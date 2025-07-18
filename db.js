require('dotenv').config();
const { Pool } = require('pg');

// Connect using Railway DATABASE_URL
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false  // Needed for Railway SSL
  }
});

module.exports = pool;
