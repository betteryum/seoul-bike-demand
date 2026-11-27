SELECT
  target.row_id,
  target.timestamp,
  target.issue_timestamp,
  lag48.rented_bike_count AS lag_48_sql,
  lag168.rented_bike_count AS lag_168_sql
FROM development_targets AS target
LEFT JOIN hourly_history AS lag48
  ON lag48.timestamp = target.lag_48_timestamp
LEFT JOIN hourly_history AS lag168
  ON lag168.timestamp = target.lag_168_timestamp
ORDER BY target.row_id;
