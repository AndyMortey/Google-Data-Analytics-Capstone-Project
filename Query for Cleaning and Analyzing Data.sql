/*1.ride_id:
--Change column name from rideable_id to ride_id
--Change column name from rideable_type to ride_type
--Change column name from member_casual to member_type
--Check for the length of characters in ride_id
--Check if the column has duplicates*/
ALTER TABLE bike_trip_data_n RENAME rideable_id TO ride_id;
ALTER TABLE bike_trip_data_n RENAME rideable_type TO ride_type;
ALTER TABLE bike_trip_data_n RENAME member_casual TO member_type;
SELECT ride_id,LENGTH(ride_id)AS CHARACTERS FROM bike_trip_data_n
GROUP BY ride_id,LENGTH(ride_id);

SELECT COUNT (DISTINCT ride_id)FROM bike_trip_data_n;
/*CONCLUSION:
All ride_id strings are 16 characters long and they are all distinct. Since ride_id is a primary key, all values
are unique.
No further cleaning is needed for this column*/

/*2.rideable_type:
--Check for the stated rideable_type*/
SELECT DISTINCT rideable_type FROM bike_trip_data_n;
/*CONCLUSION:
This shows there are 3 rideable_types; electric_bike,classic_bike and docked_bike.
However, docked_bikes is the old name for classic_bikes hence have to be changed to
classic_bike*/

UPDATE bike_trip_data_n SET rideable_type = 'classic_bike'
WHERE rideable_type = 'docked_bike';

SELECT rideable_type FROM bike_trip_data_n;
--All docked_bike types have been changed to classic_bike.

/*3.started_at/ended_at:
--Check for rows that have ride time less than one minute or greater than one day, 
and remove them*/
SELECT started_at, ended_at
FROM bike_trip_data_n
WHERE (ended_at - started_at) < INTERVAL '1 minute' OR
      (ended_at - started_at) > INTERVAL '1 day';

--Remove trips with ride time less than one minute or more than one day.
DELETE FROM bike_trip_data_n
WHERE (ended_at - started_at) < INTERVAL '1 minute' OR 
      (ended_at - started_at) > INTERVAL '1 day';
SELECT started_at,ended_at FROM bike_trip_data_n;

/*CONCLUSION:
Identified 58,058 trips that have ride time less than one minute or more than one day.
All these trips were removed,the resulting trips that fall within the ride time are 
5,665,474*/

---4.start_station_name/end_station_name:
SELECT start_station_name,end_station_name
FROM bike_trip_data_n;
--This produced 5665474 rows

--Clean the column by trimming leading and trailing spaces:
UPDATE bike_trip_data_n
SET start_station_name = TRIM(start_station_name),
end_station_name = TRIM(end_station_name);

--Check for the number of trips with null values in either columns:
SELECT start_station_name,end_station_name FROM bike_trip_data_n
WHERE start_station_name IS NULL OR end_station_name IS NULL;
--This returned 1,061,126 null values.

/*Check the number of trips with null values in either columns that
pertains to only classic bike trips*/
SELECT COUNT(*)
FROM bike_trip_data_n
WHERE rideable_type = 'classic_bike' AND 
(start_station_name IS NULL OR end_station_name IS NULL);
/*This shows that the number of trips with null values in either columns that
pertain to only classic bike trips are 6,031*/

--Remove trips with null values in either columns that pertain to only classic bike trips:
DELETE FROM bike_trip_data_n
WHERE rideable_type = 'classic_bike' AND 
(start_station_name IS NULL OR end_station_name IS NULL);

--Replace null values in either columns for only electric bike trips with the string 'On Bike Lock':
UPDATE bike_trip_data_n
SET start_station_name = 'On Bike Lock', end_station_name = 'On Bike Lock'
WHERE rideable_type = 'electric_bike' AND (start_station_name IS NULL OR end_station_name IS NULL);

--Remove trips that contained maintenance station names:
DELETE FROM bike_trip_data_n
WHERE start_station_name = 'WEST CHI-WATSON'
OR end_station_name = 'WEST CHI-WATSON'
OR start_station_name = 'DIVVY CASSETTE REPAIR MOBILE STATION'
OR end_station_name = 'DIVVY CASSETTE REPAIR MOBILE STATION'
OR start_station_name = '351'
OR end_station_name = '351'
OR start_station_name = 'Lyft Driver Center Private Rack'
OR end_station_name = 'Lyft Driver Center Private Rack'
OR start_station_name = 'Hubbard Bike-checking (LBS-WH-TEST)'
OR end_station_name = 'Hubbard Bike-checking (LBS-WH-TEST)'
OR start_station_name = 'Base - 2132 W Hubbard Warehouse'
OR end_station_name = 'Base - 2132 W Hubbard Warehouse';

