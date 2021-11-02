-- How many helo trips per day?
-- Make sure they are roughly the same each day, or maybe we are missing data?
select extract(doy from start_date) as doy, count(*) as cnt from helo group by doy order by doy asc;

-- Match between datasets.
-- A bit messy but basically match on:
--		Start station and end station are the same
-- 		Trip occurs on the same day of the year
--		Trip start times are within an hour of each other
CREATE TABLE matches as SELECT a.uid as bixi, b.uid as helo
	FROM trips a, helo b
	WHERE a.start_name = b.station_start
	AND a.end_name = b.station_end
	AND extract(doy FROM a.start_date) = extract(doy from b.start_date)
	AND (extract(hour FROM a.start_date) > extract(hour from b.start_date) - 1
	AND extract(hour FROM a.start_date) < extract(hour from b.start_date) + 1);

-- How many helo trips?
SELECT count(distinct bixi) FROM matches;

-- How many total trips in the window where we have HELO data?
SELECT count(*) FROM trips
	WHERE start_date <= (select max(start_date) from helo)
	AND start_date >= (select min(start_date) from helo);

-- 23% of trips are helo trips in this case.