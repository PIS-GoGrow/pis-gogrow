--
-- PostgreSQL database dump
--

\restrict 2BqrV7fixlF37GUwV79mIgpmN2MBZd7U9HFGroTGTHVUQZuibsyqrmbKXTSnbll

-- Dumped from database version 17.11 (Debian 17.11-1.pgdg13+2)
-- Dumped by pg_dump version 17.11 (Debian 17.11-1.pgdg13+2)

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id character varying NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.active_storage_attachments OWNER TO postgres;

--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.active_storage_attachments_id_seq OWNER TO postgres;

--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.active_storage_blobs OWNER TO postgres;

--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.active_storage_blobs_id_seq OWNER TO postgres;

--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


ALTER TABLE public.active_storage_variant_records OWNER TO postgres;

--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNER TO postgres;

--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.ar_internal_metadata OWNER TO postgres;

--
-- Name: motor_admin_user_roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.motor_admin_user_roles (
    id bigint NOT NULL,
    admin_user_id bigint NOT NULL,
    role_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.motor_admin_user_roles OWNER TO postgres;

--
-- Name: motor_admin_user_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.motor_admin_user_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.motor_admin_user_roles_id_seq OWNER TO postgres;

--
-- Name: motor_admin_user_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.motor_admin_user_roles_id_seq OWNED BY public.motor_admin_user_roles.id;


--
-- Name: motor_admin_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.motor_admin_users (
    id bigint NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    first_name character varying,
    last_name character varying,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp(6) without time zone,
    remember_created_at timestamp(6) without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp(6) without time zone,
    last_sign_in_at timestamp(6) without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying,
    failed_attempts integer DEFAULT 0 NOT NULL,
    unlock_token character varying,
    locked_at timestamp(6) without time zone,
    deleted_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.motor_admin_users OWNER TO postgres;

--
-- Name: motor_admin_users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.motor_admin_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.motor_admin_users_id_seq OWNER TO postgres;

--
-- Name: motor_admin_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.motor_admin_users_id_seq OWNED BY public.motor_admin_users.id;


--
-- Name: motor_alert_locks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.motor_alert_locks (
    id bigint NOT NULL,
    alert_id bigint NOT NULL,
    lock_timestamp character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.motor_alert_locks OWNER TO postgres;

--
-- Name: motor_alert_locks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.motor_alert_locks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.motor_alert_locks_id_seq OWNER TO postgres;

--
-- Name: motor_alert_locks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.motor_alert_locks_id_seq OWNED BY public.motor_alert_locks.id;


--
-- Name: motor_alerts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.motor_alerts (
    id bigint NOT NULL,
    query_id bigint NOT NULL,
    name character varying NOT NULL,
    description text,
    to_emails text NOT NULL,
    is_enabled boolean DEFAULT true NOT NULL,
    preferences text NOT NULL,
    author_id bigint,
    author_type character varying,
    deleted_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.motor_alerts OWNER TO postgres;

--
-- Name: motor_alerts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.motor_alerts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.motor_alerts_id_seq OWNER TO postgres;

--
-- Name: motor_alerts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.motor_alerts_id_seq OWNED BY public.motor_alerts.id;


--
-- Name: motor_api_configs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.motor_api_configs (
    id bigint NOT NULL,
    name character varying NOT NULL,
    url character varying NOT NULL,
    preferences text NOT NULL,
    credentials text NOT NULL,
    description text,
    deleted_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.motor_api_configs OWNER TO postgres;

--
-- Name: motor_api_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.motor_api_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.motor_api_configs_id_seq OWNER TO postgres;

--
-- Name: motor_api_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.motor_api_configs_id_seq OWNED BY public.motor_api_configs.id;


--
-- Name: motor_audits; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.motor_audits (
    id bigint NOT NULL,
    auditable_id character varying,
    auditable_type character varying,
    associated_id character varying,
    associated_type character varying,
    user_id bigint,
    user_type character varying,
    username character varying,
    action character varying,
    audited_changes text,
    version bigint DEFAULT 0,
    comment text,
    remote_address character varying,
    request_uuid character varying,
    created_at timestamp(6) without time zone
);


ALTER TABLE public.motor_audits OWNER TO postgres;

--
-- Name: motor_audits_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.motor_audits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.motor_audits_id_seq OWNER TO postgres;

--
-- Name: motor_audits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.motor_audits_id_seq OWNED BY public.motor_audits.id;


--
-- Name: motor_configs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.motor_configs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    value text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.motor_configs OWNER TO postgres;

--
-- Name: motor_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.motor_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.motor_configs_id_seq OWNER TO postgres;

--
-- Name: motor_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.motor_configs_id_seq OWNED BY public.motor_configs.id;


--
-- Name: motor_dashboards; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.motor_dashboards (
    id bigint NOT NULL,
    title character varying NOT NULL,
    description text,
    preferences text NOT NULL,
    author_id bigint,
    author_type character varying,
    deleted_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.motor_dashboards OWNER TO postgres;

--
-- Name: motor_dashboards_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.motor_dashboards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.motor_dashboards_id_seq OWNER TO postgres;

--
-- Name: motor_dashboards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.motor_dashboards_id_seq OWNED BY public.motor_dashboards.id;


--
-- Name: motor_encrypted_configs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.motor_encrypted_configs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    value text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.motor_encrypted_configs OWNER TO postgres;

--
-- Name: motor_encrypted_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.motor_encrypted_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.motor_encrypted_configs_id_seq OWNER TO postgres;

--
-- Name: motor_encrypted_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.motor_encrypted_configs_id_seq OWNED BY public.motor_encrypted_configs.id;


--
-- Name: motor_forms; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.motor_forms (
    id bigint NOT NULL,
    name character varying NOT NULL,
    description text,
    api_path text NOT NULL,
    http_method character varying NOT NULL,
    preferences text NOT NULL,
    author_id bigint,
    author_type character varying,
    deleted_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    api_config_name character varying NOT NULL
);


ALTER TABLE public.motor_forms OWNER TO postgres;

--
-- Name: motor_forms_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.motor_forms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.motor_forms_id_seq OWNER TO postgres;

--
-- Name: motor_forms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.motor_forms_id_seq OWNED BY public.motor_forms.id;


--
-- Name: motor_note_tag_tags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.motor_note_tag_tags (
    id bigint NOT NULL,
    tag_id bigint NOT NULL,
    note_id bigint NOT NULL
);


ALTER TABLE public.motor_note_tag_tags OWNER TO postgres;

--
-- Name: motor_note_tag_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.motor_note_tag_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.motor_note_tag_tags_id_seq OWNER TO postgres;

--
-- Name: motor_note_tag_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.motor_note_tag_tags_id_seq OWNED BY public.motor_note_tag_tags.id;


--
-- Name: motor_note_tags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.motor_note_tags (
    id bigint NOT NULL,
    name character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.motor_note_tags OWNER TO postgres;

--
-- Name: motor_note_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.motor_note_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.motor_note_tags_id_seq OWNER TO postgres;

--
-- Name: motor_note_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.motor_note_tags_id_seq OWNED BY public.motor_note_tags.id;


--
-- Name: motor_notes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.motor_notes (
    id bigint NOT NULL,
    body text,
    author_id bigint,
    author_type character varying,
    record_id character varying NOT NULL,
    record_type character varying NOT NULL,
    deleted_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.motor_notes OWNER TO postgres;

--
-- Name: motor_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.motor_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.motor_notes_id_seq OWNER TO postgres;

--
-- Name: motor_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.motor_notes_id_seq OWNED BY public.motor_notes.id;


--
-- Name: motor_notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.motor_notifications (
    id bigint NOT NULL,
    title character varying NOT NULL,
    description text,
    recipient_id bigint NOT NULL,
    recipient_type character varying NOT NULL,
    record_id character varying,
    record_type character varying,
    status character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.motor_notifications OWNER TO postgres;

--
-- Name: motor_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.motor_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.motor_notifications_id_seq OWNER TO postgres;

--
-- Name: motor_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.motor_notifications_id_seq OWNED BY public.motor_notifications.id;


--
-- Name: motor_queries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.motor_queries (
    id bigint NOT NULL,
    name character varying NOT NULL,
    description text,
    sql_body text NOT NULL,
    preferences text NOT NULL,
    author_id bigint,
    author_type character varying,
    deleted_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.motor_queries OWNER TO postgres;

--
-- Name: motor_queries_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.motor_queries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.motor_queries_id_seq OWNER TO postgres;

--
-- Name: motor_queries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.motor_queries_id_seq OWNED BY public.motor_queries.id;


--
-- Name: motor_reminders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.motor_reminders (
    id bigint NOT NULL,
    author_id bigint NOT NULL,
    author_type character varying NOT NULL,
    recipient_id bigint NOT NULL,
    recipient_type character varying NOT NULL,
    record_id character varying,
    record_type character varying,
    scheduled_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.motor_reminders OWNER TO postgres;

--
-- Name: motor_reminders_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.motor_reminders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.motor_reminders_id_seq OWNER TO postgres;

--
-- Name: motor_reminders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.motor_reminders_id_seq OWNED BY public.motor_reminders.id;


--
-- Name: motor_resources; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.motor_resources (
    id bigint NOT NULL,
    name character varying NOT NULL,
    preferences text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.motor_resources OWNER TO postgres;

--
-- Name: motor_resources_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.motor_resources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.motor_resources_id_seq OWNER TO postgres;

--
-- Name: motor_resources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.motor_resources_id_seq OWNED BY public.motor_resources.id;


--
-- Name: motor_roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.motor_roles (
    id bigint NOT NULL,
    name character varying NOT NULL,
    rules text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.motor_roles OWNER TO postgres;

--
-- Name: motor_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.motor_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.motor_roles_id_seq OWNER TO postgres;

--
-- Name: motor_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.motor_roles_id_seq OWNED BY public.motor_roles.id;


--
-- Name: motor_taggable_tags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.motor_taggable_tags (
    id bigint NOT NULL,
    tag_id bigint NOT NULL,
    taggable_id bigint NOT NULL,
    taggable_type character varying NOT NULL
);


ALTER TABLE public.motor_taggable_tags OWNER TO postgres;

--
-- Name: motor_taggable_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.motor_taggable_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.motor_taggable_tags_id_seq OWNER TO postgres;

--
-- Name: motor_taggable_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.motor_taggable_tags_id_seq OWNED BY public.motor_taggable_tags.id;


--
-- Name: motor_tags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.motor_tags (
    id bigint NOT NULL,
    name character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.motor_tags OWNER TO postgres;

--
-- Name: motor_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.motor_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.motor_tags_id_seq OWNER TO postgres;

--
-- Name: motor_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.motor_tags_id_seq OWNED BY public.motor_tags.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO postgres;

--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: motor_admin_user_roles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_admin_user_roles ALTER COLUMN id SET DEFAULT nextval('public.motor_admin_user_roles_id_seq'::regclass);


--
-- Name: motor_admin_users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_admin_users ALTER COLUMN id SET DEFAULT nextval('public.motor_admin_users_id_seq'::regclass);


--
-- Name: motor_alert_locks id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_alert_locks ALTER COLUMN id SET DEFAULT nextval('public.motor_alert_locks_id_seq'::regclass);


--
-- Name: motor_alerts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_alerts ALTER COLUMN id SET DEFAULT nextval('public.motor_alerts_id_seq'::regclass);


--
-- Name: motor_api_configs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_api_configs ALTER COLUMN id SET DEFAULT nextval('public.motor_api_configs_id_seq'::regclass);


--
-- Name: motor_audits id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_audits ALTER COLUMN id SET DEFAULT nextval('public.motor_audits_id_seq'::regclass);


--
-- Name: motor_configs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_configs ALTER COLUMN id SET DEFAULT nextval('public.motor_configs_id_seq'::regclass);


--
-- Name: motor_dashboards id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_dashboards ALTER COLUMN id SET DEFAULT nextval('public.motor_dashboards_id_seq'::regclass);


--
-- Name: motor_encrypted_configs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_encrypted_configs ALTER COLUMN id SET DEFAULT nextval('public.motor_encrypted_configs_id_seq'::regclass);


--
-- Name: motor_forms id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_forms ALTER COLUMN id SET DEFAULT nextval('public.motor_forms_id_seq'::regclass);


--
-- Name: motor_note_tag_tags id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_note_tag_tags ALTER COLUMN id SET DEFAULT nextval('public.motor_note_tag_tags_id_seq'::regclass);


--
-- Name: motor_note_tags id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_note_tags ALTER COLUMN id SET DEFAULT nextval('public.motor_note_tags_id_seq'::regclass);


--
-- Name: motor_notes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_notes ALTER COLUMN id SET DEFAULT nextval('public.motor_notes_id_seq'::regclass);


--
-- Name: motor_notifications id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_notifications ALTER COLUMN id SET DEFAULT nextval('public.motor_notifications_id_seq'::regclass);


--
-- Name: motor_queries id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_queries ALTER COLUMN id SET DEFAULT nextval('public.motor_queries_id_seq'::regclass);


--
-- Name: motor_reminders id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_reminders ALTER COLUMN id SET DEFAULT nextval('public.motor_reminders_id_seq'::regclass);


--
-- Name: motor_resources id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_resources ALTER COLUMN id SET DEFAULT nextval('public.motor_resources_id_seq'::regclass);


--
-- Name: motor_roles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_roles ALTER COLUMN id SET DEFAULT nextval('public.motor_roles_id_seq'::regclass);


--
-- Name: motor_taggable_tags id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_taggable_tags ALTER COLUMN id SET DEFAULT nextval('public.motor_taggable_tags_id_seq'::regclass);


--
-- Name: motor_tags id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_tags ALTER COLUMN id SET DEFAULT nextval('public.motor_tags_id_seq'::regclass);


--
-- Data for Name: active_storage_attachments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.active_storage_attachments (id, name, record_type, record_id, blob_id, created_at) FROM stdin;
\.


--
-- Data for Name: active_storage_blobs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.active_storage_blobs (id, key, filename, content_type, metadata, service_name, byte_size, checksum, created_at) FROM stdin;
\.


--
-- Data for Name: active_storage_variant_records; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.active_storage_variant_records (id, blob_id, variation_digest) FROM stdin;
\.


--
-- Data for Name: ar_internal_metadata; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ar_internal_metadata (key, value, created_at, updated_at) FROM stdin;
environment	production	2026-09-21 20:54:22.971836	2026-09-21 20:54:22.971836
\.


--
-- Data for Name: motor_admin_user_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.motor_admin_user_roles (id, admin_user_id, role_id, created_at, updated_at) FROM stdin;
1	1	1	2026-09-21 20:54:47.357129	2026-09-21 20:54:47.357129
\.


--
-- Data for Name: motor_admin_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.motor_admin_users (id, email, first_name, last_name, encrypted_password, reset_password_token, reset_password_sent_at, remember_created_at, sign_in_count, current_sign_in_at, last_sign_in_at, current_sign_in_ip, last_sign_in_ip, failed_attempts, unlock_token, locked_at, deleted_at, created_at, updated_at) FROM stdin;
1	rrhh.gogrow@gmail.com			$2a$12$ctDUkiSQYyVIqx4vFhnR9OhHQ3G/qPflW8D8zjok77oympWV23mE6	\N	\N	2026-09-21 20:56:05.17875	3	2026-09-21 21:04:08.911392	2026-09-21 20:56:05.183711	192.168.65.1	192.168.65.1	0	\N	\N	\N	2026-09-21 20:54:47.355552	2026-09-21 21:04:08.911974
\.


--
-- Data for Name: motor_alert_locks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.motor_alert_locks (id, alert_id, lock_timestamp, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: motor_alerts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.motor_alerts (id, query_id, name, description, to_emails, is_enabled, preferences, author_id, author_type, deleted_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: motor_api_configs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.motor_api_configs (id, name, url, preferences, credentials, description, deleted_at, created_at, updated_at) FROM stdin;
1	https://jsonplaceholder.typicode.com	https://jsonplaceholder.typicode.com	{}	{"p":"yXM=","h":{"iv":"wyXEyWJdzKBtOvKu","at":"IDBUkDFYUkBGUVQMnmxUkQ=="}}	\N	\N	2026-09-21 20:54:22.949954	2026-09-21 20:54:22.949954
2	origin	/	{}	{"p":"4iQ=","h":{"iv":"QI5tgsxV6sLMMUuV","at":"uF7ON2Jzx7ZtZBylHk53nQ=="}}	\N	\N	2026-09-21 20:54:22.95642	2026-09-21 20:54:22.95642
\.


--
-- Data for Name: motor_audits; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.motor_audits (id, auditable_id, auditable_type, associated_id, associated_type, user_id, user_type, username, action, audited_changes, version, comment, remote_address, request_uuid, created_at) FROM stdin;
1	1	Motor::Config	\N	\N	1	Motor::AdminUser	\N	update	{"value":[[{"name":"😎 Motor Admin Pro","path":"https://www.getmotoradmin.com/pro"},{"name":"⭐ Star on GitHub","path":"https://github.com/motor-admin/motor-admin"}],[{"name":"Reports","link_type":"reports"},{"name":"Forms","link_type":"forms"},{"name":"😎 Motor Admin Pro","path":"https://www.getmotoradmin.com/pro"}]]}	1	\N	192.168.65.1	fea14099-5a95-4e99-86e9-67e79b5116e8	2026-09-21 20:57:02.747092
2	1	Motor::Config	\N	\N	1	Motor::AdminUser	\N	update	{"value":[[{"name":"Reports","link_type":"reports"},{"name":"Forms","link_type":"forms"},{"name":"😎 Motor Admin Pro","path":"https://www.getmotoradmin.com/pro"}],[{"name":"Reports","link_type":"reports"},{"name":"Forms","link_type":"forms"}]]}	2	\N	192.168.65.1	bf555b2a-ed44-40d4-a439-e2c9d94a26b4	2026-09-21 20:57:05.299994
3	134	Menu	\N	\N	1	Motor::AdminUser	\N	update	{"price":["500.0","600.0"]}	1	\N	192.168.65.1	aa019b00-ab8a-4e9c-9dbb-a15612400969	2026-09-21 20:59:34.264115
4	2	Motor::Query	\N	\N	1	Motor::AdminUser	\N	create	{"name":"Menús más pedidos","description":"Muestra los menús más pedidos, así como la cantidad de menús que se pidieron históricamente.","sql_body":"SELECT menus.id AS menu_id, menus.name, SUM(orders.amount) AS total_orders\\nFROM orders INNER JOIN schedules ON orders.schedule_id = schedules.id\\n            INNER JOIN menus ON schedules.menu_id = menus.id\\nGROUP BY menus.id;\\n","preferences":{"query_type":"sql","database":"Default","visualization":"table","visualization_options":{},"variables":[]},"author_id":null,"author_type":null,"deleted_at":null}	1	\N	192.168.65.1	fd1175fe-1499-497d-a87a-a6dc46649a88	2026-09-21 21:06:53.061454
5	2	Motor::Query	\N	\N	1	Motor::AdminUser	\N	update	{"sql_body":["SELECT menus.id AS menu_id, menus.name, SUM(orders.amount) AS total_orders\\nFROM orders INNER JOIN schedules ON orders.schedule_id = schedules.id\\n            INNER JOIN menus ON schedules.menu_id = menus.id\\nGROUP BY menus.id;\\n","SELECT menus.provider_id, menus.id AS menu_id, menus.name, SUM(orders.amount) AS total_orders\\nFROM orders INNER JOIN schedules ON orders.schedule_id = schedules.id\\n            INNER JOIN menus ON schedules.menu_id = menus.id\\nGROUP BY menus.id\\nORDER BY total_orders DESC;"]}	2	\N	192.168.65.1	ec8d4e4f-4de0-4533-ad3e-26522492f23f	2026-09-21 21:07:34.081359
6	2	Motor::Query	\N	\N	1	Motor::AdminUser	\N	update	{"name":["Menús más pedidos","Platos más pedidos"],"description":["Muestra los menús más pedidos, así como la cantidad de menús que se pidieron históricamente.","Muestra los platos más pedidos con su proveedor, así como la cantidad que se pidieron históricamente."]}	3	\N	192.168.65.1	f8f7d73a-99df-4ee4-a3b2-d0cf62324447	2026-09-21 21:08:02.789852
7	2	Motor::Query	\N	\N	1	Motor::AdminUser	\N	update	{"sql_body":["SELECT menus.provider_id, menus.id AS menu_id, menus.name, SUM(orders.amount) AS total_orders\\nFROM orders INNER JOIN schedules ON orders.schedule_id = schedules.id\\n            INNER JOIN menus ON schedules.menu_id = menus.id\\nGROUP BY menus.id\\nORDER BY total_orders DESC;","SELECT menus.provider_id, users.name AS provider_name, menus.id AS menu_id, menus.name, SUM(orders.amount) AS total_orders\\nFROM orders INNER JOIN schedules ON orders.schedule_id = schedules.id\\n            INNER JOIN menus ON schedules.menu_id = menus.id\\n            INNER JOIN providers ON menus.provider_id = providers.id\\n            INNER JOIN users ON providers.user_id = users.id\\nGROUP BY users.id, menus.id\\nORDER BY total_orders DESC;"]}	4	\N	192.168.65.1	0db973f6-4d48-4a15-a89b-7b5b87054ddc	2026-09-21 21:10:03.031832
8	1	Motor::Dashboard	\N	\N	1	Motor::AdminUser	\N	update	{"deleted_at":[null,"2026-09-21T21:10:43.980Z"]}	1	\N	192.168.65.1	4b4197d9-7a8f-4b78-886b-1b6dc66fcd05	2026-09-21 21:10:43.987936
9	1	Motor::Query	\N	\N	1	Motor::AdminUser	\N	update	{"deleted_at":[null,"2026-09-21T21:10:46.454Z"]}	1	\N	192.168.65.1	ab109fe4-554c-49cc-a9c2-eed67d89bef9	2026-09-21 21:10:46.457567
10	3	Motor::Query	\N	\N	1	Motor::AdminUser	\N	create	{"name":"Proveedores con más pedidos","description":null,"sql_body":"SELECT providers.id AS provider_id, users.name AS provider_name, SUM(orders.amount) AS total_orders\\nFROM orders INNER JOIN schedules ON orders.schedule_id = schedules.id\\n            INNER JOIN menus ON schedules.menu_id = menus.id\\n            INNER JOIN providers ON menus.provider_id = providers.id\\n            INNER JOIN users ON providers.user_id = users.id\\nGROUP BY providers.id, users.id\\nORDER BY total_orders DESC;","preferences":{"query_type":"sql","database":"Default","visualization":"table","visualization_options":{},"variables":[]},"author_id":null,"author_type":null,"deleted_at":null}	1	\N	192.168.65.1	5b5cbdb8-2b49-487c-9626-bb59c31e1011	2026-09-21 21:13:20.62448
11	4	Motor::Query	\N	\N	1	Motor::AdminUser	\N	create	{"name":"Órdenes sin cuenta asignada","description":"Estas órdenes no van a ser cobradas. Su existencia representa un error en la aplicación a revisar","sql_body":"SELECT * FROM orders WHERE orders.id NOT IN (SELECT DISTINCT order_id FROM order_accounts)","preferences":{"query_type":"sql","database":"Default","visualization":"table","visualization_options":{},"variables":[]},"author_id":null,"author_type":null,"deleted_at":null}	1	\N	192.168.65.1	f6badacb-4bf6-4da9-9433-052e5753af58	2026-09-21 21:15:56.632633
12	4	Motor::Query	\N	\N	1	Motor::AdminUser	\N	update	{"sql_body":["SELECT * FROM orders WHERE orders.id NOT IN (SELECT DISTINCT order_id FROM order_accounts)","(\\n    SELECT *\\n    FROM orders\\n    WHERE orders.price - orders.discounted_price \\u003e 0\\n          AND orders.id NOT IN (SELECT DISTINCT order_accounts.order_id\\n                                FROM order_accounts INNER JOIN accounts ON accounts.id = order_accounts.account_id\\n                                WHERE accounts.owner_type = 'Consumer')\\n) UNION (\\n    SELECT *\\n    FROM orders\\n    WHERE orders.discounted_price \\u003e 0\\n          AND orders.id NOT IN (SELECT DISTINCT order_accounts.order_id\\n                                FROM order_accounts INNER JOIN accounts ON accounts.id = order_accounts.account_id\\n                                WHERE accounts.owner_type = 'Company')\\n)"]}	2	\N	192.168.65.1	b19afe5c-c455-4f5b-b6c4-d7c6981a0af0	2026-09-21 21:21:26.541817
13	5	Motor::Query	\N	\N	1	Motor::AdminUser	\N	create	{"name":"Cuentas con montos discrepantes","description":null,"sql_body":"SELECT *\\nFROM accounts\\nWHERE accounts.owner_type = 'Consumer'\\n      AND accounts.amount \\u003c\\u003e (SELECT SUM(orders.price - orders.discounted_price)\\n                              FROM orders INNER JOIN order_accounts ON order_accounts.order_id = orders.id\\n                              WHERE order_accounts.account_id = accounts.id)","preferences":{"query_type":"sql","database":"Default","visualization":"table","visualization_options":{},"variables":[]},"author_id":null,"author_type":null,"deleted_at":null}	1	\N	192.168.65.1	c9e6d432-f6a7-430a-931a-5974cb74e0c2	2026-09-21 21:28:21.007312
14	5	Motor::Query	\N	\N	1	Motor::AdminUser	\N	update	{"description":[null,"Las cuentas calculan el monto de sus órdenes en un atributo. Si esto se calcula mal, el empleado va a pagar un precio que no es el correcto."],"sql_body":["SELECT *\\nFROM accounts\\nWHERE accounts.owner_type = 'Consumer'\\n      AND accounts.amount \\u003c\\u003e (SELECT SUM(orders.price - orders.discounted_price)\\n                              FROM orders INNER JOIN order_accounts ON order_accounts.order_id = orders.id\\n                              WHERE order_accounts.account_id = accounts.id)","(\\n    SELECT *\\n    FROM (\\n      SELECT accounts.*,\\n             (SELECT SUM(orders.price - orders.discounted_price)\\n              FROM orders\\n              INNER JOIN order_accounts ON order_accounts.order_id = orders.id\\n              WHERE order_accounts.account_id = accounts.id\\n                AND orders.status = 1) AS real_amount\\n      FROM accounts\\n      WHERE accounts.owner_type = 'Consumer'\\n    ) t\\n    WHERE t.amount IS DISTINCT FROM t.real_amount\\n) UNION (\\n    SELECT *\\n    FROM (\\n      SELECT accounts.*,\\n             (SELECT SUM(orders.discounted_price)\\n              FROM orders\\n              INNER JOIN order_accounts ON order_accounts.order_id = orders.id\\n              WHERE order_accounts.account_id = accounts.id\\n                AND orders.status = 1) AS real_amount\\n      FROM accounts\\n      WHERE accounts.owner_type = 'Company'\\n    ) t\\n    WHERE t.amount IS DISTINCT FROM t.real_amount\\n)"]}	2	\N	192.168.65.1	a941d8ee-919e-4b56-8b38-579eb67657c3	2026-09-21 21:37:19.743325
15	4	Motor::Query	\N	\N	1	Motor::AdminUser	\N	update	{"description":["Estas órdenes no van a ser cobradas. Su existencia representa un error en la aplicación a revisar","Estas órdenes no van a ser cobradas. Su existencia representa un error a revisar en la aplicación"],"sql_body":["(\\n    SELECT *\\n    FROM orders\\n    WHERE orders.price - orders.discounted_price \\u003e 0\\n          AND orders.id NOT IN (SELECT DISTINCT order_accounts.order_id\\n                                FROM order_accounts INNER JOIN accounts ON accounts.id = order_accounts.account_id\\n                                WHERE accounts.owner_type = 'Consumer')\\n) UNION (\\n    SELECT *\\n    FROM orders\\n    WHERE orders.discounted_price \\u003e 0\\n          AND orders.id NOT IN (SELECT DISTINCT order_accounts.order_id\\n                                FROM order_accounts INNER JOIN accounts ON accounts.id = order_accounts.account_id\\n                                WHERE accounts.owner_type = 'Company')\\n)","(\\n    SELECT 'Consumer' AS account_missing, *\\n    FROM orders\\n    WHERE orders.price - orders.discounted_price \\u003e 0\\n          AND orders.id NOT IN (SELECT DISTINCT order_accounts.order_id\\n                                FROM order_accounts INNER JOIN accounts ON accounts.id = order_accounts.account_id\\n                                WHERE accounts.owner_type = 'Consumer')\\n) UNION (\\n    SELECT 'Company' AS account_missing, *\\n    FROM orders\\n    WHERE orders.discounted_price \\u003e 0\\n          AND orders.id NOT IN (SELECT DISTINCT order_accounts.order_id\\n                                FROM order_accounts INNER JOIN accounts ON accounts.id = order_accounts.account_id\\n                                WHERE accounts.owner_type = 'Company')\\n)"]}	3	\N	192.168.65.1	d95aaddb-cdc6-439f-97e3-c0dfa716f3ba	2026-09-22 00:36:20.64782
16	6	Motor::Query	\N	\N	1	Motor::AdminUser	\N	create	{"name":"Sesiones con roles discrepantes","description":"Un usuario no debería efectuar un rol en una sesión, si no lo posee.","sql_body":"SELECT *\\nFROM sessions\\nWHERE (sessions.role = 0 AND NOT EXISTS (SELECT * FROM providers WHERE providers.user_id = sessions.user_id))\\n      OR (sessions.role = 1 AND NOT EXISTS (SELECT * FROM consumers WHERE consumers.user_id = sessions.user_id))\\n      OR (sessions.role = 2 AND NOT EXISTS (SELECT * FROM admins WHERE admins.user_id = sessions.user_id))","preferences":{"query_type":"sql","database":"Default","visualization":"table","visualization_options":{},"variables":[]},"author_id":null,"author_type":null,"deleted_at":null}	1	\N	192.168.65.1	f69d0a86-740e-4c1c-9466-c31f3a172b01	2026-09-22 00:44:28.046982
\.


--
-- Data for Name: motor_configs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.motor_configs (id, key, value, created_at, updated_at) FROM stdin;
1	header.links	[{"name":"Reports","link_type":"reports"},{"name":"Forms","link_type":"forms"}]	2026-09-21 20:54:22.909604	2026-09-21 20:57:05.297672
\.


--
-- Data for Name: motor_dashboards; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.motor_dashboards (id, title, description, preferences, author_id, author_type, deleted_at, created_at, updated_at) FROM stdin;
1	Hello Dashboard	\N	{"layout":[{"title":"Hello","query_id":1,"size":"2x1"}]}	\N	\N	2026-09-21 21:10:43.980617	2026-09-21 20:54:22.917242	2026-09-21 21:10:43.98194
\.


--
-- Data for Name: motor_encrypted_configs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.motor_encrypted_configs (id, key, value, created_at, updated_at) FROM stdin;
1	database.credentials	{"p":"w1ugrZIcUR605T8+RZbXZGMcRKI1RRJvDdJgNIr2v7R4BFHrZDj4AIP6ZSUSOoVOvI/T9mYxF2MDnJ68GovIMPaaULoIFggDt9c79O8H8VMkqeDi1haCSmycE9ATMQ1g","h":{"iv":"uob7hsGAvPCyT0H1","at":"UK8hhr8TkFQMudqBXY7Stw=="}}	2026-09-21 20:55:32.143423	2026-09-21 20:58:31.901879
\.


--
-- Data for Name: motor_forms; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.motor_forms (id, name, description, api_path, http_method, preferences, author_id, author_type, deleted_at, created_at, updated_at, api_config_name) FROM stdin;
1	Hello Form	\N	/todos	POST	{"fields":[{"display_name":"Message","name":"message","field_type":"richtext","validators":[{"required":true}],"is_array":false}]}	\N	\N	\N	2026-09-21 20:54:22.920579	2026-09-21 20:54:22.951326	https://jsonplaceholder.typicode.com
\.


--
-- Data for Name: motor_note_tag_tags; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.motor_note_tag_tags (id, tag_id, note_id) FROM stdin;
\.


--
-- Data for Name: motor_note_tags; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.motor_note_tags (id, name, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: motor_notes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.motor_notes (id, body, author_id, author_type, record_id, record_type, deleted_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: motor_notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.motor_notifications (id, title, description, recipient_id, recipient_type, record_id, record_type, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: motor_queries; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.motor_queries (id, name, description, sql_body, preferences, author_id, author_type, deleted_at, created_at, updated_at) FROM stdin;
1	Hello Query	\N	SELECT 'Hello there'	{"visualization":"value"}	\N	\N	2026-09-21 21:10:46.45463	2026-09-21 20:54:22.914468	2026-09-21 21:10:46.455616
5	Cuentas con montos discrepantes	Las cuentas calculan el monto de sus órdenes en un atributo. Si esto se calcula mal, el empleado va a pagar un precio que no es el correcto.	(\n    SELECT *\n    FROM (\n      SELECT accounts.*,\n             (SELECT SUM(orders.price - orders.discounted_price)\n              FROM orders\n              INNER JOIN order_accounts ON order_accounts.order_id = orders.id\n              WHERE order_accounts.account_id = accounts.id\n                AND orders.status = 1) AS real_amount\n      FROM accounts\n      WHERE accounts.owner_type = 'Consumer'\n    ) t\n    WHERE t.amount IS DISTINCT FROM t.real_amount\n) UNION (\n    SELECT *\n    FROM (\n      SELECT accounts.*,\n             (SELECT SUM(orders.discounted_price)\n              FROM orders\n              INNER JOIN order_accounts ON order_accounts.order_id = orders.id\n              WHERE order_accounts.account_id = accounts.id\n                AND orders.status = 1) AS real_amount\n      FROM accounts\n      WHERE accounts.owner_type = 'Company'\n    ) t\n    WHERE t.amount IS DISTINCT FROM t.real_amount\n)	{"query_type":"sql","database":"Default","visualization":"table","visualization_options":{},"variables":[]}	\N	\N	\N	2026-09-21 21:28:21.001728	2026-09-21 21:37:34.223424
4	Órdenes sin cuenta asignada	Estas órdenes no van a ser cobradas. Su existencia representa un error a revisar en la aplicación	(\n    SELECT 'Consumer' AS account_missing, *\n    FROM orders\n    WHERE orders.price - orders.discounted_price > 0\n          AND orders.id NOT IN (SELECT DISTINCT order_accounts.order_id\n                                FROM order_accounts INNER JOIN accounts ON accounts.id = order_accounts.account_id\n                                WHERE accounts.owner_type = 'Consumer')\n) UNION (\n    SELECT 'Company' AS account_missing, *\n    FROM orders\n    WHERE orders.discounted_price > 0\n          AND orders.id NOT IN (SELECT DISTINCT order_accounts.order_id\n                                FROM order_accounts INNER JOIN accounts ON accounts.id = order_accounts.account_id\n                                WHERE accounts.owner_type = 'Company')\n)	{"query_type":"sql","database":"Default","visualization":"table","visualization_options":{},"variables":[]}	\N	\N	\N	2026-09-21 21:15:56.628782	2026-09-22 00:36:20.645536
3	Proveedores con más pedidos	\N	SELECT providers.id AS provider_id, users.name AS provider_name, SUM(orders.amount) AS total_orders\nFROM orders INNER JOIN schedules ON orders.schedule_id = schedules.id\n            INNER JOIN menus ON schedules.menu_id = menus.id\n            INNER JOIN providers ON menus.provider_id = providers.id\n            INNER JOIN users ON providers.user_id = users.id\nGROUP BY providers.id, users.id\nORDER BY total_orders DESC;	{"query_type":"sql","database":"Default","visualization":"table","visualization_options":{},"variables":[]}	\N	\N	\N	2026-09-21 21:13:20.619533	2026-09-22 00:36:42.037766
2	Platos más pedidos	Muestra los platos más pedidos con su proveedor, así como la cantidad que se pidieron históricamente.	SELECT menus.provider_id, users.name AS provider_name, menus.id AS menu_id, menus.name, SUM(orders.amount) AS total_orders\nFROM orders INNER JOIN schedules ON orders.schedule_id = schedules.id\n            INNER JOIN menus ON schedules.menu_id = menus.id\n            INNER JOIN providers ON menus.provider_id = providers.id\n            INNER JOIN users ON providers.user_id = users.id\nGROUP BY users.id, menus.id\nORDER BY total_orders DESC;	{"query_type":"sql","database":"Default","visualization":"table","visualization_options":{},"variables":[]}	\N	\N	\N	2026-09-21 21:06:53.058304	2026-09-22 00:36:57.422212
6	Sesiones con roles discrepantes	Un usuario no debería efectuar un rol en una sesión, si no lo posee.	SELECT *\nFROM sessions\nWHERE (sessions.role = 0 AND NOT EXISTS (SELECT * FROM providers WHERE providers.user_id = sessions.user_id))\n      OR (sessions.role = 1 AND NOT EXISTS (SELECT * FROM consumers WHERE consumers.user_id = sessions.user_id))\n      OR (sessions.role = 2 AND NOT EXISTS (SELECT * FROM admins WHERE admins.user_id = sessions.user_id))	{"query_type":"sql","database":"Default","visualization":"table","visualization_options":{},"variables":[]}	\N	\N	\N	2026-09-22 00:44:28.042337	2026-09-22 00:44:28.042337
\.


--
-- Data for Name: motor_reminders; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.motor_reminders (id, author_id, author_type, recipient_id, recipient_type, record_id, record_type, scheduled_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: motor_resources; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.motor_resources (id, name, preferences, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: motor_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.motor_roles (id, name, rules, created_at, updated_at) FROM stdin;
1	superadmin	[{"actions":["manage"],"subjects":["all"],"attributes":[],"conditions":[]}]	2026-09-21 20:54:46.984766	2026-09-21 20:54:46.984766
\.


--
-- Data for Name: motor_taggable_tags; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.motor_taggable_tags (id, tag_id, taggable_id, taggable_type) FROM stdin;
1	1	5	Motor::Query
2	1	4	Motor::Query
3	2	3	Motor::Query
4	2	2	Motor::Query
5	1	6	Motor::Query
\.


--
-- Data for Name: motor_tags; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.motor_tags (id, name, created_at, updated_at) FROM stdin;
1	Consistencia	2026-09-21 21:37:34.21789	2026-09-21 21:37:34.21789
2	Estadísticas	2026-09-22 00:36:42.032988	2026-09-22 00:36:42.032988
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schema_migrations (version) FROM stdin;
20210803152358
20210803153805
20210805074314
20210805074328
20210805081429
20211124011025
20211228142855
20220112095600
20221127142113
\.


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.active_storage_attachments_id_seq', 1, false);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.active_storage_blobs_id_seq', 1, false);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.active_storage_variant_records_id_seq', 1, false);


--
-- Name: motor_admin_user_roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.motor_admin_user_roles_id_seq', 1, true);


--
-- Name: motor_admin_users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.motor_admin_users_id_seq', 1, true);


--
-- Name: motor_alert_locks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.motor_alert_locks_id_seq', 1, false);


--
-- Name: motor_alerts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.motor_alerts_id_seq', 1, false);


--
-- Name: motor_api_configs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.motor_api_configs_id_seq', 2, true);


--
-- Name: motor_audits_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.motor_audits_id_seq', 16, true);


--
-- Name: motor_configs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.motor_configs_id_seq', 1, true);


--
-- Name: motor_dashboards_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.motor_dashboards_id_seq', 1, true);


--
-- Name: motor_encrypted_configs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.motor_encrypted_configs_id_seq', 1, true);


--
-- Name: motor_forms_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.motor_forms_id_seq', 1, true);


--
-- Name: motor_note_tag_tags_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.motor_note_tag_tags_id_seq', 1, false);


--
-- Name: motor_note_tags_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.motor_note_tags_id_seq', 1, false);


--
-- Name: motor_notes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.motor_notes_id_seq', 1, false);


--
-- Name: motor_notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.motor_notifications_id_seq', 1, false);


--
-- Name: motor_queries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.motor_queries_id_seq', 6, true);


--
-- Name: motor_reminders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.motor_reminders_id_seq', 1, false);


--
-- Name: motor_resources_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.motor_resources_id_seq', 1, false);


--
-- Name: motor_roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.motor_roles_id_seq', 1, true);


--
-- Name: motor_taggable_tags_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.motor_taggable_tags_id_seq', 5, true);


--
-- Name: motor_tags_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.motor_tags_id_seq', 2, true);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: motor_admin_user_roles motor_admin_user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_admin_user_roles
    ADD CONSTRAINT motor_admin_user_roles_pkey PRIMARY KEY (id);


--
-- Name: motor_admin_users motor_admin_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_admin_users
    ADD CONSTRAINT motor_admin_users_pkey PRIMARY KEY (id);


--
-- Name: motor_alert_locks motor_alert_locks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_alert_locks
    ADD CONSTRAINT motor_alert_locks_pkey PRIMARY KEY (id);


--
-- Name: motor_alerts motor_alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_alerts
    ADD CONSTRAINT motor_alerts_pkey PRIMARY KEY (id);


--
-- Name: motor_api_configs motor_api_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_api_configs
    ADD CONSTRAINT motor_api_configs_pkey PRIMARY KEY (id);


--
-- Name: motor_audits motor_audits_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_audits
    ADD CONSTRAINT motor_audits_pkey PRIMARY KEY (id);


--
-- Name: motor_configs motor_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_configs
    ADD CONSTRAINT motor_configs_pkey PRIMARY KEY (id);


--
-- Name: motor_dashboards motor_dashboards_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_dashboards
    ADD CONSTRAINT motor_dashboards_pkey PRIMARY KEY (id);


--
-- Name: motor_encrypted_configs motor_encrypted_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_encrypted_configs
    ADD CONSTRAINT motor_encrypted_configs_pkey PRIMARY KEY (id);


--
-- Name: motor_forms motor_forms_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_forms
    ADD CONSTRAINT motor_forms_pkey PRIMARY KEY (id);


--
-- Name: motor_note_tag_tags motor_note_tag_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_note_tag_tags
    ADD CONSTRAINT motor_note_tag_tags_pkey PRIMARY KEY (id);


--
-- Name: motor_note_tags motor_note_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_note_tags
    ADD CONSTRAINT motor_note_tags_pkey PRIMARY KEY (id);


--
-- Name: motor_notes motor_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_notes
    ADD CONSTRAINT motor_notes_pkey PRIMARY KEY (id);


--
-- Name: motor_notifications motor_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_notifications
    ADD CONSTRAINT motor_notifications_pkey PRIMARY KEY (id);


--
-- Name: motor_queries motor_queries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_queries
    ADD CONSTRAINT motor_queries_pkey PRIMARY KEY (id);


--
-- Name: motor_reminders motor_reminders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_reminders
    ADD CONSTRAINT motor_reminders_pkey PRIMARY KEY (id);


--
-- Name: motor_resources motor_resources_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_resources
    ADD CONSTRAINT motor_resources_pkey PRIMARY KEY (id);


--
-- Name: motor_roles motor_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_roles
    ADD CONSTRAINT motor_roles_pkey PRIMARY KEY (id);


--
-- Name: motor_taggable_tags motor_taggable_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_taggable_tags
    ADD CONSTRAINT motor_taggable_tags_pkey PRIMARY KEY (id);


--
-- Name: motor_tags motor_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_tags
    ADD CONSTRAINT motor_tags_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_motor_admin_user_roles_on_admin_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_motor_admin_user_roles_on_admin_user_id ON public.motor_admin_user_roles USING btree (admin_user_id);


--
-- Name: index_motor_admin_user_roles_on_role_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_motor_admin_user_roles_on_role_id ON public.motor_admin_user_roles USING btree (role_id);


--
-- Name: index_motor_admin_user_roles_on_role_id_and_admin_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_motor_admin_user_roles_on_role_id_and_admin_user_id ON public.motor_admin_user_roles USING btree (role_id, admin_user_id);


--
-- Name: index_motor_admin_users_on_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_motor_admin_users_on_email ON public.motor_admin_users USING btree (email);


--
-- Name: index_motor_admin_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_motor_admin_users_on_reset_password_token ON public.motor_admin_users USING btree (reset_password_token);


--
-- Name: index_motor_admin_users_on_unlock_token; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_motor_admin_users_on_unlock_token ON public.motor_admin_users USING btree (unlock_token);


--
-- Name: index_motor_alert_locks_on_alert_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_motor_alert_locks_on_alert_id ON public.motor_alert_locks USING btree (alert_id);


--
-- Name: index_motor_alert_locks_on_alert_id_and_lock_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_motor_alert_locks_on_alert_id_and_lock_timestamp ON public.motor_alert_locks USING btree (alert_id, lock_timestamp);


--
-- Name: index_motor_alerts_on_query_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_motor_alerts_on_query_id ON public.motor_alerts USING btree (query_id);


--
-- Name: index_motor_alerts_on_updated_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_motor_alerts_on_updated_at ON public.motor_alerts USING btree (updated_at);


--
-- Name: index_motor_audits_on_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_motor_audits_on_created_at ON public.motor_audits USING btree (created_at);


--
-- Name: index_motor_audits_on_request_uuid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_motor_audits_on_request_uuid ON public.motor_audits USING btree (request_uuid);


--
-- Name: index_motor_configs_on_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_motor_configs_on_key ON public.motor_configs USING btree (key);


--
-- Name: index_motor_configs_on_updated_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_motor_configs_on_updated_at ON public.motor_configs USING btree (updated_at);


--
-- Name: index_motor_dashboards_on_updated_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_motor_dashboards_on_updated_at ON public.motor_dashboards USING btree (updated_at);


--
-- Name: index_motor_encrypted_configs_on_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_motor_encrypted_configs_on_key ON public.motor_encrypted_configs USING btree (key);


--
-- Name: index_motor_encrypted_configs_on_updated_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_motor_encrypted_configs_on_updated_at ON public.motor_encrypted_configs USING btree (updated_at);


--
-- Name: index_motor_forms_on_updated_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_motor_forms_on_updated_at ON public.motor_forms USING btree (updated_at);


--
-- Name: index_motor_note_tag_tags_on_tag_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_motor_note_tag_tags_on_tag_id ON public.motor_note_tag_tags USING btree (tag_id);


--
-- Name: index_motor_queries_on_updated_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_motor_queries_on_updated_at ON public.motor_queries USING btree (updated_at);


--
-- Name: index_motor_reminders_on_scheduled_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_motor_reminders_on_scheduled_at ON public.motor_reminders USING btree (scheduled_at);


--
-- Name: index_motor_resources_on_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_motor_resources_on_name ON public.motor_resources USING btree (name);


--
-- Name: index_motor_resources_on_updated_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_motor_resources_on_updated_at ON public.motor_resources USING btree (updated_at);


--
-- Name: index_motor_roles_on_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_motor_roles_on_name ON public.motor_roles USING btree (name);


--
-- Name: index_motor_roles_on_updated_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_motor_roles_on_updated_at ON public.motor_roles USING btree (updated_at);


--
-- Name: index_motor_taggable_tags_on_tag_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_motor_taggable_tags_on_tag_id ON public.motor_taggable_tags USING btree (tag_id);


--
-- Name: motor_alerts_name_unique_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX motor_alerts_name_unique_index ON public.motor_alerts USING btree (name) WHERE (deleted_at IS NULL);


--
-- Name: motor_api_configs_name_unique_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX motor_api_configs_name_unique_index ON public.motor_api_configs USING btree (name) WHERE (deleted_at IS NULL);


--
-- Name: motor_auditable_associated_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX motor_auditable_associated_index ON public.motor_audits USING btree (associated_type, associated_id);


--
-- Name: motor_auditable_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX motor_auditable_index ON public.motor_audits USING btree (auditable_type, auditable_id, version);


--
-- Name: motor_auditable_user_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX motor_auditable_user_index ON public.motor_audits USING btree (user_id, user_type);


--
-- Name: motor_dashboards_title_unique_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX motor_dashboards_title_unique_index ON public.motor_dashboards USING btree (title) WHERE (deleted_at IS NULL);


--
-- Name: motor_forms_name_unique_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX motor_forms_name_unique_index ON public.motor_forms USING btree (name) WHERE (deleted_at IS NULL);


--
-- Name: motor_note_tags_name_unique_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX motor_note_tags_name_unique_index ON public.motor_note_tags USING btree (name);


--
-- Name: motor_note_tags_note_id_tag_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX motor_note_tags_note_id_tag_id_index ON public.motor_note_tag_tags USING btree (note_id, tag_id);


--
-- Name: motor_notes_author_id_author_type_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX motor_notes_author_id_author_type_index ON public.motor_notes USING btree (author_id, author_type);


--
-- Name: motor_notifications_recipient_id_recipient_type_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX motor_notifications_recipient_id_recipient_type_index ON public.motor_notifications USING btree (recipient_id, recipient_type);


--
-- Name: motor_notifications_record_id_record_type_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX motor_notifications_record_id_record_type_index ON public.motor_notifications USING btree (record_id, record_type);


--
-- Name: motor_polymorphic_association_tag_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX motor_polymorphic_association_tag_index ON public.motor_taggable_tags USING btree (taggable_id, taggable_type, tag_id);


--
-- Name: motor_queries_name_unique_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX motor_queries_name_unique_index ON public.motor_queries USING btree (name) WHERE (deleted_at IS NULL);


--
-- Name: motor_reminders_author_id_author_type_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX motor_reminders_author_id_author_type_index ON public.motor_reminders USING btree (author_id, author_type);


--
-- Name: motor_reminders_recipient_id_recipient_type_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX motor_reminders_recipient_id_recipient_type_index ON public.motor_reminders USING btree (recipient_id, recipient_type);


--
-- Name: motor_reminders_record_id_record_type_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX motor_reminders_record_id_record_type_index ON public.motor_reminders USING btree (record_id, record_type);


--
-- Name: motor_tags_name_unique_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX motor_tags_name_unique_index ON public.motor_tags USING btree (name);


--
-- Name: motor_admin_user_roles fk_rails_151496d9f5; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_admin_user_roles
    ADD CONSTRAINT fk_rails_151496d9f5 FOREIGN KEY (role_id) REFERENCES public.motor_roles(id);


--
-- Name: motor_alert_locks fk_rails_38d1b2960e; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_alert_locks
    ADD CONSTRAINT fk_rails_38d1b2960e FOREIGN KEY (alert_id) REFERENCES public.motor_alerts(id);


--
-- Name: motor_note_tag_tags fk_rails_5958bda098; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_note_tag_tags
    ADD CONSTRAINT fk_rails_5958bda098 FOREIGN KEY (note_id) REFERENCES public.motor_notes(id);


--
-- Name: motor_alerts fk_rails_8828951644; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_alerts
    ADD CONSTRAINT fk_rails_8828951644 FOREIGN KEY (query_id) REFERENCES public.motor_queries(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: motor_admin_user_roles fk_rails_9a18445822; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_admin_user_roles
    ADD CONSTRAINT fk_rails_9a18445822 FOREIGN KEY (admin_user_id) REFERENCES public.motor_admin_users(id);


--
-- Name: motor_taggable_tags fk_rails_ba9ebe2280; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_taggable_tags
    ADD CONSTRAINT fk_rails_ba9ebe2280 FOREIGN KEY (tag_id) REFERENCES public.motor_tags(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: motor_note_tag_tags fk_rails_f0bd88b67d; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motor_note_tag_tags
    ADD CONSTRAINT fk_rails_f0bd88b67d FOREIGN KEY (tag_id) REFERENCES public.motor_note_tags(id);


--
-- PostgreSQL database dump complete
--

\unrestrict 2BqrV7fixlF37GUwV79mIgpmN2MBZd7U9HFGroTGTHVUQZuibsyqrmbKXTSnbll

