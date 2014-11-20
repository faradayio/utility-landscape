# Process for generating utility service territories from remote sources:
# - Census TIGER data
# - EIA tabular data

# Prerecs for this (among others):
# postgresql 9.whatevs
# psql command line utils
# ogr2ogr
# csvkit (omigod i love this thing)

# Fire this up from the root of the repository
rm -r geojson_territories
rm -r intake
mkdir geojson_territories
mkdir intake
cd intake

# Create the DB and get it ready for spatial awesomness
dropdb makeutils
createdb makeutils
psql makeutils -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'
psql makeutils -c 'CREATE EXTENSION IF NOT EXISTS postgis'
psql makeutils -c 'CREATE EXTENSION IF NOT EXISTS postgis_topology'
psql makeutils -c 'CREATE EXTENSION fuzzystrmatch'
psql makeutils -c 'CREATE EXTENSION postgis_tiger_geocoder'

# Add a starter table for utility data
psql makeutils -c 'DROP TABLE IF EXISTS utilities'
psql makeutils -c 'CREATE TABLE utilities (year text, id text, uname text, state text, county text )'

# - Import census "counties"
echo 'getting counties'
wget -c http://www2.census.gov/geo/tiger/TIGER2010DP1/County_2010Census_DP1.zip
mkdir census_county
mv County_2010Census_DP1.zip census_county/
cd census_county
unzip County_2010Census_DP1.zip
echo 'importing counties'
ogr2ogr -t_srs "EPSG:4326" -f "PostgreSQL" "PG:dbname=makeutils host=127.0.0.1 port=5432 user=vagrant" County_2010Census_DP1.shp -nln census_county -nlt PROMOTE_TO_MULTI -lco PRECISION=NO
echo 'done importing'
cd ..

# - Import census "states"
echo 'getting states'
wget -c http://www2.census.gov/geo/tiger/TIGER2010DP1/State_2010Census_DP1.zip
mkdir census_state
mv State_2010Census_DP1.zip census_state/
cd census_state
unzip State_2010Census_DP1.zip
echo 'importing states'
ogr2ogr -t_srs "EPSG:4326" -f "PostgreSQL" "PG:dbname=makeutils host=127.0.0.1 port=5432 user=vagrant" State_2010Census_DP1.shp -nln census_state -nlt PROMOTE_TO_MULTI -lco PRECISION=NO
echo 'done importing'
cd ..

# Insert counties, states
echo 'building usable counties and states'
psql makeutils -f ../sql/census_intake.sql

# Import utility list from EIA, process it, insert it into places
echo 'getting the utility list'
wget -c http://www.eia.gov/electricity/data/eia861/zip/f8612012.zip
mkdir utilities
mv f8612012.zip utilities/
cd utilities
unzip f8612012.zip
echo 'converting xls to csv (open data formats, people, say it with me)'
in2csv service_territory_2012.xls > service_territory_2012.csv
echo 'stripping weird delimiter rows'
csvclean service_territory_2012.csv
echo 'importing utilities to places'
psql makeutils -c "\copy utilities FROM 'service_territory_2012_out.csv' csv header"
echo 'matching to county membership'
psql makeutils -f ../../sql/utilities_intake.sql
cd ..

# Clean up intake files
cd ..
rm -r intake

# Split into GeoJSON
ogr2ogr -f "GeoJSON" geojson_territories PG:"host=127.0.0.1 port=5432 dbname=makeutils" utility_territories

# All done!