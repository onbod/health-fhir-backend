--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5
-- Dumped by pg_dump version 17.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: counseling_topic; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.counseling_topic AS ENUM (
    'nutrition',
    'birth_preparedness',
    'breastfeeding',
    'family_planning',
    'hygiene',
    'danger_signs',
    'postnatal_care',
    'malaria_prevention',
    'hiv_prevention',
    'iptp',
    'iron_supplementation'
);


ALTER TYPE public.counseling_topic OWNER TO postgres;

--
-- Name: danger_sign_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.danger_sign_type AS ENUM (
    'severe_headache',
    'visual_disturbances',
    'convulsions',
    'severe_abdominal_pain',
    'vaginal_bleeding',
    'severe_vomiting',
    'fever',
    'difficulty_breathing',
    'reduced_fetal_movements',
    'ruptured_membranes',
    'other'
);


ALTER TYPE public.danger_sign_type OWNER TO postgres;

--
-- Name: gender_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.gender_type AS ENUM (
    'male',
    'female',
    'other',
    'unknown'
);


ALTER TYPE public.gender_type OWNER TO postgres;

--
-- Name: triage_level; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.triage_level AS ENUM (
    'emergency',
    'priority',
    'queue',
    'no_urgent_care'
);


ALTER TYPE public.triage_level OWNER TO postgres;

--
-- Name: yes_no_na_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.yes_no_na_type AS ENUM (
    'yes',
    'no',
    'na'
);


ALTER TYPE public.yes_no_na_type OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: admin; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin (
    id integer NOT NULL,
    username character varying(50) NOT NULL,
    password_hash character varying(255) NOT NULL,
    email character varying(100),
    role character varying(20) DEFAULT 'admin'::character varying,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    name character varying(100)
);


ALTER TABLE public.admin OWNER TO postgres;

--
-- Name: admin_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admin_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.admin_id_seq OWNER TO postgres;

--
-- Name: admin_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admin_id_seq OWNED BY public.admin.id;


--
-- Name: anc_visit; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.anc_visit (
    id integer NOT NULL,
    fhir_id uuid DEFAULT public.uuid_generate_v4(),
    patient_id integer NOT NULL,
    facility_id integer NOT NULL,
    visit_number integer NOT NULL,
    visit_date date NOT NULL,
    is_outreach boolean DEFAULT false,
    triage_level public.triage_level,
    danger_signs public.danger_sign_type[],
    urgent_referral_needed boolean,
    referral_reason text,
    systolic_bp integer,
    diastolic_bp integer,
    has_oedema public.yes_no_na_type,
    has_pitting_oedema public.yes_no_na_type,
    urine_albumin public.yes_no_na_type,
    fetal_heart_rate integer,
    fetal_movements public.yes_no_na_type,
    fundal_height integer,
    presentation character varying(50),
    hemoglobin numeric(4,1),
    malaria_test_result character varying(20),
    hiv_status character varying(20),
    syphilis_status character varying(20),
    hepatitis_b_status character varying(20),
    urine_test_results jsonb,
    counseling_topics public.counseling_topic[],
    counseling_notes text,
    iron_folic_acid_given boolean,
    mms_supplement_given boolean,
    iptp_doses integer,
    tetanus_doses integer,
    albendazole_given boolean,
    llin_given boolean,
    next_visit_date date,
    next_visit_weeks integer,
    follow_up_instructions text,
    smart_metrics jsonb DEFAULT '{"relevant": true, "specific": true, "timeBound": true, "achievable": true, "measurable": true}'::jsonb,
    meta jsonb DEFAULT '{"class": {"code": "AMB", "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "display": "ambulatory"}, "profile": ["http://hl7.org/fhir/StructureDefinition/Encounter"], "extension": [{"url": "http://who.int/dak/anc", "valueCode": "anc-visit"}], "resourceType": "Encounter"}'::jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    gestational_age_weeks integer,
    CONSTRAINT anc_visit_iptp_doses_check CHECK (((iptp_doses >= 0) AND (iptp_doses <= 3))),
    CONSTRAINT anc_visit_tetanus_doses_check CHECK (((tetanus_doses >= 0) AND (tetanus_doses <= 5))),
    CONSTRAINT anc_visit_visit_number_check CHECK (((visit_number >= 1) AND (visit_number <= 8)))
);


ALTER TABLE public.anc_visit OWNER TO postgres;

--
-- Name: anc_visit_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.anc_visit_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.anc_visit_id_seq OWNER TO postgres;

--
-- Name: anc_visit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.anc_visit_id_seq OWNED BY public.anc_visit.id;


--
-- Name: chat_message; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_message (
    id integer NOT NULL,
    chat_id character varying(100),
    sender_id character varying(100),
    receiver_id character varying(100),
    message text,
    "timestamp" timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    status character varying(20) DEFAULT 'sent'::character varying,
    who_guideline text,
    dak_guideline text,
    fhir_resource jsonb
);


ALTER TABLE public.chat_message OWNER TO postgres;

--
-- Name: chat_message_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.chat_message_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.chat_message_id_seq OWNER TO postgres;

--
-- Name: chat_message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.chat_message_id_seq OWNED BY public.chat_message.id;


--
-- Name: decision_support_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.decision_support_log (
    id integer NOT NULL,
    fhir_id uuid DEFAULT public.uuid_generate_v4(),
    anc_visit_id integer,
    decision_point character varying(50) NOT NULL,
    decision_description text NOT NULL,
    input_conditions jsonb NOT NULL,
    decision_output jsonb NOT NULL,
    action_taken text,
    alert_shown boolean,
    "timestamp" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    meta jsonb DEFAULT '{"profile": ["http://hl7.org/fhir/StructureDefinition/Provenance"], "resourceType": "Provenance"}'::jsonb
);


ALTER TABLE public.decision_support_log OWNER TO postgres;

