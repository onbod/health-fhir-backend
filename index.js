require('dotenv').config(); // Load env vars

const express = require('express');
const bodyParser = require('body-parser');
const { Pool } = require('pg');
const { v4: uuidv4 } = require('uuid');
const Fhir = require('fhir').Fhir;
const fhir = new Fhir();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const cors = require('cors');

const SECRET_KEY = process.env.SECRET_KEY || 'your_secret_key'; // Keep secret in Railway var
const otpStore = new Map(); // In-memory OTP store for demo

const app = express();
app.use(bodyParser.json());

// ✅ Allow frontend to connect
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3001',
  credentials: true
}));

// ✅ Log all incoming requests
app.use((req, res, next) => {
  console.log('INCOMING REQUEST:', req.method, req.url);
  next();
});

// ✅ PostgreSQL connection (works locally + Railway)
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false } // Needed for Railway SSL
});

// ✅ Quick Health Check
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT NOW()');
    res.json({ status: 'ok', db: 'connected' });
  } catch (err) {
    console.error('DB ERROR:', err);
    res.status(500).json({ status: 'error', db: 'disconnected' });
  }
});

/**
 * ✅ Your Authentication & User Routes
 */

// OTP request endpoint
app.post('/login/request-otp', async (req, res) => {
  const { phone, client_number, given, family, nin_number } = req.body;
  let query, value;

  if (phone) {
    query = 'SELECT * FROM patient WHERE phone = $1';
    value = [phone];
  } else if (given && family && client_number) {
    query = `
      SELECT * FROM patient
      WHERE EXISTS (
        SELECT 1 FROM jsonb_array_elements(name) AS n
        WHERE n->'given' ? $1 AND n->>'family' = $2
      )
      AND client_number = $3
    `;
    value = [given, family, client_number];
  } else if (nin_number) {
    query = 'SELECT * FROM patient WHERE nin_number = $1';
    value = [nin_number];
  } else {
    return res.status(400).json({ error: 'Missing identifier' });
  }

  const result = await pool.query(query, value);
  if (result.rows.length === 0) {
    return res.status(404).json(operationOutcome('error', 'not-found', 'User not found'));
  }

  const otp = '123456'; // TEMP for testing
  let otpKey = phone || (given && family && client_number ? `${given}:${family}:${client_number}` : nin_number);
  otpStore.set(otpKey, { otp, expires: Date.now() + 5 * 60 * 1000 });

  console.log(`OTP for ${otpKey}: ${otp}`); // Replace with SMS in production
  res.json({ message: 'OTP sent', otp }); // <-- REMOVE 'otp' IN PRODUCTION
});

// OTP verify endpoint
app.post('/login/verify-otp', async (req, res) => {
  const { phone, client_number, given, family, nin_number, otp } = req.body;
  let key, query, value;

  if (phone) {
    key = phone;
    query = 'SELECT * FROM patient WHERE phone = $1';
    value = [phone];
  } else if (given && family && client_number) {
    key = `${given}:${family}:${client_number}`;
    query = `
      SELECT * FROM patient
      WHERE EXISTS (
        SELECT 1 FROM jsonb_array_elements(name) AS n
        WHERE n->'given' ? $1 AND n->>'family' = $2
      )
      AND client_number = $3
    `;
    value = [given, family, client_number];
  } else if (nin_number) {
    key = nin_number;
    query = 'SELECT * FROM patient WHERE nin_number = $1';
    value = [nin_number];
  } else {
    return res.status(400).json({ error: 'Missing identifier' });
  }

  const otpEntry = otpStore.get(key);
  if (!otpEntry || otpEntry.otp !== otp || otpEntry.expires < Date.now()) {
    return res.status(401).json({ error: 'Invalid or expired OTP' });
  }

  const result = await pool.query(query, value);
  if (result.rows.length === 0) return res.status(404).json({ error: 'User not found' });

  otpStore.delete(key);

  const user = result.rows[0];
  const token = jwt.sign(
    { id: user.id, client_number: user.client_number, name: user.name, phone: user.phone, nin_number: user.nin_number, role: 'patient' },
    SECRET_KEY,
    { expiresIn: '1h' }
  );

  res.json({ token });
});

