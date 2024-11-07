--
-- PostgreSQL database dump
--

-- Dumped from database version 14.9 (Debian 14.9-1.pgdg110+1)
-- Dumped by pg_dump version 17.0

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
-- Name: graphile_migrate; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA graphile_migrate;


--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: tx; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tx (
    chain_num smallint NOT NULL,
    block_height bigint NOT NULL,
    tx_idx smallint NOT NULL,
    hash bytea NOT NULL,
    data jsonb NOT NULL
);


--
-- Name: all_ecocredit_txes(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.all_ecocredit_txes() RETURNS SETOF public.tx
    LANGUAGE sql STABLE
    AS $$
    select tx.*
    from tx
    inner join msg using (chain_num, block_height, tx_idx)
    where
      tx.data ->'tx_response'->'code' = '0' and
      msg.data->>'@type' like '/regen.ecocredit.%'
    order by tx.block_height desc
$$;


--
-- Name: current; Type: TABLE; Schema: graphile_migrate; Owner: -
--

CREATE TABLE graphile_migrate.current (
    filename text DEFAULT 'current.sql'::text NOT NULL,
    content text NOT NULL,
    date timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: migrations; Type: TABLE; Schema: graphile_migrate; Owner: -
--

CREATE TABLE graphile_migrate.migrations (
    hash text NOT NULL,
    previous_hash text,
    filename text NOT NULL,
    date timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: block; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.block (
    chain_num smallint NOT NULL,
    height bigint NOT NULL,
    data jsonb NOT NULL,
    "time" timestamp with time zone NOT NULL
);


--
-- Name: chain; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chain (
    num smallint NOT NULL,
    chain_id text NOT NULL
);


--
-- Name: chain_num_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chain_num_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chain_num_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chain_num_seq OWNED BY public.chain.num;


--
-- Name: class_issuers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.class_issuers (
    type text NOT NULL,
    block_height bigint NOT NULL,
    tx_idx smallint NOT NULL,
    msg_idx smallint NOT NULL,
    chain_num smallint NOT NULL,
    "timestamp" timestamp with time zone,
    tx_hash text NOT NULL,
    class_id text NOT NULL,
    issuer text NOT NULL,
    latest boolean DEFAULT true NOT NULL
);


--
-- Name: msg_event_attr; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.msg_event_attr (
    chain_num smallint NOT NULL,
    block_height bigint NOT NULL,
    tx_idx smallint NOT NULL,
    msg_idx smallint NOT NULL,
    type text NOT NULL,
    key text NOT NULL,
    value text NOT NULL,
    value_hash bytea NOT NULL
);


--
-- Name: event_retire_v1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.event_retire_v1 AS
 SELECT msg_event_attr.chain_num,
    msg_event_attr.block_height,
    msg_event_attr.tx_idx,
    msg_event_attr.msg_idx,
    max(
        CASE
            WHEN (msg_event_attr.key = 'owner'::text) THEN msg_event_attr.value
            ELSE NULL::text
        END) AS owner,
    max(
        CASE
            WHEN (msg_event_attr.key = 'batch_denom'::text) THEN msg_event_attr.value
            ELSE NULL::text
        END) AS batch_denom,
    max(
        CASE
            WHEN (msg_event_attr.key = 'amount'::text) THEN msg_event_attr.value
            ELSE NULL::text
        END) AS amount,
    max(
        CASE
            WHEN (msg_event_attr.key = 'jurisdiction'::text) THEN msg_event_attr.value
            ELSE NULL::text
        END) AS jurisdiction,
    max(
        CASE
            WHEN (msg_event_attr.key = 'reason'::text) THEN msg_event_attr.value
            ELSE NULL::text
        END) AS reason,
    (sum(
        CASE
            WHEN (msg_event_attr.key = 'amount'::text) THEN 1
            ELSE 0
        END) > 1) AS has_duplicates
   FROM public.msg_event_attr
  WHERE (msg_event_attr.type ~~ 'regen.ecocredit.v1.EventRetire'::text)
  GROUP BY msg_event_attr.chain_num, msg_event_attr.block_height, msg_event_attr.tx_idx, msg_event_attr.msg_idx;


--
-- Name: event_retire_v1alpha1; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.event_retire_v1alpha1 AS
 SELECT msg_event_attr.chain_num,
    msg_event_attr.block_height,
    msg_event_attr.tx_idx,
    msg_event_attr.msg_idx,
    max(
        CASE
            WHEN (msg_event_attr.key = 'retirer'::text) THEN msg_event_attr.value
            ELSE NULL::text
        END) AS retirer,
    max(
        CASE
            WHEN (msg_event_attr.key = 'batch_denom'::text) THEN msg_event_attr.value
            ELSE NULL::text
        END) AS batch_denom,
    max(
        CASE
            WHEN (msg_event_attr.key = 'amount'::text) THEN msg_event_attr.value
            ELSE NULL::text
        END) AS amount,
    max(
        CASE
            WHEN (msg_event_attr.key = 'location'::text) THEN msg_event_attr.value
            ELSE NULL::text
        END) AS location,
    (sum(
        CASE
            WHEN (msg_event_attr.key = 'amount'::text) THEN 1
            ELSE 0
        END) > 1) AS has_duplicates
   FROM public.msg_event_attr
  WHERE (msg_event_attr.type ~~ 'regen.ecocredit.v1alpha1.EventRetire'::text)
  GROUP BY msg_event_attr.chain_num, msg_event_attr.block_height, msg_event_attr.tx_idx, msg_event_attr.msg_idx;


--
-- Name: event_retire; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.event_retire AS
 SELECT event_retire_v1.chain_num,
    event_retire_v1.block_height,
    event_retire_v1.tx_idx,
    event_retire_v1.msg_idx,
    event_retire_v1.owner,
    event_retire_v1.batch_denom,
    event_retire_v1.amount,
    event_retire_v1.jurisdiction,
    event_retire_v1.reason,
    event_retire_v1.has_duplicates
   FROM public.event_retire_v1
UNION
 SELECT event_retire_v1alpha1.chain_num,
    event_retire_v1alpha1.block_height,
    event_retire_v1alpha1.tx_idx,
    event_retire_v1alpha1.msg_idx,
    event_retire_v1alpha1.retirer AS owner,
    event_retire_v1alpha1.batch_denom,
    event_retire_v1alpha1.amount,
    event_retire_v1alpha1.location AS jurisdiction,
    ''::text AS reason,
    event_retire_v1alpha1.has_duplicates
   FROM public.event_retire_v1alpha1;


--
-- Name: flyway_schema_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flyway_schema_history (
    installed_rank integer NOT NULL,
    version character varying(50),
    description character varying(200) NOT NULL,
    type character varying(20) NOT NULL,
    script character varying(1000) NOT NULL,
    checksum integer,
    installed_by character varying(100) NOT NULL,
    installed_on timestamp without time zone DEFAULT now() NOT NULL,
    execution_time integer NOT NULL,
    success boolean NOT NULL
);


--
-- Name: msg; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.msg (
    chain_num smallint NOT NULL,
    block_height bigint NOT NULL,
    tx_idx smallint NOT NULL,
    msg_idx smallint NOT NULL,
    data jsonb NOT NULL
);


--
-- Name: msg_event; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.msg_event (
    chain_num smallint NOT NULL,
    block_height bigint NOT NULL,
    tx_idx smallint NOT NULL,
    msg_idx smallint NOT NULL,
    type text NOT NULL
);


--
-- Name: orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orders (
    "timestamp" timestamp with time zone,
    type text NOT NULL,
    credits_amount text NOT NULL,
    project_id text NOT NULL,
    buyer_address text NOT NULL,
    total_price text NOT NULL,
    ask_denom text NOT NULL,
    retired_credits boolean NOT NULL,
    retirement_reason text,
    retirement_jurisdiction text,
    block_height bigint NOT NULL,
    chain_num smallint NOT NULL,
    tx_idx smallint NOT NULL,
    msg_idx smallint NOT NULL,
    tx_hash text NOT NULL
);


--
-- Name: proposals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.proposals (
    type text NOT NULL,
    block_height bigint NOT NULL,
    tx_idx smallint NOT NULL,
    msg_idx smallint NOT NULL,
    chain_num smallint NOT NULL,
    "timestamp" timestamp with time zone,
    tx_hash text NOT NULL,
    proposal_id bigint NOT NULL,
    status text NOT NULL,
    group_policy_address text NOT NULL,
    metadata text NOT NULL,
    proposers text[] NOT NULL,
    submit_time timestamp with time zone,
    group_version bigint NOT NULL,
    group_policy_version bigint NOT NULL,
    final_tally_result jsonb NOT NULL,
    voting_period_end timestamp with time zone NOT NULL,
    executor_result text NOT NULL,
    messages jsonb NOT NULL
);


--
-- Name: retirements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.retirements (
    type text NOT NULL,
    amount text NOT NULL,
    batch_denom text NOT NULL,
    jurisdiction text NOT NULL,
    owner text NOT NULL,
    reason text NOT NULL,
    "timestamp" timestamp with time zone,
    block_height bigint NOT NULL,
    chain_num smallint NOT NULL,
    tx_idx smallint NOT NULL,
    msg_idx smallint NOT NULL,
    tx_hash text NOT NULL,
    batch_denoms text[] DEFAULT ARRAY[]::text[] NOT NULL
);


--
-- Name: votes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.votes (
    type text NOT NULL,
    block_height bigint NOT NULL,
    tx_idx smallint NOT NULL,
    msg_idx smallint NOT NULL,
    chain_num smallint NOT NULL,
    "timestamp" timestamp with time zone,
    tx_hash text NOT NULL,
    proposal_id bigint NOT NULL,
    voter text NOT NULL,
    option text NOT NULL,
    metadata text NOT NULL,
    submit_time timestamp with time zone NOT NULL
);


--
-- Name: chain num; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chain ALTER COLUMN num SET DEFAULT nextval('public.chain_num_seq'::regclass);


--
-- Name: current current_pkey; Type: CONSTRAINT; Schema: graphile_migrate; Owner: -
--

ALTER TABLE ONLY graphile_migrate.current
    ADD CONSTRAINT current_pkey PRIMARY KEY (filename);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: graphile_migrate; Owner: -
--

ALTER TABLE ONLY graphile_migrate.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (hash);


--
-- Name: block block_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.block
    ADD CONSTRAINT block_pkey PRIMARY KEY (chain_num, height);


--
-- Name: chain chain_chain_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chain
    ADD CONSTRAINT chain_chain_id_key UNIQUE (chain_id);


--
-- Name: chain chain_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chain
    ADD CONSTRAINT chain_pkey PRIMARY KEY (num);


--
-- Name: class_issuers class_issuers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.class_issuers
    ADD CONSTRAINT class_issuers_pkey PRIMARY KEY (chain_num, block_height, tx_idx, msg_idx, class_id, issuer);


--
-- Name: flyway_schema_history flyway_schema_history_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flyway_schema_history
    ADD CONSTRAINT flyway_schema_history_pk PRIMARY KEY (installed_rank);


--
-- Name: msg_event_attr msg_event_attr_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.msg_event_attr
    ADD CONSTRAINT msg_event_attr_pkey PRIMARY KEY (chain_num, block_height, tx_idx, msg_idx, type, key, value_hash);


--
-- Name: msg_event msg_event_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.msg_event
    ADD CONSTRAINT msg_event_pkey PRIMARY KEY (chain_num, block_height, tx_idx, msg_idx, type);


--
-- Name: msg msg_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.msg
    ADD CONSTRAINT msg_pkey PRIMARY KEY (chain_num, block_height, tx_idx, msg_idx);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (chain_num, block_height, tx_idx, msg_idx, project_id, ask_denom);


--
-- Name: proposals proposals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposals
    ADD CONSTRAINT proposals_pkey PRIMARY KEY (chain_num, block_height, tx_idx, msg_idx);


--
-- Name: retirements retirements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.retirements
    ADD CONSTRAINT retirements_pkey PRIMARY KEY (chain_num, block_height, tx_idx, msg_idx);


--
-- Name: retirements retirements_tx_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.retirements
    ADD CONSTRAINT retirements_tx_hash_key UNIQUE (tx_hash);


--
-- Name: tx tx_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tx
    ADD CONSTRAINT tx_hash_key UNIQUE (hash);


--
-- Name: tx tx_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tx
    ADD CONSTRAINT tx_pkey PRIMARY KEY (chain_num, block_height, tx_idx);


--
-- Name: votes votes_chain_num_proposal_id_voter_ux; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.votes
    ADD CONSTRAINT votes_chain_num_proposal_id_voter_ux UNIQUE (chain_num, proposal_id, voter);


--
-- Name: votes votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.votes
    ADD CONSTRAINT votes_pkey PRIMARY KEY (chain_num, block_height, tx_idx, msg_idx);


--
-- Name: class_issuers_credit_class_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX class_issuers_credit_class_id_idx ON public.class_issuers USING btree (class_id);


--
-- Name: class_issuers_issuer_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX class_issuers_issuer_idx ON public.class_issuers USING btree (issuer);


--
-- Name: class_issuers_latest_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX class_issuers_latest_idx ON public.class_issuers USING btree (latest);


--
-- Name: flyway_schema_history_s_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX flyway_schema_history_s_idx ON public.flyway_schema_history USING btree (success);


--
-- Name: msg_data_type_gin_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX msg_data_type_gin_idx ON public.msg USING gin (((data ->> '@type'::text)) public.gin_trgm_ops);


--
-- Name: msg_event_attr_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX msg_event_attr_type_idx ON public.msg_event_attr USING btree (type);


--
-- Name: msg_event_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX msg_event_type_idx ON public.msg_event USING btree (type);


--
-- Name: msg_expr_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX msg_expr_idx ON public.msg USING gin (((data -> '@type'::text)));


--
-- Name: orders_buyer_address_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX orders_buyer_address_idx ON public.orders USING btree (buyer_address);


--
-- Name: proposals_group_policy_address_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX proposals_group_policy_address_idx ON public.proposals USING btree (group_policy_address);


--
-- Name: proposals_proposal_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX proposals_proposal_id_idx ON public.proposals USING btree (proposal_id);


--
-- Name: retirements_owner_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX retirements_owner_idx ON public.retirements USING btree (owner);


--
-- Name: tx_data_tx_response_code_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tx_data_tx_response_code_idx ON public.tx USING btree ((((data -> 'tx_response'::text) -> 'code'::text)));


--
-- Name: votes_proposal_id_chain_num_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX votes_proposal_id_chain_num_idx ON public.votes USING btree (proposal_id, chain_num);


--
-- Name: migrations migrations_previous_hash_fkey; Type: FK CONSTRAINT; Schema: graphile_migrate; Owner: -
--

ALTER TABLE ONLY graphile_migrate.migrations
    ADD CONSTRAINT migrations_previous_hash_fkey FOREIGN KEY (previous_hash) REFERENCES graphile_migrate.migrations(hash);


--
-- Name: block block_chain_num_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.block
    ADD CONSTRAINT block_chain_num_fkey FOREIGN KEY (chain_num) REFERENCES public.chain(num);


--
-- Name: class_issuers class_issuers_chain_num_block_height_tx_idx_msg_idx_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.class_issuers
    ADD CONSTRAINT class_issuers_chain_num_block_height_tx_idx_msg_idx_type_fkey FOREIGN KEY (chain_num, block_height, tx_idx, msg_idx, type) REFERENCES public.msg_event(chain_num, block_height, tx_idx, msg_idx, type);


--
-- Name: msg msg_chain_num_block_height_tx_idx_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.msg
    ADD CONSTRAINT msg_chain_num_block_height_tx_idx_fkey FOREIGN KEY (chain_num, block_height, tx_idx) REFERENCES public.tx(chain_num, block_height, tx_idx);


--
-- Name: msg_event_attr msg_event_attr_chain_num_block_height_tx_idx_msg_idx_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.msg_event_attr
    ADD CONSTRAINT msg_event_attr_chain_num_block_height_tx_idx_msg_idx_fkey FOREIGN KEY (chain_num, block_height, tx_idx, msg_idx) REFERENCES public.msg(chain_num, block_height, tx_idx, msg_idx);


--
-- Name: msg_event msg_event_chain_num_block_height_tx_idx_msg_idx_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.msg_event
    ADD CONSTRAINT msg_event_chain_num_block_height_tx_idx_msg_idx_fkey FOREIGN KEY (chain_num, block_height, tx_idx, msg_idx) REFERENCES public.msg(chain_num, block_height, tx_idx, msg_idx);


--
-- Name: proposals proposals_chain_num_block_height_tx_idx_msg_idx_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proposals
    ADD CONSTRAINT proposals_chain_num_block_height_tx_idx_msg_idx_type_fkey FOREIGN KEY (chain_num, block_height, tx_idx, msg_idx, type) REFERENCES public.msg_event(chain_num, block_height, tx_idx, msg_idx, type);


--
-- Name: retirements retirements_chain_num_block_height_tx_idx_msg_idx_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.retirements
    ADD CONSTRAINT retirements_chain_num_block_height_tx_idx_msg_idx_type_fkey FOREIGN KEY (chain_num, block_height, tx_idx, msg_idx, type) REFERENCES public.msg_event(chain_num, block_height, tx_idx, msg_idx, type);


--
-- Name: tx tx_chain_num_block_height_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tx
    ADD CONSTRAINT tx_chain_num_block_height_fkey FOREIGN KEY (chain_num, block_height) REFERENCES public.block(chain_num, height);


--
-- Name: votes votes_chain_num_block_height_tx_idx_msg_idx_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.votes
    ADD CONSTRAINT votes_chain_num_block_height_tx_idx_msg_idx_type_fkey FOREIGN KEY (chain_num, block_height, tx_idx, msg_idx, type) REFERENCES public.msg_event(chain_num, block_height, tx_idx, msg_idx, type);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA public FROM postgres;
REVOKE USAGE ON SCHEMA public FROM PUBLIC;


--
-- PostgreSQL database dump complete
--

