-- CREATE UTILITY SERVICE TERRITORY BOUNDARIES USING COUNTY-LEVEL SRVICE TERRITORIES
-- Needed tables:
	-- 1. utilities (imported from csv)
	-- 3. county1
	-- 4. state1

-------------------------------------------------------------------------------

ALTER TABLE county1
	ADD COLUMN state text,
	ADD COLUMN namejoin text,
	ADD COLUMN nameshort text;

UPDATE county1 c1
	SET state = s1.state
	FROM state1 s1
	WHERE left(c1.id,2) = s1.id;

UPDATE county1 c1                                                                                                     
	SET namejoin = c1.name || ', ' ||s1.state
	FROM state1 s1
	WHERE c1.state = s1.state
;

UPDATE county1
	SET nameshort = replace(name,' City and County','');

UPDATE county1
	SET nameshort = replace(nameshort,' County','');

UPDATE county1
	SET nameshort = replace(nameshort,' Borough','');

UPDATE county1
	SET nameshort = replace(nameshort,' Census Area','');

UPDATE county1
	SET nameshort = replace(nameshort,' Municipio','');

UPDATE county1
	SET nameshort = replace(nameshort,' Municipality','');

UPDATE county1
	SET nameshort = replace(nameshort,' Parish','');

-- Add the right-syntax county name to utilities
ALTER TABLE utilities
	ADD COLUMN namejoin text;

UPDATE utilities
	SET namejoin = county || ', ' || state;

-- Cleanup of utilities, rmeove header and PR:
DELETE FROM utilities
	WHERE namejoin = 'County, State';
DELETE FROM utilities
	WHERE state = 'PR';

-- Calculate the geometry of each county-utility based on join field

DROP TABLE IF EXISTS utility_staging;

CREATE TABLE utility_staging AS (
	SELECT
		u.id AS id,
		c.the_geom AS the_geom
	FROM
		utilities u,
		county1 c
	WHERE
		u.state = right(c.namejoin,2)
	AND
		similarity(
			regexp_replace(c.nameshort, '[^\w]', '', 'g'), 
			regexp_replace(u.county, '[^\w]', '', 'g')
		) > 0.7
);

-- Add the obvious city-counties of MD and VA:
INSERT INTO utility_staging (
		id,the_geom
	)
	SELECT
		u.id AS id,
		c.the_geom AS the_geom
	FROM
		utilities u,
		county1 c
	WHERE
		c.name ILIKE '%city%'
	AND
		u.county ILIKE '%city%'
	AND
		u.state = right(c.namejoin,2)
	AND
		similarity(
			c.namejoin, 
			u.namejoin
		) > 0.6
;

-------------------------------------------------------------------------------
 -- Exceptions: insert cases for squirrely VA city-counties and AK combined coastal zones