--
-- Name: decision_support_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.decision_support_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.decision_support_log_id_seq OWNER TO postgres;

--
-- Name: decision_support_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.decision_support_log_id_seq OWNED BY public.decision_support_log.id;


--
-- Name: delivery; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.delivery (
    id integer NOT NULL,
    fhir_id uuid DEFAULT public.uuid_generate_v4(),
    pregnancy_id integer NOT NULL,
    facility_id integer,
    delivery_date date NOT NULL,
    delivery_time time without time zone,
    delivery_mode character varying(50),
    complications text[],
    blood_loss_ml integer,
    placenta_complete boolean,
    mother_condition character varying(50),
    partograph_used boolean,
    attendant_type character varying(50),
    meta jsonb DEFAULT '{"code": {"coding": [{"code": "5880005", "system": "http://snomed.info/sct", "display": "Delivery"}]}, "profile": ["http://hl7.org/fhir/StructureDefinition/Procedure"], "resourceType": "Procedure"}'::jsonb
);


ALTER TABLE public.delivery OWNER TO postgres;

--
-- Name: delivery_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.delivery_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.delivery_id_seq OWNER TO postgres;

--
-- Name: delivery_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.delivery_id_seq OWNED BY public.delivery.id;


--
-- Name: facility; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.facility (
    id integer NOT NULL,
    fhir_id uuid DEFAULT public.uuid_generate_v4(),
    name character varying(100) NOT NULL,
    type character varying(50) NOT NULL,
    chiefdom_zone character varying(100) NOT NULL,
    is_anc_site boolean DEFAULT true NOT NULL,
    is_emonc_site boolean DEFAULT false NOT NULL,
    meta jsonb DEFAULT '{"profile": ["http://hl7.org/fhir/StructureDefinition/Location"], "resourceType": "Location"}'::jsonb
);


ALTER TABLE public.facility OWNER TO postgres;

--
-- Name: facility_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.facility_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.facility_id_seq OWNER TO postgres;

--
-- Name: facility_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.facility_id_seq OWNED BY public.facility.id;


