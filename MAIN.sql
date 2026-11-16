---count the rows in both tables--

select count(*) from safari_connect_dirty;
select count (*) from trips_staging;


CREATE TABLE safari_connect.safari_connect_dirty (
    booking_id        VARCHAR(20),
    passenger_name    VARCHAR(100),
    passenger_phone   VARCHAR(30),
    passenger_gender  VARCHAR(20),
    passenger_city    VARCHAR(50),
    route_code        VARCHAR(20),
    route_from        VARCHAR(50),
    route_to          VARCHAR(50),
    vehicle_plate     VARCHAR(20),
    vehicle_type      VARCHAR(30),
    driver_name       VARCHAR(100),
    driver_rating     VARCHAR(10),
    departure_date    VARCHAR(20),
    departure_time    VARCHAR(10),
    seat_class        VARCHAR(30),
    seats_booked      VARCHAR(10),
    fare_per_seat     VARCHAR(20),
    total_fare        VARCHAR(30),
    payment_method    VARCHAR(20),
    booking_status    VARCHAR(20),
    trip_rating       VARCHAR(10)
);

SELECT COUNT(*) FROM safari_connect.safari_connect_dirty;

-- 1-3: passenger names (uppercase, lowercase, extra spaces)
UPDATE safari_connect.safari_connect_dirty
SET passenger_name = INITCAP(TRIM(passenger_name));

-- 4-6: phone numbers (strip dashes, +254, empty)
UPDATE safari_connect.safari_connect_dirty
SET passenger_phone = REGEXP_REPLACE(passenger_phone, '[^0-9]', '', 'g')
WHERE passenger_phone IS NOT NULL;

UPDATE safari_connect.safari_connect_dirty
SET passenger_phone = '0' || SUBSTRING(passenger_phone FROM 4)
WHERE passenger_phone LIKE '254%' AND LENGTH(passenger_phone) = 12;

UPDATE safari_connect.safari_connect_dirty
SET passenger_phone = NULL
WHERE TRIM(passenger_phone) = '';

-- 7: DD/MM/YYYY
UPDATE safari_connect.safari_connect_dirty
SET departure_date = TO_CHAR(TO_DATE(departure_date, 'DD/MM/YYYY'), 'YYYY-MM-DD')
WHERE departure_date LIKE '__/__/____';

-- 8: MM-DD-YYYY
UPDATE safari_connect.safari_connect_dirty
SET departure_date = TO_CHAR(TO_DATE(departure_date, 'MM-DD-YYYY'), 'YYYY-MM-DD')
WHERE departure_date LIKE '__-__-____';

-- 9: DD-MM-YY
UPDATE safari_connect.safari_connect_dirty
SET departure_date = TO_CHAR(TO_DATE(departure_date, 'DD-MM-YY'), 'YYYY-MM-DD')
WHERE departure_date LIKE '__-__-__';

-- 10-12: passenger city
UPDATE safari_connect.safari_connect_dirty
SET passenger_city = INITCAP(TRIM(passenger_city));

UPDATE safari_connect.safari_connect_dirty
SET passenger_city = 'Unknown'
WHERE passenger_city IS NULL OR TRIM(passenger_city) = '';

-- 13: gender
UPDATE safari_connect.safari_connect_dirty
SET passenger_gender = CASE
    WHEN UPPER(TRIM(passenger_gender)) IN ('MALE','M') THEN 'Male'
    WHEN UPPER(TRIM(passenger_gender)) IN ('FEMALE','F') THEN 'Female'
    ELSE 'Unknown'
END;

-- 14: payment method
UPDATE safari_connect.safari_connect_dirty
SET payment_method = CASE
    WHEN UPPER(TRIM(payment_method)) LIKE '%MPESA%' OR UPPER(TRIM(payment_method)) LIKE '%M-PESA%' THEN 'M-Pesa'
    WHEN UPPER(TRIM(payment_method)) = 'CASH' THEN 'Cash'
    WHEN UPPER(TRIM(payment_method)) = 'CARD' THEN 'Card'
    ELSE 'Other'
END;

-- 15: booking status
UPDATE safari_connect.safari_connect_dirty
SET booking_status = INITCAP(TRIM(booking_status));

-- 16-17: fares (strip KES / commas / spaces)
UPDATE safari_connect.safari_connect_dirty
SET total_fare = REGEXP_REPLACE(TRIM(total_fare), '[^0-9]', '', 'g')
WHERE TRIM(total_fare) != '';

UPDATE safari_connect.safari_connect_dirty
SET fare_per_seat = REGEXP_REPLACE(TRIM(fare_per_seat), '[^0-9]', '', 'g')
WHERE TRIM(fare_per_seat) != '';

-- 18-19: seat class
UPDATE safari_connect.safari_connect_dirty
SET seat_class = CASE
    WHEN UPPER(TRIM(seat_class)) LIKE '%ECONOMY%' OR UPPER(TRIM(seat_class)) LIKE '%ECO%' THEN 'Economy'
    WHEN UPPER(TRIM(seat_class)) LIKE '%BUSINESS%' OR UPPER(TRIM(seat_class)) LIKE '%BUS%' THEN 'Business'
    ELSE 'Unknown'
