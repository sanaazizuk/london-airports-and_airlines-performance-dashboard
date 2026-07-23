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

#Question: How did each airport's flight volume change year over year (2023 → 2024 → 2025)?
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




#Key Findings — London Airport & Airline Performance (2023–2026)

#Heathrow dominates London air traffic — 1,546,667 flights over the period, nearly double Gatwick (845,364) and more than the other four airports combined. It also holds 9 of the top 10 busiest individual routes from London, led by Heathrow → New York JFK (49,417 flights).
#Punctuality issues aren't simply a long-haul vs short-haul story. While some long-haul carriers (Tunisair 48.9 min, Rwandair Express 47.8 min, Air India 38 min) show the worst average delays, other long-haul airlines (JetBlue 9.0 min, Japan Airlines 9.7 min) rank among the most punctual — the pattern is airline-specific, not distance-based.
#Growth since 2023 has been uneven across airports. Luton shows the strongest, most consistent growth (+2.6% in 2024, +3.1% in 2025). Heathrow and Gatwick grew initially but plateaued by 2025. London City has stayed essentially flat, showing little post-2023 growth.
#Traffic is clearly seasonal, with a consistent summer peak (July) and winter trough every year from 2023–2025, and each summer's peak has been slightly higher than the last — a sign of steady overall recovery/growth in London flight volumes.

#(Note: 2026 figures only cover part of the year, so year-over-year comparisons involving 2026 aren't directly comparable to full prior years.)