--City of Manassas - (VA)
INSERT INTO utility_staging (id,the_geom) SELECT '11560', the_geom FROM county1 WHERE id = '51685';
--City of Danville - (VA)
INSERT INTO utility_staging (id,the_geom) SELECT '4794', the_geom FROM county1 WHERE id = '51590';
--City of Martinsville - (VA)
INSERT INTO utility_staging (id,the_geom) SELECT '11770', the_geom FROM county1 WHERE id = '51690';
--Appalachian Power Co
INSERT INTO utility_staging (id,the_geom) SELECT '733', the_geom FROM county1 WHERE id = '51680';
--Appalachian Power Co
INSERT INTO utility_staging (id,the_geom) SELECT '733', the_geom FROM county1 WHERE id = '51640';
--Bristol Virginia Utilities
INSERT INTO utility_staging (id,the_geom) SELECT '2248', the_geom FROM county1 WHERE id = '51520';
--Appalachian Power Co
INSERT INTO utility_staging (id,the_geom) SELECT '733', the_geom FROM county1 WHERE id = '51720';
--City of Radford - (VA)
INSERT INTO utility_staging (id,the_geom) SELECT '15619', the_geom FROM county1 WHERE id = '51750';
--Public Service Co of NM
INSERT INTO utility_staging (id,the_geom) SELECT '15473', the_geom FROM county1 WHERE id = '35013';
--El Paso Electric Co
INSERT INTO utility_staging (id,the_geom) SELECT '5701', the_geom FROM county1 WHERE id = '35013';
--Columbus Electric Coop, Inc
INSERT INTO utility_staging (id,the_geom) SELECT '4071', the_geom FROM county1 WHERE id = '35013';
--Pelican Utility
INSERT INTO utility_staging (id,the_geom) SELECT '29297', ST_Union(the_geom) the_geom FROM county1 WHERE id = '02230'OR id = '02105';
--Alaska Power and Telephone Co
INSERT INTO utility_staging (id,the_geom) SELECT '219', ST_Union(the_geom) the_geom FROM county1 WHERE id = '02230'OR id = '02105';
--Copper Valley Elec Assn, Inc
INSERT INTO utility_staging (id,the_geom) SELECT '4329', ST_Union(the_geom) the_geom FROM county1 WHERE id = '02230'OR id = '02105';
--Gustavus Electric Inc
INSERT INTO utility_staging (id,the_geom) SELECT '7822', ST_Union(the_geom) the_geom FROM county1 WHERE id = '02230'OR id = '02105';
--City of Tenakee Springs - (AK)
INSERT INTO utility_staging (id,the_geom) SELECT '18541', ST_Union(the_geom) the_geom FROM county1 WHERE id = '02230'OR id = '02105';
--Inside Passage Elec Coop, Inc
INSERT INTO utility_staging (id,the_geom) SELECT '18963', ST_Union(the_geom) the_geom FROM county1 WHERE id = '02230'OR id = '02105';
--City of Chignik - (AK)
INSERT INTO utility_staging (id,the_geom) SELECT '3421', ST_Union(the_geom) the_geom FROM county1 WHERE id = '02195'OR id = '02275';
--City of Petersburg - (AK)
INSERT INTO utility_staging (id,the_geom) SELECT '14856', ST_Union(the_geom) the_geom FROM county1 WHERE id = '02195'OR id = '02275';
--Inside Passage Elec Coop, Inc
INSERT INTO utility_staging (id,the_geom) SELECT '18963', ST_Union(the_geom) the_geom FROM county1 WHERE id = '02195'OR id = '02275';
--City of Wrangell - (AK)
INSERT INTO utility_staging (id,the_geom) SELECT '21015', ST_Union(the_geom) the_geom FROM county1 WHERE id = '02195'OR id = '02275';
--Alaska Power and Telephone Co
INSERT INTO utility_staging (id,the_geom) SELECT '219', ST_Union(the_geom) the_geom FROM county1 WHERE id = '02130'OR id = '02198';
--Metlakatla Power & Light
INSERT INTO utility_staging (id,the_geom) SELECT '12385', ST_Union(the_geom) the_geom FROM county1 WHERE id = '02130'OR id = '02198';

-------------------------------------------------------------------------------

-- Time to dissolve by utility name! Woot!
DROP TABLE IF EXISTS utility_territories;
CREATE TABLE utility_territories AS (
	SELECT
		id,
		ST_Union(the_geom) the_geom
	FROM 
		utility_staging
	GROUP BY
		id
);

-- Enrich the schema
ALTER TABLE utility_territories
	ADD COLUMN name text,
	ADD COLUMN type text,
	ADD COLUMN state character varying(2);

UPDATE utility_territories u1
	SET name = u2.uname,
	    state = u2.state,
	    type = 'electric utility'
	FROM 
		utilities u2
	WHERE 
		u1.id = u2.id;

-- Calculate Indices:

-- Name: idx_id_utility_territories; Type: INDEX; Schema: public; Owner: -; Tablespace:
CREATE INDEX idx_id_utility_territories ON utility_territories USING btree (id);
-- Name: idx_name_utility_territories; Type: INDEX; Schema: public; Owner: -; Tablespace:
CREATE INDEX idx_name_utility_territories ON utility_territories USING btree (name);
-- Name: idx_the_geom; Type: INDEX; Schema: public; Owner: -; Tablespace:
CREATE INDEX idx_the_geom ON utility_territories USING gist (the_geom);
-- Name: idx_type_utility_territories; Type: INDEX; Schema: public; Owner: -; Tablespace:
CREATE INDEX idx_type_utility_territories ON utility_territories USING btree (type);

-- TODO: Add state-provided shapefiles with greater specificity where available
