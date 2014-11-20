-- Extract the useful stuff from census inputs

DROP TABLE IF EXISTS state1;
CREATE TABLE state1 AS (
	SELECT
		geoid10 id,
		name10 AS name,
		dp0010001 population,
		dp0130001 households,
		stusps10 state,
		wkb_geometry the_geom
	FROM census_state
);

DROP TABLE IF EXISTS county1;
CREATE TABLE county1 AS (
	SELECT
		geoid10 id,
		namelsad10 AS name,
		dp0010001 population,
		dp0130001 households,
		wkb_geometry the_geom
	FROM census_county
);

