--
-- PostgreSQL database dump
--

DROP DATABASE IF EXISTS pewaa;
CREATE DATABASE pewaa;

\c pewaa;

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: oauth_tokens; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE oauth_tokens (
    id uuid DEFAULT uuid_generate_v4(),
    access_token text NOT NULL,
    access_token_expires_on timestamp without time zone NOT NULL,
    client_id text NOT NULL,
    refresh_token text NOT NULL,
    refresh_token_expires_on timestamp without time zone NOT NULL,
    user_id uuid NOT NULL,
    created_on timestamp DEFAULT current_timestamp
);

--
-- Name: oauth_clients; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE oauth_clients (
    client_id text NOT NULL,
    client_secret text NOT NULL,
    redirect_uri text NOT NULL,
    grants text[] NOT NULL,
    user_id uuid NOT NULL,
    created_on timestamp DEFAULT current_timestamp
);

--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE users (
    id uuid DEFAULT uuid_generate_v4(),
    username varchar(100) NOT NULL UNIQUE,
    hash varchar NOT NULL,
    email varchar(100) NOT NULL UNIQUE,
    name varchar(200) NOT NULL,
    description text NULL,
    avatar varchar NULL,
    created_on timestamp DEFAULT current_timestamp,
    updated_on timestamp
);

--
-- Name: wishlists; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE wishlists (
    id uuid DEFAULT uuid_generate_v4(),
    name varchar(200) NOT NULL,
    description text NULL,
    avatar varchar NULL,
    created_on timestamp DEFAULT current_timestamp,
    updated_on timestamp
);

--
-- Name: wishlist_items; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE wishlist_items (
    id uuid DEFAULT uuid_generate_v4(),
    name varchar(200) NOT NULL,
    code varchar(200) NULL UNIQUE,
    price numeric NOT NULL CHECK (price > 0),
    wishlist_id uuid NOT NULL,
    description text NULL,
    avatar varchar NULL,
    created_on timestamp DEFAULT current_timestamp,
    updated_on timestamp
);

--
-- Name: wishlist_item_contributors; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE wishlist_contributors (
    id uuid DEFAULT uuid_generate_v4(),
    user_id uuid NOT NULL,
    wishlist_id uuid NOT NULL,
    permissions varchar(20) NOT NULL,
    avatar varchar NULL,
    created_on timestamp DEFAULT current_timestamp,
    updated_on timestamp
);

--
-- Name: payments; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE payments (
    id uuid DEFAULT uuid_generate_v4(),
    amount numeric NOT NULL CHECK (amount > 0),
    wishlist_item_id uuid NOT NULL,
    reference text NOT NULL,
    description text NOT NULL,
    status varchar(20) NOT NULL,
    user_id uuid NOT NULL,
    created_on timestamp DEFAULT current_timestamp,
    updated_on timestamp
);

--
-- Name: oauth_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY oauth_tokens
    ADD CONSTRAINT oauth_tokens_pkey PRIMARY KEY (id);

--
-- Name: oauth_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY oauth_clients
    ADD CONSTRAINT oauth_clients_pkey PRIMARY KEY (client_id, client_secret);

--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);

--
-- Name: wishlists_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY wishlists
    ADD CONSTRAINT wishlists_pkey PRIMARY KEY (id);

--
-- Name: wishlist_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY wishlist_items
    ADD CONSTRAINT wishlist_items_pkey PRIMARY KEY (id);

--
-- Name: wishlist_items_fkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY wishlist_items
    ADD CONSTRAINT wishlist_items_fkey FOREIGN KEY (wishlist_id) REFERENCES wishlists(id);


--
-- Name: wishlist_item_contributors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY wishlist_contributors
    ADD CONSTRAINT wishlist_contributors_pkey PRIMARY KEY (id);

--
-- Name: wishlist_contributors_fkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY wishlist_contributors
    ADD CONSTRAINT wishlist_contributors_fkey FOREIGN KEY (wishlist_id) REFERENCES wishlists(id);

--
-- Name: wishlist_contributors_user_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY wishlist_contributors
    ADD CONSTRAINT wishlist_contributors_user_fkey FOREIGN KEY (user_id) REFERENCES users(id);

--
-- Name: payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);

--
-- Name: payments_wishlist_items_fkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY payments
    ADD CONSTRAINT payments_wishlist_items_fkey FOREIGN KEY (wishlist_item_id) REFERENCES wishlist_items(id);

--
-- Name: wishlist_items_user_fkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY payments
    ADD CONSTRAINT payments_user_fkey FOREIGN KEY (user_id) REFERENCES users(id);

--
-- Name: oauth_clients_user_fkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY oauth_clients
    ADD CONSTRAINT oauth_clients_user_fkey FOREIGN KEY (user_id) REFERENCES users(id);

--
-- Name: users_username_password; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX users_username_password ON users USING btree (username, hash);

--
-- PostgreSQL database dump complete
--