// Direct login endpoint
app.post('/login/direct', async (req, res) => {
  const { given, family, client_number, nin_number } = req.body;
  let query, value;

  if (given && family && client_number) {
    query = `
      SELECT * FROM patient
      WHERE EXISTS (
        SELECT 1 FROM jsonb_array_elements(name) AS n
        WHERE n->'given' ? $1 AND n->>'family' = $2
      )
      AND client_number = $3
    `;
    value = [given, family, client_number];
    let result = await pool.query(query, value);

    if (result.rows.length === 0 && nin_number && nin_number !== client_number) {
      query = `
        SELECT * FROM patient
        WHERE EXISTS (
          SELECT 1 FROM jsonb_array_elements(name) AS n
          WHERE n->'given' ? $1 AND n->>'family' = $2
        )
        AND nin_number = $3
      `;
      value = [given, family, nin_number];
      result = await pool.query(query, value);
    }

    if (result.rows.length === 0) return res.status(404).json({ error: 'User not found' });

    const user = result.rows[0];
    const token = jwt.sign(
      { id: user.id, client_number: user.client_number, name: user.name, phone: user.phone, nin_number: user.nin_number, role: 'patient' },
      SECRET_KEY,
      { expiresIn: '1h' }
    );

    return res.json({ token });
  } else if (nin_number) {
    query = 'SELECT * FROM patient WHERE nin_number = $1';
    value = [nin_number];
    const result = await pool.query(query, value);
    if (result.rows.length === 0) return res.status(404).json({ error: 'User not found' });

    const user = result.rows[0];
    const token = jwt.sign(
      { id: user.id, client_number: user.client_number, name: user.name, phone: user.phone, nin_number: user.nin_number, role: 'patient' },
      SECRET_KEY,
      { expiresIn: '1h' }
    );

    return res.json({ token });
  } else {
    return res.status(400).json({ error: 'Missing identifier' });
  }
});

// Admin login
app.post('/admin/login', async (req, res) => {
  const { email, password } = req.body;
  const result = await pool.query('SELECT * FROM admin WHERE username = $1 OR email = $1', [email]);
  if (result.rows.length === 0) return res.status(401).json({ error: 'Invalid credentials' });

  const admin = result.rows[0];
  const match = await bcrypt.compare(password, admin.password_hash);
  if (!match) return res.status(401).json({ error: 'Invalid credentials' });

  const token = jwt.sign(
    { id: admin.id, username: admin.username, email: admin.email, name: admin.name, role: admin.role || 'admin' },
    SECRET_KEY,
    { expiresIn: '2h' }
  );

  res.json({ token, name: admin.name, email: admin.email });
});

// ✅ JWT auth middleware
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.sendStatus(401);

  jwt.verify(token, SECRET_KEY, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    if (!user.role || (user.role !== 'patient' && user.role !== 'admin')) {
      return res.status(403).json({ error: 'Insufficient role' });
    }
    next();
  });
}

// ✅ Decision Support Alerts
function generateDecisionSupportAlerts(pregnancy, ancVisits) {
  const alerts = [];
  ancVisits.forEach(v => {
    if (v.systolic_bp > 130 || v.diastolic_bp > 90) {
      alerts.push({
        code: "DAK.ANC.DANGER.HYPERTENSION",
        message: `High BP at visit ${v.visit_number} (${v.systolic_bp}/${v.diastolic_bp}) – pre-eclampsia risk`
      });
    }
    if (v.danger_signs && v.danger_signs.includes('vaginal_bleeding')) {
      alerts.push({
        code: "DAK.ANC.DANGER.BLEEDING",
        message: `Vaginal bleeding reported – urgent referral needed`
      });
    }
  });
  return alerts;
}

// ✅ Basic Test Route
app.get('/test-patients', async (req, res) => {
  const result = await pool.query('SELECT id FROM patient');
  res.json(result.rows);
});

/**
 * ✅ All your other routes (FHIR, reports, chat, etc.) remain the same...
 * (I didn’t remove any of your functionality)
 */

function operationOutcome(severity, code, diagnostics) {
  return {
    resourceType: "OperationOutcome",
    issue: [
      {
        severity,
        code,
        diagnostics
      }
    ]
  };
}

function generateDecisionSupportAlerts(pregnancy, ancVisits) {
  const alerts = [];

  ancVisits.forEach(v => {
    if (v.systolic_bp && v.diastolic_bp && (v.systolic_bp > 130 || v.diastolic_bp > 90)) {
      alerts.push({
        code: "DAK.ANC.DANGER.HYPERTENSION",
        message: `High BP detected at visit ${v.visit_number} (${v.systolic_bp}/${v.diastolic_bp}) – possible pre-eclampsia risk`
      });
    }

    if (v.danger_signs && v.danger_signs.includes('vaginal_bleeding')) {
      alerts.push({
        code: "DAK.ANC.DANGER.BLEEDING",
        message: `Vaginal bleeding reported – urgent referral needed`
      });
    }
  });

  return alerts;
}