--
-- Name: fhir_resources; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fhir_resources (
    id integer NOT NULL,
    resource_type character varying(64) NOT NULL,
    resource_id character varying(64) NOT NULL,
    data jsonb NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.fhir_resources OWNER TO postgres;

--
-- Name: fhir_resources_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fhir_resources_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fhir_resources_id_seq OWNER TO postgres;

--
-- Name: fhir_resources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fhir_resources_id_seq OWNED BY public.fhir_resources.id;


--
-- Name: health_tips; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.health_tips (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    content text NOT NULL,
    category character varying(50) NOT NULL,
    target_stage character varying(50) NOT NULL,
    target_weeks integer[],
    target_visits integer[],
    weeks character varying(50),
    trimester character varying(50),
    visit character varying(50),
    category_type character varying(100),
    nutrition_type character varying(100),
    is_active boolean DEFAULT true,
    sent_count integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT health_tips_category_check CHECK (((category)::text = ANY ((ARRAY['health'::character varying, 'nutrition'::character varying, 'video'::character varying])::text[]))),
    CONSTRAINT health_tips_target_stage_check CHECK (((target_stage)::text = ANY ((ARRAY['first-trimester'::character varying, 'second-trimester'::character varying, 'third-trimester'::character varying, 'delivery'::character varying])::text[])))
);


ALTER TABLE public.health_tips OWNER TO postgres;

--
-- Name: health_tips_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.health_tips_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.health_tips_id_seq OWNER TO postgres;

--
-- Name: health_tips_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.health_tips_id_seq OWNED BY public.health_tips.id;


--
-- Name: indicator_metrics; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.indicator_metrics (
    id integer NOT NULL,
    fhir_id uuid DEFAULT public.uuid_generate_v4(),
    indicator_code character varying(50) NOT NULL,
    indicator_name text NOT NULL,
    numerator_definition text NOT NULL,
    denominator_definition text NOT NULL,
    measurement_period character varying(50),
    reporting_level character varying(50),
    data_sources text[],
    meta jsonb DEFAULT '{"profile": ["http://hl7.org/fhir/StructureDefinition/Measure"], "resourceType": "Measure"}'::jsonb
);


ALTER TABLE public.indicator_metrics OWNER TO postgres;

--
-- Name: indicator_metrics_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.indicator_metrics_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.indicator_metrics_id_seq OWNER TO postgres;

--
-- Name: indicator_metrics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.indicator_metrics_id_seq OWNED BY public.indicator_metrics.id;


--
-- Name: neonate; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.neonate (
    id integer NOT NULL,
    fhir_id uuid DEFAULT public.uuid_generate_v4(),
    delivery_id integer NOT NULL,
    birth_order integer,
    sex public.gender_type,
    birth_weight_kg numeric(4,2),
    apgar_1min integer,
    apgar_5min integer,
    resuscitation_needed boolean,
    breastfeeding_initiated boolean,
    vitamin_k_given boolean,
    birth_defects text[],
    meta jsonb DEFAULT '{"code": {"coding": [{"code": "57070-2", "system": "http://loinc.org", "display": "Birth status"}]}, "profile": ["http://hl7.org/fhir/StructureDefinition/Observation"], "resourceType": "Observation"}'::jsonb,
    CONSTRAINT neonate_apgar_1min_check CHECK (((apgar_1min >= 0) AND (apgar_1min <= 10))),
    CONSTRAINT neonate_apgar_5min_check CHECK (((apgar_5min >= 0) AND (apgar_5min <= 10))),
    CONSTRAINT neonate_birth_order_check CHECK (((birth_order >= 1) AND (birth_order <= 4)))
);


ALTER TABLE public.neonate OWNER TO postgres;

--
-- Name: neonate_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.neonate_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.neonate_id_seq OWNER TO postgres;

--
-- Name: neonate_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.neonate_id_seq OWNED BY public.neonate.id;


--
-- Name: patient; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.patient (
    id integer NOT NULL,
    fhir_id uuid DEFAULT public.uuid_generate_v4(),
    client_number character varying(50),
    nin_number character varying(50),
    name jsonb NOT NULL,
    birth_date date,
    age integer,
    gender public.gender_type,
    address jsonb,
    phone character varying(20),
    emergency_contact jsonb,
    responsible_person character varying(100),
    blood_group character varying(10),
    is_sickler public.yes_no_na_type DEFAULT 'na'::public.yes_no_na_type,
    is_pregnant public.yes_no_na_type DEFAULT 'no'::public.yes_no_na_type,
    registration_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    meta jsonb DEFAULT '{"source": "DAK ANC System", "profile": ["http://hl7.org/fhir/StructureDefinition/Patient"], "resourceType": "Patient"}'::jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT patient_age_check CHECK (((age >= 10) AND (age <= 60)))
);


ALTER TABLE public.patient OWNER TO postgres;

--
-- Name: patient_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.patient_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.patient_id_seq OWNER TO postgres;

--
-- Name: patient_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.patient_id_seq OWNED BY public.patient.id;


--
-- Name: patient_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.patient_view AS
 SELECT (data ->> 'id'::text) AS id,
    (data ->> 'resourceType'::text) AS resource_type,
    (data -> 'name'::text) AS name,
    (data ->> 'gender'::text) AS gender,
    (data ->> 'birthDate'::text) AS birth_date,
    data
   FROM public.fhir_resources
  WHERE ((resource_type)::text = 'Patient'::text);


ALTER VIEW public.patient_view OWNER TO postgres;

--
-- Name: postnatal_visit; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.postnatal_visit (
    id integer NOT NULL,
    fhir_id uuid DEFAULT public.uuid_generate_v4(),
    patient_id integer NOT NULL,
    delivery_id integer,
    visit_date date NOT NULL,
    days_postpartum integer NOT NULL,
    mother_condition character varying(100),
    bp character varying(10),
    temperature numeric(4,1),
    uterine_involution character varying(50),
    lochia_description character varying(100),
    breastfeeding_status character varying(50),
    family_planning_discussed boolean,
    pp_complications text[],
    neonate_checks jsonb,
    meta jsonb DEFAULT '{"class": {"code": "AMB", "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "display": "ambulatory"}, "profile": ["http://hl7.org/fhir/StructureDefinition/Encounter"], "resourceType": "Encounter"}'::jsonb
);


ALTER TABLE public.postnatal_visit OWNER TO postgres;

--
-- Name: postnatal_visit_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.postnatal_visit_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.postnatal_visit_id_seq OWNER TO postgres;

--
-- Name: postnatal_visit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.postnatal_visit_id_seq OWNED BY public.postnatal_visit.id;


--
-- Name: pregnancy; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pregnancy (
    id integer NOT NULL,
    fhir_id uuid DEFAULT public.uuid_generate_v4(),
    patient_id integer NOT NULL,
    lmp date NOT NULL,
    edd date NOT NULL,
    gravida integer NOT NULL,
    parity integer NOT NULL,
    living_children integer,
    previous_cs integer DEFAULT 0,
    height_cm numeric(5,2),
    booking_weight_kg numeric(5,2),
    risk_factors jsonb,
    meta jsonb DEFAULT '{"code": {"coding": [{"code": "11884-4", "system": "http://loinc.org", "display": "Pregnancy status"}]}, "profile": ["http://hl7.org/fhir/StructureDefinition/Observation"], "resourceType": "Observation"}'::jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.pregnancy OWNER TO postgres;

--
-- Name: pregnancy_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pregnancy_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pregnancy_id_seq OWNER TO postgres;

--
-- Name: pregnancy_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pregnancy_id_seq OWNED BY public.pregnancy.id;


--
-- Name: report; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.report (
    id integer NOT NULL,
    client_number character varying(50),
    client_name character varying(255),
    phone_number character varying(50),
    report_type character varying(100),
    facility_name character varying(255),
    description text,
    is_anonymous boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    file_urls text[],
    who_guideline text,
    dak_guideline text,
    fhir_resource jsonb,
    status character varying(50) DEFAULT 'pending'::character varying
);


ALTER TABLE public.report OWNER TO postgres;

--
-- Name: report_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.report_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.report_id_seq OWNER TO postgres;

--
-- Name: report_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.report_id_seq OWNED BY public.report.id;


--
-- Name: system_functionality; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.system_functionality (
    id integer NOT NULL,
    fhir_id uuid DEFAULT public.uuid_generate_v4(),
    requirement_id character varying(50) NOT NULL,
    requirement_description text NOT NULL,
    implementation_status character varying(20) NOT NULL,
    last_test_date date,
    test_result character varying(20),
    notes text,
    meta jsonb DEFAULT '{"profile": ["http://hl7.org/fhir/StructureDefinition/Basic"], "resourceType": "Basic"}'::jsonb
);


ALTER TABLE public.system_functionality OWNER TO postgres;

--
-- Name: system_functionality_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.system_functionality_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_functionality_id_seq OWNER TO postgres;

--
-- Name: system_functionality_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.system_functionality_id_seq OWNED BY public.system_functionality.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    role character varying(50) DEFAULT 'clinician'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: admin id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin ALTER COLUMN id SET DEFAULT nextval('public.admin_id_seq'::regclass);


--
-- Name: anc_visit id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.anc_visit ALTER COLUMN id SET DEFAULT nextval('public.anc_visit_id_seq'::regclass);


--
-- Name: chat_message id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_message ALTER COLUMN id SET DEFAULT nextval('public.chat_message_id_seq'::regclass);


--
-- Name: decision_support_log id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.decision_support_log ALTER COLUMN id SET DEFAULT nextval('public.decision_support_log_id_seq'::regclass);


--
-- Name: delivery id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery ALTER COLUMN id SET DEFAULT nextval('public.delivery_id_seq'::regclass);


--
-- Name: facility id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.facility ALTER COLUMN id SET DEFAULT nextval('public.facility_id_seq'::regclass);


--
-- Name: fhir_resources id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fhir_resources ALTER COLUMN id SET DEFAULT nextval('public.fhir_resources_id_seq'::regclass);


--
-- Name: health_tips id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.health_tips ALTER COLUMN id SET DEFAULT nextval('public.health_tips_id_seq'::regclass);


--
-- Name: indicator_metrics id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.indicator_metrics ALTER COLUMN id SET DEFAULT nextval('public.indicator_metrics_id_seq'::regclass);


--
-- Name: neonate id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.neonate ALTER COLUMN id SET DEFAULT nextval('public.neonate_id_seq'::regclass);


--
-- Name: patient id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient ALTER COLUMN id SET DEFAULT nextval('public.patient_id_seq'::regclass);


--
-- Name: postnatal_visit id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.postnatal_visit ALTER COLUMN id SET DEFAULT nextval('public.postnatal_visit_id_seq'::regclass);


--
-- Name: pregnancy id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pregnancy ALTER COLUMN id SET DEFAULT nextval('public.pregnancy_id_seq'::regclass);


--
-- Name: report id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report ALTER COLUMN id SET DEFAULT nextval('public.report_id_seq'::regclass);


--
-- Name: system_functionality id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_functionality ALTER COLUMN id SET DEFAULT nextval('public.system_functionality_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: admin; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admin (id, username, password_hash, email, role, created_at, name) FROM stdin;
1	ibrahimswaray430	$2b$10$HJy8V1Bn0TWbK/ImsP/wgecn0tarGXYo92X6YuRJinewHgY5yJ4Ea	ibrahimswaray430@gmail.com	admin	2025-07-18 15:16:04.079514+00	Ibrahim S Swaray
\.


--
-- Data for Name: anc_visit; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.anc_visit (id, fhir_id, patient_id, facility_id, visit_number, visit_date, is_outreach, triage_level, danger_signs, urgent_referral_needed, referral_reason, systolic_bp, diastolic_bp, has_oedema, has_pitting_oedema, urine_albumin, fetal_heart_rate, fetal_movements, fundal_height, presentation, hemoglobin, malaria_test_result, hiv_status, syphilis_status, hepatitis_b_status, urine_test_results, counseling_topics, counseling_notes, iron_folic_acid_given, mms_supplement_given, iptp_doses, tetanus_doses, albendazole_given, llin_given, next_visit_date, next_visit_weeks, follow_up_instructions, smart_metrics, meta, created_at, gestational_age_weeks) FROM stdin;
1	2296b351-fdb8-423a-84d6-1c20a63a610d	4	4	1	2025-04-25	f	queue	\N	\N	\N	120	80	\N	\N	\N	\N	\N	\N	\N	10.5	\N	\N	\N	\N	\N	{nutrition,danger_signs,birth_preparedness}	\N	t	\N	1	\N	\N	\N	\N	\N	\N	{"relevant": true, "specific": true, "timeBound": true, "achievable": true, "measurable": true}	{"class": {"coding": [{"code": "AMB", "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "display": "ambulatory"}]}, "resourceType": "Encounter"}	2025-07-16 15:59:55.085323+00	8
2	d03eb89e-fe1b-447c-805c-175025a29833	1	1	1	2025-04-01	f	priority	{vaginal_bleeding,severe_headache}	t	Heavy bleeding and headache	135	92	yes	no	no	140	yes	20	cephalic	11.2	negative	negative	negative	negative	{"glucose": "negative", "protein": "negative"}	{nutrition,danger_signs,birth_preparedness}	Discussed nutrition, danger signs, and birth preparedness	t	f	1	2	t	t	2024-03-01	4	Return in 4 weeks	{"relevant": true, "specific": true, "timeBound": true, "achievable": true, "measurable": true}	{"class": {"code": "AMB", "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "display": "ambulatory"}, "profile": ["http://hl7.org/fhir/StructureDefinition/Encounter"], "extension": [{"url": "http://who.int/dak/anc", "valueCode": "anc-visit"}], "resourceType": "Encounter"}	2024-02-01 10:00:00+00	\N
\.


--
-- Data for Name: chat_message; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_message (id, chat_id, sender_id, receiver_id, message, "timestamp", status, who_guideline, dak_guideline, fhir_resource) FROM stdin;
1	ANC-2024-0125	ANC-2024-0125	health_worker	Hi	2025-07-17 21:28:59.981535	sent	Respectful communication	Digital Adherence	\N
\.


--
-- Data for Name: decision_support_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.decision_support_log (id, fhir_id, anc_visit_id, decision_point, decision_description, input_conditions, decision_output, action_taken, alert_shown, "timestamp", meta) FROM stdin;
1	4693a660-5c11-48ce-b0cc-2a1bee2a40ea	1	ANC.DT.01	Danger signs assessment	{"bp": "120/80", "danger_signs": []}	{"decision": "no_danger_signs"}	Continued with routine ANC care	\N	2025-07-16 16:01:33.857119+00	{"profile": ["http://hl7.org/fhir/StructureDefinition/Provenance"], "resourceType": "Provenance"}
2	e35c0020-363f-4247-8b15-d4a03fd69284	1	ANC.DT.01	Detected high BP and vaginal bleeding	{"systolic_bp": 135, "danger_signs": ["vaginal_bleeding", "severe_headache"], "diastolic_bp": 92}	{"alert": "DAK.ANC.DANGER.HYPERTENSION"}	Urgent referral recommended	t	2024-02-01 10:30:00+00	{"profile": ["http://hl7.org/fhir/StructureDefinition/Provenance"], "resourceType": "Provenance"}
\.


--
-- Data for Name: delivery; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.delivery (id, fhir_id, pregnancy_id, facility_id, delivery_date, delivery_time, delivery_mode, complications, blood_loss_ml, placenta_complete, mother_condition, partograph_used, attendant_type, meta) FROM stdin;
1	dd4c6e14-3ba7-4b7a-b90e-0a12763d30e9	1	1	2024-10-08	14:30:00	normal	{none}	300	t	stable	t	midwife	{"code": {"coding": [{"code": "5880005", "system": "http://snomed.info/sct", "display": "Delivery"}]}, "profile": ["http://hl7.org/fhir/StructureDefinition/Procedure"], "resourceType": "Procedure"}
\.


--
-- Data for Name: facility; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.facility (id, fhir_id, name, type, chiefdom_zone, is_anc_site, is_emonc_site, meta) FROM stdin;
4	2822e07f-6172-4d71-8740-cba9c8bfa281	Rokupa Government Hospital	Hospital	Western Area Urban	t	t	{"status": "active", "extension": [{"url": "http://who.int/dak/anc", "valueCode": "anc-site"}], "identifier": [{"value": "FAC-2023-001", "system": "https://moh.sl/facilities"}, {"value": "ANC-SITE-001", "system": "https://who.int/dak"}], "physicalType": {"coding": [{"code": "bu", "system": "http://terminology.hl7.org/CodeSystem/location-physical-type", "display": "Building"}]}, "resourceType": "Location"}
1	1d76caf4-ace4-476c-9970-01a550040276	Demo Health Center	Primary	Demo Chiefdom	t	t	{"status": "active", "profile": ["http://hl7.org/fhir/StructureDefinition/Location"], "resourceType": "Location", "managingOrganization": {"display": "Demo Health Org"}}
\.


--
-- Data for Name: fhir_resources; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fhir_resources (id, resource_type, resource_id, data, created_at, updated_at) FROM stdin;
1	Patient	ANC-2024-0001	{"id": "ANC-2024-0001", "meta": {"source": "DAK ANC System", "profile": ["http://hl7.org/fhir/StructureDefinition/Patient"]}, "name": [{"use": "official", "text": "Mrs Mariama Aminata Sesay", "given": ["Mariama", "Aminata"], "family": "Sesay", "prefix": ["Mrs"], "suffix": ["Jr"]}], "gender": "female", "address": [{"city": "Demo City", "line": ["123 Demo St", "Apt 4B"], "country": "SL", "district": "Demo District", "postalCode": "12345"}], "contact": [{"name": {"text": "Fatmata Sesay"}, "address": {"text": "456 Demo Ave"}, "telecom": [{"value": "+23280000002", "system": "phone"}], "relationship": [{"coding": [{"code": "SIS", "system": "http://terminology.hl7.org/CodeSystem/v2-0131", "display": "Sister"}]}]}], "telecom": [{"value": "+23280000001", "system": "phone"}], "birthDate": "1992-05-10", "identifier": [{"value": "ANC-2024-0001", "system": "http://healthymama.org/client_number"}], "resourceType": "Patient", "maritalStatus": {"coding": [{"code": "M", "system": "http://terminology.hl7.org/CodeSystem/v3-MaritalStatus", "display": "Married"}]}, "multipleBirthBoolean": false}	2025-07-18 14:14:37.32959	2025-07-18 14:14:37.32959
2	Encounter	ANC-2024-0001-ANC1	{"id": "ANC-2024-0001-ANC1", "meta": {"profile": ["http://hl7.org/fhir/StructureDefinition/Encounter"]}, "class": {"code": "AMB", "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "display": "ambulatory"}, "period": {"end": "2024-02-01T10:30:00+00:00", "start": "2024-02-01T10:00:00+00:00"}, "status": "finished", "subject": {"reference": "Patient/ANC-2024-0001"}, "extension": [{"url": "http://who.int/dak/anc", "valueCode": "anc-visit"}], "reasonCode": [{"coding": [{"code": "4241000179101", "system": "http://snomed.info/sct", "display": "Antenatal care"}]}], "resourceType": "Encounter", "serviceProvider": {"reference": "Location/1"}}	2025-07-18 14:14:56.37174	2025-07-18 14:14:56.37174
3	Procedure	ANC-2024-0001-DEL1	{"id": "ANC-2024-0001-DEL1", "code": {"coding": [{"code": "5880005", "system": "http://snomed.info/sct", "display": "Delivery"}]}, "meta": {"profile": ["http://hl7.org/fhir/StructureDefinition/Procedure"]}, "status": "completed", "outcome": {"coding": [{"code": "700000006", "system": "http://snomed.info/sct", "display": "Normal vaginal delivery"}]}, "subject": {"reference": "Patient/ANC-2024-0001"}, "bodySite": [{"text": "uterus"}], "location": {"reference": "Location/1"}, "complication": [{"text": "none"}], "resourceType": "Procedure", "performedDateTime": "2024-10-08T14:30:00+00:00"}	2025-07-18 14:15:10.370975	2025-07-18 14:15:10.370975
4	Observation	ANC-2024-0001-PREG1	{"id": "ANC-2024-0001-PREG1", "code": {"coding": [{"code": "11884-4", "system": "http://loinc.org", "display": "Pregnancy status"}]}, "meta": {"profile": ["http://hl7.org/fhir/StructureDefinition/Observation"]}, "status": "final", "subject": {"reference": "Patient/ANC-2024-0001"}, "component": [{"code": {"coding": [{"code": "11996-6", "system": "http://loinc.org", "display": "Gravida"}]}, "valueInteger": 2}, {"code": {"coding": [{"code": "11977-6", "system": "http://loinc.org", "display": "Parity"}]}, "valueInteger": 1}], "valueString": "Pregnant", "resourceType": "Observation", "effectiveDateTime": "2024-01-01T09:00:00+00:00"}	2025-07-18 14:16:23.978756	2025-07-18 14:16:23.978756
5	Location	1	{"id": "1", "meta": {"profile": ["http://hl7.org/fhir/StructureDefinition/Location"]}, "name": "Demo Health Center", "type": [{"coding": [{"code": "HOSP", "system": "http://terminology.hl7.org/CodeSystem/v3-RoleCode", "display": "Hospital"}]}], "status": "active", "address": {"city": "Demo City", "line": ["123 Demo St"], "country": "SL", "district": "Demo District"}, "resourceType": "Location", "managingOrganization": {"display": "Demo Health Org"}}	2025-07-18 14:22:37.237113	2025-07-18 14:22:37.237113
6	Observation	ANC-2024-0001-NEO1	{"id": "ANC-2024-0001-NEO1", "code": {"coding": [{"code": "57070-2", "system": "http://loinc.org", "display": "Birth status"}]}, "meta": {"profile": ["http://hl7.org/fhir/StructureDefinition/Observation"]}, "status": "final", "subject": {"reference": "Patient/ANC-2024-0001"}, "component": [{"code": {"coding": [{"code": "8339-4", "system": "http://loinc.org", "display": "Birth weight"}]}, "valueQuantity": {"unit": "kg", "value": 3.2}}], "valueString": "Live birth", "resourceType": "Observation", "effectiveDateTime": "2024-10-08T14:30:00+00:00"}	2025-07-18 14:23:08.002538	2025-07-18 14:23:08.002538
\.


--
-- Data for Name: health_tips; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.health_tips (id, title, content, category, target_stage, target_weeks, target_visits, weeks, trimester, visit, category_type, nutrition_type, is_active, sent_count, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: indicator_metrics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.indicator_metrics (id, fhir_id, indicator_code, indicator_name, numerator_definition, denominator_definition, measurement_period, reporting_level, data_sources, meta) FROM stdin;
1	5190076e-5f99-4448-8d1a-b9d31da71dd1	ANC.01	Women with first ANC visit	Number of women attending first ANC visit	Total number of pregnant women registered	monthly	facility	{anc_visit,patient}	{"profile": ["http://hl7.org/fhir/StructureDefinition/Measure"], "resourceType": "Measure"}
\.


--
-- Data for Name: neonate; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.neonate (id, fhir_id, delivery_id, birth_order, sex, birth_weight_kg, apgar_1min, apgar_5min, resuscitation_needed, breastfeeding_initiated, vitamin_k_given, birth_defects, meta) FROM stdin;
1	9635c3c2-3de7-4fbf-bb2c-bd6f6e16d8a1	1	1	female	3.20	8	9	f	t	t	{none}	{"code": {"coding": [{"code": "57070-2", "system": "http://loinc.org", "display": "Birth status"}]}, "profile": ["http://hl7.org/fhir/StructureDefinition/Observation"], "resourceType": "Observation"}
\.


--
-- Data for Name: patient; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.patient (id, fhir_id, client_number, nin_number, name, birth_date, age, gender, address, phone, emergency_contact, responsible_person, blood_group, is_sickler, is_pregnant, registration_date, meta, created_at, updated_at) FROM stdin;
1	a3d2bc66-6d73-48eb-a273-934e4120e9a9	ANC-2024-0001	NIN-0001	[{"use": "official", "text": "Mrs Mariama Aminata Sesay", "given": ["Mariama", "Aminata"], "family": "Sesay", "prefix": ["Mrs"], "suffix": ["Jr"]}]	1992-05-10	32	female	{"city": "Demo City", "line": ["123 Demo St", "Apt 4B"], "country": "SL", "district": "Demo District", "postalCode": "12345"}	+23280000001	{"name": "Fatmata Sesay", "phone": "+23280000002", "address": "456 Demo Ave", "relationship": "sister"}	Fatmata Sesay	O+	no	yes	2024-01-15 09:00:00+00	{"source": "DAK ANC System", "profile": ["http://hl7.org/fhir/StructureDefinition/Patient"], "resourceType": "Patient"}	2024-01-15 09:00:00+00	2024-06-01 10:00:00+00
4	537d4109-d5fb-4a52-9989-b008df10f44a	ANC-2024-0125	SLNIN-1990-1234-5678	[{"use": "official", "given": ["Mariama"], "family": "Sesay", "prefix": ["Mrs"]}]	1990-06-15	33	female	{"use": "home", "city": "Freetown", "line": ["25 Bai Bureh Road"], "text": "25 Bai Bureh Road, Freetown", "type": "physical", "country": "Sierra Leone", "district": "Western Area Urban"}	+23288054344	{"name": "Alhaji Sesay", "phone": "+232762345678", "address": "Same as patient", "relationship": "husband"}	Alhaji Sesay (Husband)	A+	no	yes	2025-04-25 08:15:00+00	{"extension": [{"url": "http://hl7.org/fhir/StructureDefinition/patient-nationality", "valueCode": "SL"}, {"url": "http://who.int/dak/anc", "valueCode": "anc-client"}], "identifier": [{"value": "ANC-2024-0125", "system": "https://moh.sl/anc"}, {"value": "SLNIN-1990-1234-5678", "system": "https://nin.gov.sl"}], "resourceType": "Patient"}	2025-07-16 15:51:58.098638+00	2025-07-16 15:51:58.098638+00
\.


--
-- Data for Name: postnatal_visit; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.postnatal_visit (id, fhir_id, patient_id, delivery_id, visit_date, days_postpartum, mother_condition, bp, temperature, uterine_involution, lochia_description, breastfeeding_status, family_planning_discussed, pp_complications, neonate_checks, meta) FROM stdin;
1	3c27f408-146b-4210-97bc-808d598e0bbf	1	1	2024-10-10	2	stable	120/80	36.8	normal	normal	exclusive	t	{none}	[{"weight": 3.2, "baby_id": 1, "feeding": "exclusive"}]	{"class": {"code": "AMB", "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "display": "ambulatory"}, "profile": ["http://hl7.org/fhir/StructureDefinition/Encounter"], "resourceType": "Encounter"}
2	2def9b3a-a2c9-473a-87be-2950f998eda5	1	1	2024-10-10	2	stable	120/80	36.8	normal	normal	exclusive	t	{none}	[{"weight": 3.2, "baby_id": 1, "feeding": "exclusive"}]	{"class": {"code": "AMB", "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "display": "ambulatory"}, "profile": ["http://hl7.org/fhir/StructureDefinition/Encounter"], "resourceType": "Encounter"}
\.


--
-- Data for Name: pregnancy; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pregnancy (id, fhir_id, patient_id, lmp, edd, gravida, parity, living_children, previous_cs, height_cm, booking_weight_kg, risk_factors, meta, created_at) FROM stdin;
1	9c5fc5c7-ee87-4d02-a239-75499a2c900e	1	2025-04-01	2024-10-08	2	1	1	0	160.00	60.00	["anemia", "hypertension"]	{"code": {"coding": [{"code": "11884-4", "system": "http://loinc.org", "display": "Pregnancy status"}]}, "profile": ["http://hl7.org/fhir/StructureDefinition/Observation"], "resourceType": "Observation"}	2025-04-01 09:00:00+00
4	35054be5-d4ff-4225-b05f-66906eca6515	4	2025-04-01	2024-10-08	3	2	2	1	158.00	64.50	["previous_cs", "anaemia", "short_stature"]	{"code": {"coding": [{"code": "11884-4", "system": "http://loinc.org", "display": "Pregnancy status"}]}, "subject": {"reference": "Patient/4"}, "resourceType": "Observation"}	2025-07-16 15:56:07.224745+00
\.


--
-- Data for Name: report; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.report (id, client_number, client_name, phone_number, report_type, facility_name, description, is_anonymous, created_at, file_urls, who_guideline, dak_guideline, fhir_resource, status) FROM stdin;
1	ANC-2024-0125	Mariama Sesay	+23288054344	CHO	Test	Testing	f	2025-07-17 21:21:55.875086	{}	Respectful care	Digital Adherence	\N	pending
\.


--
-- Data for Name: system_functionality; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.system_functionality (id, fhir_id, requirement_id, requirement_description, implementation_status, last_test_date, test_result, notes, meta) FROM stdin;
1	e7ec90b0-a0e5-413f-b6a1-3e51e8ce0436	FR.ANC.01	System shall capture all required demographic information during patient registration	implemented	2024-01-20	passed	All DAK-required fields implemented with validation	{"code": {"coding": [{"code": "registration", "system": "http://who.int/dak/requirements", "display": "Registration Requirements"}]}, "resourceType": "Basic"}
2	c2ed0402-b581-487e-9d1d-6e7505ad9002	FR.ANC.01	System records first ANC visit	complete	2024-06-01	pass	Demo data for system functionality	{"profile": ["http://hl7.org/fhir/StructureDefinition/Basic"], "resourceType": "Basic"}
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, username, email, password_hash, role, created_at, updated_at) FROM stdin;
\.


--
-- Name: admin_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.admin_id_seq', 1, true);


--
-- Name: anc_visit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.anc_visit_id_seq', 1, true);


--
-- Name: chat_message_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.chat_message_id_seq', 1, true);


--
-- Name: decision_support_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.decision_support_log_id_seq', 1, true);


--
-- Name: delivery_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.delivery_id_seq', 1, false);


--
-- Name: facility_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.facility_id_seq', 4, true);


--
-- Name: fhir_resources_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.fhir_resources_id_seq', 6, true);


--
-- Name: health_tips_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.health_tips_id_seq', 1, false);


--
-- Name: indicator_metrics_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.indicator_metrics_id_seq', 1, false);


--
-- Name: neonate_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.neonate_id_seq', 1, false);


--
-- Name: patient_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.patient_id_seq', 4, true);


--
-- Name: postnatal_visit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.postnatal_visit_id_seq', 1, false);


--
-- Name: pregnancy_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pregnancy_id_seq', 4, true);


--
-- Name: report_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.report_id_seq', 1, true);


--
-- Name: system_functionality_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.system_functionality_id_seq', 1, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 1, false);


--
-- Name: admin admin_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin
    ADD CONSTRAINT admin_pkey PRIMARY KEY (id);


--
-- Name: admin admin_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin
    ADD CONSTRAINT admin_username_key UNIQUE (username);


--
-- Name: anc_visit anc_visit_fhir_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.anc_visit
    ADD CONSTRAINT anc_visit_fhir_id_key UNIQUE (fhir_id);


--
-- Name: anc_visit anc_visit_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.anc_visit
    ADD CONSTRAINT anc_visit_pkey PRIMARY KEY (id);


--
-- Name: chat_message chat_message_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_message
    ADD CONSTRAINT chat_message_pkey PRIMARY KEY (id);


--
-- Name: decision_support_log decision_support_log_fhir_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.decision_support_log
    ADD CONSTRAINT decision_support_log_fhir_id_key UNIQUE (fhir_id);


--
-- Name: decision_support_log decision_support_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.decision_support_log
    ADD CONSTRAINT decision_support_log_pkey PRIMARY KEY (id);


--
-- Name: delivery delivery_fhir_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery
    ADD CONSTRAINT delivery_fhir_id_key UNIQUE (fhir_id);


--
-- Name: delivery delivery_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery
    ADD CONSTRAINT delivery_pkey PRIMARY KEY (id);


--
-- Name: facility facility_fhir_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.facility
    ADD CONSTRAINT facility_fhir_id_key UNIQUE (fhir_id);


--
-- Name: facility facility_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.facility
    ADD CONSTRAINT facility_pkey PRIMARY KEY (id);


--
-- Name: fhir_resources fhir_resources_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fhir_resources
    ADD CONSTRAINT fhir_resources_pkey PRIMARY KEY (id);


--
-- Name: health_tips health_tips_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.health_tips
    ADD CONSTRAINT health_tips_pkey PRIMARY KEY (id);


--
-- Name: indicator_metrics indicator_metrics_fhir_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.indicator_metrics
    ADD CONSTRAINT indicator_metrics_fhir_id_key UNIQUE (fhir_id);


--
-- Name: indicator_metrics indicator_metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.indicator_metrics
    ADD CONSTRAINT indicator_metrics_pkey PRIMARY KEY (id);


--
-- Name: neonate neonate_fhir_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.neonate
    ADD CONSTRAINT neonate_fhir_id_key UNIQUE (fhir_id);


--
-- Name: neonate neonate_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.neonate
    ADD CONSTRAINT neonate_pkey PRIMARY KEY (id);


--
-- Name: patient patient_client_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient
    ADD CONSTRAINT patient_client_number_key UNIQUE (client_number);


--
-- Name: patient patient_fhir_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient
    ADD CONSTRAINT patient_fhir_id_key UNIQUE (fhir_id);


--
-- Name: patient patient_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient
    ADD CONSTRAINT patient_pkey PRIMARY KEY (id);


--
-- Name: postnatal_visit postnatal_visit_fhir_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.postnatal_visit
    ADD CONSTRAINT postnatal_visit_fhir_id_key UNIQUE (fhir_id);


--
-- Name: postnatal_visit postnatal_visit_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.postnatal_visit
    ADD CONSTRAINT postnatal_visit_pkey PRIMARY KEY (id);


--
-- Name: pregnancy pregnancy_fhir_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pregnancy
    ADD CONSTRAINT pregnancy_fhir_id_key UNIQUE (fhir_id);


--
-- Name: pregnancy pregnancy_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pregnancy
    ADD CONSTRAINT pregnancy_pkey PRIMARY KEY (id);


--
-- Name: report report_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report
    ADD CONSTRAINT report_pkey PRIMARY KEY (id);


--
-- Name: system_functionality system_functionality_fhir_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_functionality
    ADD CONSTRAINT system_functionality_fhir_id_key UNIQUE (fhir_id);


--
-- Name: system_functionality system_functionality_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_functionality
    ADD CONSTRAINT system_functionality_pkey PRIMARY KEY (id);


--
-- Name: fhir_resources unique_resource; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fhir_resources
    ADD CONSTRAINT unique_resource UNIQUE (resource_type, resource_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: idx_anc_visit_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_anc_visit_date ON public.anc_visit USING btree (visit_date);


--
-- Name: idx_anc_visit_facility; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_anc_visit_facility ON public.anc_visit USING btree (facility_id);


--
-- Name: idx_anc_visit_patient; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_anc_visit_patient ON public.anc_visit USING btree (patient_id);


--
-- Name: idx_data_gin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_data_gin ON public.fhir_resources USING gin (data);


--
-- Name: idx_decision_support_visit; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_decision_support_visit ON public.decision_support_log USING btree (anc_visit_id);


--
-- Name: idx_delivery_pregnancy; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_delivery_pregnancy ON public.delivery USING btree (pregnancy_id);


--
-- Name: idx_neonate_delivery; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_neonate_delivery ON public.neonate USING btree (delivery_id);


--
-- Name: idx_patient_client_number; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_patient_client_number ON public.patient USING btree (client_number);


--
-- Name: idx_postnatal_visit_patient; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_postnatal_visit_patient ON public.postnatal_visit USING btree (patient_id);


--
-- Name: idx_pregnancy_patient; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pregnancy_patient ON public.pregnancy USING btree (patient_id);


--
-- Name: idx_resource_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resource_id ON public.fhir_resources USING btree (resource_id);


--
-- Name: idx_resource_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resource_type ON public.fhir_resources USING btree (resource_type);


--
-- Name: anc_visit anc_visit_facility_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.anc_visit
    ADD CONSTRAINT anc_visit_facility_id_fkey FOREIGN KEY (facility_id) REFERENCES public.facility(id);


--
-- Name: anc_visit anc_visit_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.anc_visit
    ADD CONSTRAINT anc_visit_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patient(id);


--
-- Name: decision_support_log decision_support_log_anc_visit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.decision_support_log
    ADD CONSTRAINT decision_support_log_anc_visit_id_fkey FOREIGN KEY (anc_visit_id) REFERENCES public.anc_visit(id);


--
-- Name: delivery delivery_facility_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery
    ADD CONSTRAINT delivery_facility_id_fkey FOREIGN KEY (facility_id) REFERENCES public.facility(id);


--
-- Name: delivery delivery_pregnancy_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery
    ADD CONSTRAINT delivery_pregnancy_id_fkey FOREIGN KEY (pregnancy_id) REFERENCES public.pregnancy(id);


--
-- Name: neonate neonate_delivery_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.neonate
    ADD CONSTRAINT neonate_delivery_id_fkey FOREIGN KEY (delivery_id) REFERENCES public.delivery(id);


--
-- Name: postnatal_visit postnatal_visit_delivery_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.postnatal_visit
    ADD CONSTRAINT postnatal_visit_delivery_id_fkey FOREIGN KEY (delivery_id) REFERENCES public.delivery(id);


--
-- Name: postnatal_visit postnatal_visit_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.postnatal_visit
    ADD CONSTRAINT postnatal_visit_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patient(id);


--
-- Name: pregnancy pregnancy_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pregnancy
    ADD CONSTRAINT pregnancy_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patient(id);


--
-- PostgreSQL database dump complete
--

