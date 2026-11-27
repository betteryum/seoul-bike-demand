-- Audit only the outcome-free train/validation replay input.
-- The caller creates development_demo from app/data/demo_forecast_inputs.csv.
WITH per_day AS (
  SELECT
    split,
    target_date,
    COUNT(*) AS hourly_rows,
    COUNT(DISTINCT hour) AS distinct_hours,
    MIN(hour) AS first_hour,
    MAX(hour) AS last_hour,
    SUM(CASE
      WHEN substr(issue_timestamp, 1, 10) = date(target_date, '-1 day')
       AND substr(issue_timestamp, 12, 8) = '00:00:00'
      THEN 0 ELSE 1
    END) AS timing_violations,
    SUM(CASE
      WHEN lag_48 IS NULL OR lag_168 IS NULL
        OR lag_48 < 0 OR lag_168 < 0
      THEN 1 ELSE 0
    END) AS lag_violations
  FROM development_demo
  GROUP BY split, target_date
)
SELECT
  split,
  COUNT(*) AS eligible_days,
  SUM(hourly_rows) AS hourly_rows,
  SUM(CASE
    WHEN hourly_rows = 24
     AND distinct_hours = 24
     AND first_hour = 0
     AND last_hour = 23
     AND timing_violations = 0
     AND lag_violations = 0
    THEN 0 ELSE 1
  END) AS invalid_days
FROM per_day
GROUP BY split
ORDER BY split;