END;

-- 20: driver names
UPDATE safari_connect.safari_connect_dirty
SET driver_name = INITCAP(TRIM(driver_name));

-- 21: invalid trip ratings
UPDATE safari_connect.safari_connect_dirty
SET trip_rating = NULL
WHERE trip_rating IN ('0','6');

-- 22: delete negative seats
DELETE FROM safari_connect.safari_connect_dirty
WHERE seats_booked = '-1';

-- 23: delete duplicate booking ids
DELETE FROM safari_connect.safari_connect_dirty
WHERE ctid NOT IN (
    SELECT MIN(ctid)
    FROM safari_connect.safari_connect_dirty
    GROUP BY booking_id
);




SELECT COUNT(*) FROM safari_connect.safari_connect_dirty;

ALTER TABLE safari_connect.safari_connect_dirty
    ALTER COLUMN seats_booked TYPE INTEGER USING seats_booked::INTEGER,
    ALTER COLUMN fare_per_seat TYPE INTEGER USING fare_per_seat::INTEGER,
    ALTER COLUMN total_fare   TYPE INTEGER USING total_fare::INTEGER,
    ALTER COLUMN driver_rating TYPE NUMERIC USING driver_rating::NUMERIC,
    ALTER COLUMN trip_rating   TYPE INTEGER USING trip_rating::INTEGER,
    ALTER COLUMN departure_date TYPE DATE USING departure_date::DATE;

CREATE OR REPLACE VIEW cleaned_trips AS
SELECT * FROM safari_connect.safari_connect_dirty;

SELECT COUNT(*) FROM cleaned_trips;                
SELECT DISTINCT booking_status FROM cleaned_trips;
SELECT DISTINCT driver_name FROM cleaned_trips ORDER BY driver_name;



--Route Analysis Which routes earn the most? 

select
route_code,
route_from,
route_to,
SUM(total_fare) as total_revenue,
sum(seats_booked) as total_seats_booked
from cleaned_trips
where booking_status = 'Completed'
group by route_code, route_from, route_to
order by total_revenue desc;



--Which are most popular? 

select 
route_code,
route_from,
route_to,
sum(seats_booked) as total_seats_booked
from cleaned_trips
where booking_status = 'Completed'
group by route_code, route_from, route_to
order by total_seats_booked  desc;



--Which is most efficient per seat sold?
--Specific route codes with KES figures. A clear top route and a clear underperformer.

select 
route_code,
route_from,
route_to,
sum(total_fare) as total_revenue,
sum(seats_booked) as total_seats_booked,
round(sum(total_fare) / nullif(sum(seats_booked), 0), 2) as revenue_per_seat
from cleaned_trips ct 
where booking_status = 'Completed'
group by route_code, route_from, route_to
order by revenue_per_seat desc;

 

--Driver Performance Who are the best drivers? 

SELECT 
    driver_name,
    COUNT(*) AS trips,
    SUM(seats_booked) AS seats,
    SUM(total_fare) AS revenue,
    ROUND(AVG(driver_rating)::numeric, 2) AS rating
FROM cleaned_trips
WHERE booking_status = 'Completed'
GROUP BY driver_name
ORDER BY revenue DESC;


--Does driver rating affect passenger satisfaction?
select
driver_name,
avg(driver_rating) as driver_rating,
round(Avg(trip_rating)::numeric,1) as passenger_satisfaction
from cleaned_trips ct 
where booking_status = 'Completed'
group by driver_name
order by driver_rating desc, passenger_satisfaction desc;



--Named drivers with revenue and rating figures. 
--A promotion recommendation with data behind it.

select
driver_name,
sum(total_fare) as total_revenue,
sum(seats_booked) as total_seats_booked,
avg(driver_rating) as driver_rating,
round(avg(trip_rating):: numeric, 1) as passenger_satisfaction
from cleaned_trips ct 
where booking_status = 'Completed'
group by driver_name
order by total_revenue desc;


--Revenue Trends How is revenue changing month by month? 

select
to_char(departure_date, 'yyyy-mm') as month,
count(*) as bookings,
sum(seats_booked) as total_seats_booked,
sum(total_fare) as total_revenue
from cleaned_trips ct 
where booking_status = 'Completed'
group by month
order by total_revenue desc;

--What are our best and worst months?
--Month-over-month change with % growth. A trend direction - growing or declining?

select
to_char(departure_date, 'yyyy-mm') as month,
sum(total_fare) as total_revenue
from cleaned_trips ct 
where booking_status = 'Completed'
group by month
order by total_revenue asc;