// 1. Your custom endpoint
app.post('/report', async (req, res) => {
  const {
    client_number,
    client_name,
    phone_number,
    report_type,
    facility_name,
    description,
    is_anonymous,
    file_urls,
    who_guideline,
    dak_guideline,
    fhir_resource
  } = req.body;

  try {
    const result = await pool.query(
      `INSERT INTO report
        (client_number, client_name, phone_number, report_type, facility_name, description, is_anonymous, file_urls, who_guideline, dak_guideline, fhir_resource)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
       RETURNING *`,
      [
        client_number,
        client_name,
        phone_number,
        report_type,
        facility_name,
        description,
        is_anonymous,
        file_urls,
        who_guideline,
        dak_guideline,
        fhir_resource
      ]
    );
    res.status(201).json(result.rows[0]);
  } catch (e) {
    console.error('Error inserting report:', e);
    res.status(500).json({ error: 'Failed to submit report' });
  }
});

app.get('/indicators/anc', async (req, res) => {
  const result = await pool.query(`
    SELECT 
      COUNT(*) FILTER (WHERE visit_number = 1) AS first_visit,
      COUNT(*) FILTER (WHERE visit_number >= 4) AS four_plus_visits,
      COUNT(*) FILTER (WHERE danger_signs IS NOT NULL AND danger_signs != '{}') AS danger_sign_cases
    FROM anc_visit
  `);

  const metrics = {
    resourceType: "MeasureReport",
    type: "summary",
    period: {
      start: "2025-01-01",
      end: new Date().toISOString()
    },
    group: [
      { measureScore: { value: Number(result.rows[0].first_visit) }, description: "Women with first ANC visit" },
      { measureScore: { value: Number(result.rows[0].four_plus_visits) }, description: "Women with ≥4 ANC visits" },
      { measureScore: { value: Number(result.rows[0].danger_sign_cases) }, description: "ANC danger sign cases" }
    ]
  };
  res.json(metrics);
});

// Get user session/profile endpoint (MUST come before catch-all routes)
app.get('/user/session', async (req, res) => {
  console.log('DEBUG: /user/session - Starting endpoint');
  
  // Extract user ID from JWT token in Authorization header
  const authHeader = req.headers['authorization'];
  console.log('DEBUG: /user/session - authHeader:', authHeader);
  
  const token = authHeader && authHeader.split(' ')[1];
  console.log('DEBUG: /user/session - token:', token ? 'present' : 'missing');
  
  if (!token) {
    console.log('DEBUG: /user/session - No token provided');
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    const decoded = jwt.verify(token, SECRET_KEY);
    const userId = decoded.id;
    console.log('DEBUG: /user/session userId:', userId);
    console.log('DEBUG: /user/session decoded token:', decoded);

    // Get patient info
    const patientResult = await pool.query('SELECT * FROM patient WHERE id = $1', [userId]);
    console.log('DEBUG: /user/session patientResult:', patientResult.rows);
    console.log('DEBUG: /user/session patientResult.rowCount:', patientResult.rowCount);

    if (patientResult.rows.length === 0) return res.status(404).json({ error: 'User not found' });
    const patient = patientResult.rows[0];

    // Get current pregnancy (latest by edd)
    const pregnancyResult = await pool.query(
      'SELECT * FROM pregnancy WHERE patient_id = $1 ORDER BY edd DESC LIMIT 1', [userId]
    );
    const pregnancy = pregnancyResult.rows[0] || null;
    console.log('DEBUG: /user/session pregnancy:', pregnancy);

    // Get all ANC visits for this patient (for the current pregnancy)
    let ancVisits = [];
    if (pregnancy) {
      const ancResult = await pool.query(
        'SELECT * FROM anc_visit WHERE patient_id = $1 ORDER BY visit_number ASC', [userId]
      );
      ancVisits = ancResult.rows;
    }
    console.log('DEBUG: /user/session ancVisits:', ancVisits);

    // Get delivery info for this pregnancy
    let delivery = null;
    if (pregnancy) {
      const deliveryResult = await pool.query(
        'SELECT * FROM delivery WHERE pregnancy_id = $1', [pregnancy.id]
      );
      delivery = deliveryResult.rows[0] || null;
    }
    console.log('DEBUG: /user/session delivery:', delivery);

    // Get neonate info for this delivery
    let neonates = [];
    if (delivery) {
      const neonateResult = await pool.query(
        'SELECT * FROM neonate WHERE delivery_id = $1', [delivery.id]
      );
      neonates = neonateResult.rows;
    }
    console.log('DEBUG: /user/session neonates:', neonates);

    // Get postnatal visits for this delivery
    let postnatalVisits = [];
    if (delivery) {
      const postnatalResult = await pool.query(
        'SELECT * FROM postnatal_visit WHERE delivery_id = $1', [delivery.id]
      );
      postnatalVisits = postnatalResult.rows;
    }
    console.log('DEBUG: /user/session postnatalVisits:', postnatalVisits);

    const decisionSupportAlerts = pregnancy ? generateDecisionSupportAlerts(pregnancy, ancVisits) : [];

    res.json({
      patient,
      pregnancy,
      ancVisits,
      delivery,
      neonates,
      postnatalVisits,
      decisionSupportAlerts
    });
  } catch (err) {
    console.error('JWT verification error:', err);
    return res.status(401).json({ error: 'Invalid token' });
  }
});

