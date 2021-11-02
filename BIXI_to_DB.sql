CREATE DATABASE bixi2helo;
CREATE USER bixi with password 'helo';
CREATE EXTENSION postgis;


CREATE TABLE trips (
	start_date timestamp without time zone,
	station_start int,
	end_date timestamp without time zone,
	station_end int,
	duration int,
	is_member smallint
);
GRANT ALL ON trips to bixi;

\copy trips from '/home/hermes/BIXI/OD_2021_06.csv' with csv header;
\copy trips from '/home/hermes/BIXI/OD_2021_07.csv' with csv header;
\copy trips from '/home/hermes/BIXI/OD_2021_08.csv' with csv header;
\copy trips from '/home/hermes/BIXI/OD_2021_09.csv' with csv header;

ALTER TABLE trips add column uid serial;


CREATE TABLE stations (
	id int,
	name varchar(1500),
	lat float8,
	lng float8
);
GRANT ALL ON stations to bixi;

\copy stations from '/home/hermes/BIXI/stations_06.csv' with csv header;
\copy stations from '/home/hermes/BIXI/stations_07.csv' with csv header;
\copy stations from '/home/hermes/BIXI/stations_08.csv' with csv header;
\copy stations from '/home/hermes/BIXI/stations_09.csv' with csv header;

CREATE TABLE tmp AS select distinct id, name, lat, lng from stations;

-- Sanity check due to change in station names and ids
-- select id, count(*) as cnt from tmp group by id order by cnt desc;
-- In this example one station changed names but kept everything else the same... annoying.

DROP TABLE stations;
ALTER TABLE tmp RENAME TO stations;
ALTER TABLE stations ADD COLUMN geom geometry;
UPDATE stations SET geom = st_setsrid(st_makepoint(lng, lat), 4326);

CREATE INDEX stations_idx on stations(id);
CREATE INDEX stations_nidx on stations(name);


CREATE TABLE helo (
	plate varchar(10),
	station_start varchar(1500),
	station_end varchar(1500),
	charge_start int,
	charge_end int,
	start_time bigint,
	duration int,
	dist float8
);
GRANT ALL ON helo TO bixi;

-- Run HELO_to_TRIPS.php
\copy helo from '/home/hermes/BIXI/bixi_trips.csv' with csv;
ALTER TABLE helo ADD COLUMN start_date TIMESTAMP WITHOUT TIME ZONE;
UPDATE helo SET start_date = to_timestamp(start_time)::TIMESTAMP;
ALTER TABLE helo ADD COLUMN uid SERIAL;


-- A little redundent but makes the analysis queries easier.
ALTER TABLE trips ADD COLUMN start_name varchar(1500), ADD COLUMN end_name varchar(1500);
UPDATE trips SET start_name = a.name FROM stations a where a.id = trips.station_start;
UPDATE trips SET end_name = a.name FROM stations a where a.id = trips.station_end;