CREATE DATABASE london_airports_project;
USE london_airports_project;
SELECT COUNT(*) FROM fact_punctuality;
SELECT * FROM fact_punctuality LIMIT 10;

#how many flights per airport
SELECT
    reporting_airport,
    SUM(number_flights_matched) AS total_flights
FROM fact_punctuality
GROUP BY reporting_airport
ORDER BY total_flights DESC;

#Is the average delay figure misleading if I don't weight it by flight volume?
SELECT
    reporting_airport,
    ROUND(SUM(average_delay_mins * number_flights_matched) / SUM(number_flights_matched), 2) AS weighted_avg_delay_mins,
    ROUND(AVG(average_delay_mins), 2) AS simple_avg_delay_mins
FROM fact_punctuality
WHERE number_flights_matched > 0
GROUP BY reporting_airport
ORDER BY weighted_avg_delay_mins DESC;

#Which airline has the worst average delay across London airports?
SELECT
    airline_name,
    SUM(number_flights_matched) AS total_flights,
    ROUND(AVG(average_delay_mins), 1) AS avg_delay_mins
FROM fact_punctuality
WHERE number_flights_matched > 0
GROUP BY airline_name
HAVING SUM(number_flights_matched) > 500
ORDER BY avg_delay_mins DESC
LIMIT 10;

#Which airlines are the most punctual (lowest average delay) operating from London airports?
SELECT
    airline_name,
    SUM(number_flights_matched) AS total_flights,
    ROUND(AVG(average_delay_mins), 1) AS avg_delay_mins
FROM fact_punctuality
WHERE number_flights_matched > 0
GROUP BY airline_name
HAVING SUM(number_flights_matched) > 500
ORDER BY avg_delay_mins ASC
LIMIT 10;

#What's the busiest route (origin airport → destination) overall
SELECT
    reporting_airport AS origin,
    origin_destination AS destination,
    SUM(number_flights_matched) AS total_flights
FROM fact_punctuality
GROUP BY origin, destination
ORDER BY total_flights DESC
LIMIT 10;

#Is there a difference in cancellation rate between Scheduled and Charter flights?
SELECT
    scheduled_charter,
    SUM(number_flights_matched) AS total_flights,
    SUM(number_flights_cancelled) AS total_cancelled,
    ROUND(SUM(number_flights_cancelled) / SUM(number_flights_matched) * 100, 2) AS cancellation_rate_pct
FROM fact_punctuality
GROUP BY scheduled_charter;

#Is there a difference in cancellation rate between Scheduled and Charter flights?
#Is Gatwick's delay actually driven by charter mix, or does it hold within scheduled flights too?
SELECT
    reporting_airport,
    scheduled_charter,
    ROUND(SUM(average_delay_mins * number_flights_matched) / SUM(number_flights_matched), 2) AS weighted_avg_delay_mins,
    SUM(number_flights_matched) AS total_flights
FROM fact_punctuality
WHERE number_flights_matched > 0
GROUP BY reporting_airport, scheduled_charter
ORDER BY reporting_airport, scheduled_charter;


#How did each airport's flight volume change year over year (2023 → 2024 → 2025)?
#yoy
#Step 1: just get total flights per airport per year first
SELECT
    reporting_airport,
    YEAR(reporting_period) AS flight_year,
    SUM(number_flights_matched) AS total_flights
FROM fact_punctuality
GROUP BY reporting_airport, flight_year
ORDER BY reporting_airport, flight_year;
#Step 2: now let's calculate the actual year-over-year % change, using a window function ...LAG()
SELECT
    reporting_airport,
    flight_year,
    total_flights,
    LAG(total_flights) OVER (PARTITION BY reporting_airport ORDER BY flight_year) AS previous_year_flights,
    ROUND(
        (total_flights - LAG(total_flights) OVER (PARTITION BY reporting_airport ORDER BY flight_year))
        / LAG(total_flights) OVER (PARTITION BY reporting_airport ORDER BY flight_year) * 100
    , 1) AS yoy_pct_change
FROM (
    SELECT
        reporting_airport,
        YEAR(reporting_period) AS flight_year,
        SUM(number_flights_matched) AS total_flights
    FROM fact_punctuality
    GROUP BY reporting_airport, flight_year
) AS yearly_totals
ORDER BY reporting_airport, flight_year;


#Is London City's high cancellation rate caused by one bad airline, or is it spread across the whole airport?
SELECT
    airline_name,
    SUM(number_flights_matched) AS total_flights,
    SUM(number_flights_cancelled) AS total_cancelled,
    ROUND(SUM(number_flights_cancelled) / SUM(number_flights_matched) * 100, 2) AS cancellation_rate_pct
FROM fact_punctuality
WHERE reporting_airport = 'LONDON CITY' AND number_flights_matched > 0
GROUP BY airline_name
HAVING SUM(number_flights_matched) > 500
ORDER BY cancellation_rate_pct DESC;



#Key Findings — London Airport & Airline Performance (2023–2026)

#Heathrow dominates London air traffic — 1,546,667 flights over the period, nearly double Gatwick (845,364) and more than the other four airports combined. It also holds 9 of the top 10 busiest individual routes from London, led by Heathrow → New York JFK (49,417 flights).
#Punctuality issues aren't simply a long-haul vs short-haul story. While some long-haul carriers (Tunisair 48.9 min, Rwandair Express 47.8 min, Air India 38 min) show the worst average delays, other long-haul airlines (JetBlue 9.0 min, Japan Airlines 9.7 min) rank among the most punctual — the pattern is airline-specific, not distance-based.
#Growth since 2023 has been uneven across airports. Luton shows the strongest, most consistent growth (+2.6% in 2024, +3.1% in 2025). Heathrow and Gatwick grew initially but plateaued by 2025. London City has stayed essentially flat, showing little post-2023 growth.
#Traffic is clearly seasonal, with a consistent summer peak (July) and winter trough every year from 2023–2025, and each summer's peak has been slightly higher than the last — a sign of steady overall recovery/growth in London flight volumes.
#(Note: 2026 figures only cover part of the year, so year-over-year comparisons involving 2026 aren't directly comparable to full prior years.)
#Gatwick's delay disadvantage is not explained by a higher charter flight share — it holds even within scheduled flights alone (21.14 min vs Heathrow's 16.23 min scheduled), confirming the finding is genuine rather than a route-mix artefact.
#London City's high cancellation rate is not driven by one underperforming airline — BA CityFlyer, its largest operator by far, actually has a below-average cancellation rate (2.39% vs the airport's 2.95% overall), so the pattern is airport-wide rather than a single carrier problem.


SELECT DISTINCT origin_destination FROM fact_punctuality ORDER BY origin_destination;