// 2. FHIR catch-all (must come after!)
app.use('/:resourceType', (req, res, next) => {
  next(); // No authentication required for any resourceType
});
app.get('/fhir/:resourceType', async (req, res) => {
  const { resourceType } = req.params;
  const queryParams = req.query;

  let sql = `SELECT data FROM fhir_resources WHERE resource_type = $1`;
  let values = [resourceType];

  if (resourceType === 'Patient' && queryParams.name) {
    sql += ` AND EXISTS (
      SELECT 1 FROM jsonb_array_elements(data->'name') AS n
      WHERE EXISTS (
        SELECT 1 FROM jsonb_array_elements_text(n->'given') AS g
        WHERE g = $2
      )
    )`;
    values.push(queryParams.name);
  } else if (queryParams.name) {
    sql += ` AND data->>'name' ILIKE $2`;
    values.push(`%${queryParams.name}%`);
  }
  if (queryParams.patient) {
    sql += ` AND data->>'subject' = $${values.length + 1}`;
    values.push(queryParams.patient);
  }

  const result = await pool.query(sql, values);
  res.json({
    resourceType: "Bundle",
    type: "searchset",
    total: result.rows.length,
    entry: result.rows.map(row => ({ resource: row.data }))
  });
});
app.get('/metadata', (req, res) => {
  const capabilityStatement = {
    resourceType: "CapabilityStatement",
    status: "active",
    date: new Date().toISOString(),
    publisher: "Healthy Mother App",
    kind: "instance",
    software: {
      name: "Healthy Mother FHIR API",
      version: "1.0.0"
    },
    fhirVersion: "4.0.1",
    format: ["json"],
    rest: [{
      mode: "server",
      resource: [
        { type: "Patient", interaction: [{ code: "read" }, { code: "search-type" }, { code: "update" }, { code: "create" }, { code: "delete" }] },
        { type: "Encounter", interaction: [{ code: "read" }, { code: "create" }, { code: "search-type" }] },
        { type: "Observation", interaction: [{ code: "read" }, { code: "search-type" }] },
        { type: "Procedure", interaction: [{ code: "read" }, { code: "create" }] }
      ]
    }]
  };
  res.json(capabilityStatement);
});
app.post('/:resourceType', async (req, res) => {
  const resourceType = req.params.resourceType;
  const resource = req.body;
  const resourceId = resource.id || uuidv4();
  resource.id = resourceId;

  // Validate resource
  const result = fhir.validate(resource);
  if (!result.valid) {
    return res.status(400).json({ error: 'Invalid FHIR resource', issues: result });
  }

  await pool.query(
    'INSERT INTO fhir_resources (resource_type, resource_id, data) VALUES ($1, $2, $3)',
    [resourceType, resourceId, resource]
  );
  res.status(201).json(resource);
});

// Read a FHIR resource
app.get('/:resourceType/:id', async (req, res) => {
  const { resourceType, id } = req.params;
  const result = await pool.query(
    'SELECT data FROM fhir_resources WHERE resource_type = $1 AND resource_id = $2',
    [resourceType, id]
  );
  if (result.rows.length === 0) {
    return res.status(404).json({ error: 'Resource not found' });
  }
  res.json(result.rows[0].data);
});