/*5.start_station_id/end_station_id:
--Remove these columns from the table*/
ALTER TABLE bike_trip_data_n
DROP COLUMN start_station_id,
DROP COLUMN end_station_id;

/*6.start_lat/end_lat AND start_lng/end_lng:
--Remove all trips in these columns that have null values*/
DELETE FROM bike_trip_data_n WHERE start_latitude IS NULL OR start_longitude IS NULL OR end_latitude IS NULL
OR end_longitude IS NULL;
--This returned zero deletes meaning the columns have no null values.

/*7. member_casual:
--Check for the allowable strings in the column*/
SELECT DISTINCT member_casual FROM  bike_trip_data_n;
--This showed the allowable strings are casual and member.
SELECT * FROM  bike_trip_data_n; 

------------------------ANALYZING THE CLEANED DATA-----------
/*
1.Total number of rides and percentage of rides made by each group throughout the year.
2.Number of rides per month
2.Average ride duration for each group to see how they differ.
3. Which day of the week had the highest volume of trips for both groups.
4.In the introduction, it is stated that CYCLISTIC has 692 stations across chicago. So check to 
confirm the exact number of stations for both groups.
5.Number of Ride_type for both groups*/

----1.Determine the amount of rides for each member type and ride type---- 
 WITH type_of_ride AS (
 SELECT ride_type, member_type, count(*) AS amount_of_rides
 FROM  bike_trip_data_n
 GROUP BY ride_type, member_type
 ORDER BY member_type, amount_of_rides DESC)
 SELECT * FROM type_of_ride;
 
----2.Number of rides per month for each member type----
 WITH rides_per_month AS (
 SELECT member_type, DATE_TRUNC('month', started_at::timestamp) 
 AS month, count(*) AS num_of_rides
 FROM bike_trip_data_n
 GROUP BY member_type, month)
 SELECT * FROM rides_per_month;
   
----3.Average ride duration for each group to see how they differ----
 SELECT member_type, CASE
 WHEN member_type = 'member' THEN (SELECT AVG(ended_at - started_at))
 WHEN member_type = 'casual' THEN (SELECT AVG(ended_at - started_at))
 END AS average_trip_duration_all_year
 FROM bike_trip_data_n
 GROUP BY member_type;
	
----4.Determine which day of the week had the highest volume of trips for both groups----
 SELECT member_type, day_of_week, CASE
 WHEN member_type = 'member' THEN COUNT(*)
 WHEN member_type = 'casual' THEN COUNT(*)
 END AS day_of_week_count FROM bike_trip_data_n
 GROUP BY member_type, day_of_week
 ORDER BY member_type, day_of_week_count DESC;
 
----5.Check for the exact number of start_station_name for the member types----
  WITH cte AS (SELECT member_type, start_station_name,
  CASE WHEN member_type = 'casual' THEN 
  DENSE_RANK() OVER(PARTITION BY member_type ORDER BY COUNT(start_station_name) DESC)
  WHEN member_type = 'member' THEN 
  DENSE_RANK() OVER(PARTITION BY member_type ORDER BY COUNT(start_station_name) DESC)
  END AS RANK FROM bike_trip_data_n
  WHERE start_station_name IS NOT NULL AND start_station_name <> 'On Bike Lock'
  GROUP BY start_station_name, member_type
  ORDER BY member_type, RANK)
  SELECT * FROM cte
  WHERE RANK <= 5;
--------5a.Check for the exact number of end_station_name for the member types------
  WITH cte AS (SELECT member_type, end_station_name,
  CASE WHEN member_type = 'casual' THEN 
  DENSE_RANK() OVER(PARTITION BY member_type ORDER BY COUNT(end_station_name) DESC)
  WHEN member_type = 'member' THEN 
  DENSE_RANK() OVER(PARTITION BY member_type ORDER BY COUNT(end_station_name) DESC)
  END AS RANK FROM bike_trip_data_n
  WHERE end_station_name IS NOT NULL AND end_station_name <> 'On Bike Lock'
  GROUP BY end_station_name, member_type
  ORDER BY member_type, RANK)
  SELECT * FROM cte
  WHERE RANK <= 5;
  
 ----6.Count of ride type for the member types----
  SELECT ride_type, member_type, COUNT(*) AS total_rides
  FROM bike_trip_data_n
  GROUP BY ride_type, member_type
  ORDER BY ride_type, member_type, total_rides DESC;
   