SELECT 
    TO_CHAR(departure_date, 'YYYY-MM') AS month,
    COUNT(*) AS bookings,
    SUM(seats_booked) AS seats,
    SUM(total_fare) AS revenue,
    LAG(SUM(total_fare)) OVER (ORDER BY TO_CHAR(departure_date, 'YYYY-MM')) AS prev_month,
    ROUND(
        100.0 * (SUM(total_fare) - LAG(SUM(total_fare)) OVER (ORDER BY TO_CHAR(departure_date, 'YYYY-MM')))
        / NULLIF(LAG(SUM(total_fare)) OVER (ORDER BY TO_CHAR(departure_date, 'YYYY-MM')), 0)
    , 2) AS mom_growth_pct
FROM cleaned_trips
WHERE booking_status = 'Completed'
GROUP BY TO_CHAR(departure_date, 'YYYY-MM')
ORDER BY month;


--passenger Insights 
--Where do passengers come from? top cities
select
passenger_city,
count (*) as bookings,
 sum(total_fare) as total_revenue,
 sum(seats_booked) as total_seats_booked
 from cleaned_trips
 where booking_status = 'Completed'
 group by passenger_city 
 order by bookings desc;



--What seat class do they prefer? 

select
 seat_class,
 count (*) as bookings,
 sum(total_fare) as revenue
 from cleaned_trips
 where booking_status = 'Completed'
 group by seat_class
 order by bookings desc;


--Are they satisfied?
SELECT 
    ROUND(AVG(trip_rating)::numeric, 2) AS avg_satisfaction,
    COUNT(*) FILTER (WHERE trip_rating = 5) AS rated_5,
    COUNT(*) FILTER (WHERE trip_rating = 4) AS rated_4,
    COUNT(*) FILTER (WHERE trip_rating = 3) AS rated_3,
    COUNT(*) FILTER (WHERE trip_rating = 2) AS rated_2,
    COUNT(*) FILTER (WHERE trip_rating = 1) AS rated_1
FROM cleaned_trips
WHERE booking_status = 'Completed'
  AND trip_rating IS NOT NULL;
--Top cities with numbers. Satisfaction breakdown. Gender and class split.

SELECT 
    passenger_gender,
    COUNT(*) AS bookings,
    SUM(total_fare) AS revenue
FROM cleaned_trips
WHERE booking_status = 'Completed'
GROUP BY passenger_gender
ORDER BY bookings DESC;


--Cancellations What is the cancellation rate per route?

SELECT 
    route_code,
    COUNT(*) AS total_bookings,
    COUNT(*) FILTER (WHERE booking_status = 'Cancelled') AS cancelled,
    COUNT(*) FILTER (WHERE booking_status = 'No Show') AS no_shows,
    ROUND(100.0 * COUNT(*) FILTER (WHERE booking_status IN ('Cancelled','No Show')) 
          / COUNT(*), 2) AS cancel_rate_pct,
    SUM(total_fare) FILTER (WHERE booking_status IN ('Cancelled','No Show')) AS lost_revenue
FROM cleaned_trips
GROUP BY route_code
ORDER BY lost_revenue DESC NULLS LAST;


--How much revenue did cancellations cost us?
--A KES figure for lost revenue. The worst route for cancellations. A policy recommendation.
SELECT 
    COUNT(*) AS total,
    COUNT(*) FILTER (WHERE booking_status = 'Cancelled') AS cancelled,
    COUNT(*) FILTER (WHERE booking_status = 'No Show') AS no_shows,
    ROUND(100.0 * COUNT(*) FILTER (WHERE booking_status IN ('Cancelled','No Show')) / COUNT(*), 2) AS cancel_rate_pct,
    SUM(total_fare) FILTER (WHERE booking_status IN ('Cancelled','No Show')) AS total_lost_revenue
FROM cleaned_trips;


--Operational Patterns What are our busiest days and times?
SELECT 
    TO_CHAR(departure_date, 'Day') AS day_of_week,
    EXTRACT(ISODOW FROM departure_date) AS day_num,
    COUNT(*) AS bookings,
    SUM(total_fare) AS revenue
FROM cleaned_trips
WHERE booking_status = 'Completed'
GROUP BY TO_CHAR(departure_date, 'Day'), EXTRACT(ISODOW FROM departure_date)
ORDER BY day_num;


--When should we add more vehicles?
--Specific days and times with booking and revenue numbers. 
--A clear peak period.
SELECT 
    EXTRACT(HOUR FROM departure_time::time) AS hour_of_day,
    COUNT(*) AS bookings,
    SUM(total_fare) AS revenue
FROM cleaned_trips
WHERE booking_status = 'Completed'
GROUP BY EXTRACT(HOUR FROM departure_time::time)
ORDER BY hour_of_day;

alter table safari_connect.safari_connect_dirty
add column day_of_the_week varchar(20);

update safari_connect.safari_connect_dirty scd 
set day_of_the_week = to_char(departure_date, 'Day');

create or replace view cleaned_trips as
select * 
from safari_connect.safari_connect_dirty scd  ;

select *
from cleaned_trips ct ;

select day_of_the_week, 
count(*)
from cleaned_trips ct 
group by day_of_the_week 
order by day_of_the_week ;