// Search FHIR resources
app.get('/:resourceType', async (req, res) => {
  const { resourceType } = req.params;
  const result = await pool.query(
    'SELECT data FROM fhir_resources WHERE resource_type = $1',
    [resourceType]
  );
  res.json(result.rows.map(row => row.data));
});

// Update a FHIR resource
app.put('/:resourceType/:id', async (req, res) => {
  const { resourceType, id } = req.params;
  const resource = req.body;
  resource.id = id;
  await pool.query(
    'UPDATE fhir_resources SET data = $1 WHERE resource_type = $2 AND resource_id = $3',
    [resource, resourceType, id]
  );
  res.json(resource);
});

// Delete a FHIR resource
app.delete('/:resourceType/:id', async (req, res) => {
  const { resourceType, id } = req.params;
  await pool.query(
    'DELETE FROM fhir_resources WHERE resource_type = $1 AND resource_id = $2',
    [resourceType, id]
  );
  res.status(204).send();
});



// Get all messages for a chat
app.get('/chat/:chatId/messages', async (req, res) => {
  const { chatId } = req.params;
  const result = await pool.query(
    'SELECT * FROM chat_message WHERE chat_id = $1 ORDER BY timestamp ASC',
    [chatId]
  );
  res.json(result.rows);
});

// Send a new message
app.post('/chat/:chatId/messages', async (req, res) => {
  const { chatId } = req.params;
  const {
    sender_id,
    receiver_id,
    message,
    who_guideline,
    dak_guideline,
    fhir_resource
  } = req.body;
  const result = await pool.query(
    `INSERT INTO chat_message
      (chat_id, sender_id, receiver_id, message, who_guideline, dak_guideline, fhir_resource)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING *`,
    [chatId, sender_id, receiver_id, message, who_guideline, dak_guideline, fhir_resource]
  );
  res.status(201).json(result.rows[0]);
});

app.listen(3000, () => {
  console.log('FHIR server running on port 3000');
});

app.get('/test-patients', async (req, res) => {
  const result = await pool.query('SELECT id, client_number, name FROM patient');
  console.log('DEBUG: all patient ids:', result.rows);
  res.json(result.rows);
});

app.get('/admin/patient/:id/full', async (req, res) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Admin access required' });
  }
  const patientId = req.params.id;

  // Get patient info
  const patientResult = await pool.query('SELECT * FROM patient WHERE id = $1', [patientId]);
  if (patientResult.rows.length === 0) return res.status(404).json({ error: 'User not found' });
  const patient = patientResult.rows[0];

  // Get current pregnancy (latest by edd)
  const pregnancyResult = await pool.query(
    'SELECT * FROM pregnancy WHERE patient_id = $1 ORDER BY edd DESC LIMIT 1', [patientId]
  );
  const pregnancy = pregnancyResult.rows[0] || null;

  // Get all ANC visits for this patient (for the current pregnancy)
  let ancVisits = [];
  if (pregnancy) {
    const ancResult = await pool.query(
      'SELECT * FROM anc_visit WHERE patient_id = $1 ORDER BY visit_number ASC', [patientId]
    );
    ancVisits = ancResult.rows;
  }

  // Get delivery info for this pregnancy
  let delivery = null;
  if (pregnancy) {
    const deliveryResult = await pool.query(
      'SELECT * FROM delivery WHERE pregnancy_id = $1', [pregnancy.id]
    );
    delivery = deliveryResult.rows[0] || null;
  }

  // Get neonate info for this delivery
  let neonates = [];
  if (delivery) {
    const neonateResult = await pool.query(
      'SELECT * FROM neonate WHERE delivery_id = $1', [delivery.id]
    );
    neonates = neonateResult.rows;
  }

  // Get postnatal visits for this delivery
  let postnatalVisits = [];
  if (delivery) {
    const postnatalResult = await pool.query(
      'SELECT * FROM postnatal_visit WHERE delivery_id = $1', [delivery.id]
    );
    postnatalVisits = postnatalResult.rows;
  }

  // Decision support alerts (reuse your function)
  const decisionSupportAlerts = pregnancy ? generateDecisionSupportAlerts(pregnancy, ancVisits) : [];

  res.json({
    patient,
    pregnancy,
    ancVisits,
    delivery,
    neonates,
    postnatalVisits,
    decisionSupportAlerts
  });
});
// ✅ Start Server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`FHIR server running on port ${PORT}`));
