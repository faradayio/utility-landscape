-- Build the Database and shell table

-- Extensions:
-- Enable Trigram matching
CREATE EXTENSION pg_trgm;
-- Enable PostGIS (includes raster)
CREATE EXTENSION postgis;
-- Enable Topology
CREATE EXTENSION postgis_topology;
-- fuzzy matching for backup
CREATE EXTENSION fuzzystrmatch;
-- uuid generator
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Build the utility_territories table
--
-- Name: utility_territories; Type: TABLE; Schema: public; Owner: -; Tablespace:
--
DROP TABLE IF EXISTS utility_territories;
CREATE TABLE utility_territories (
    id text,
    name text,
    type text,
    state text,
    the_geom geometry(Geometry,4326),
    the_geom_webmercator geometry(Geometry,3857)
);

--
-- Name: idx_id_utility_territories; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX idx_id_utility_territories ON utility_territories USING btree (id);

--
-- Name: idx_name_utility_territories; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX idx_name_utility_territories ON utility_territories USING btree (name);

--
-- Name: idx_the_geom; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX idx_the_geom ON utility_territories USING gist (the_geom);

--
-- Name: idx_the_geom_webmercator_utility_territories; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX idx_the_geom_webmercator_utility_territories ON utility_territories USING gist (the_geom_webmercator);

--
-- Name: idx_type_utility_territories; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX idx_type_utility_territories ON utility_territories USING btree (type);
