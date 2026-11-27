# Independent SQL Contract Audits

Run `python3 scripts/audit_sql.py` from the repository root. Python's standard-library `sqlite3` runs both queries in memory, with no server, credential, external API, or Python package installation.

`01_exact_lag_audit.sql` joins target rows to historical demand by exact timestamp. The runner creates two **synthetic** target rows and deliberately omits one 48-hour historical match; the missing value must remain NULL instead of shifting to an adjacent row. This fixture does not use real target outcomes.

`02_development_day_audit.sql` groups the outcome-free `app/data/demo_forecast_inputs.csv` by split and target date. It verifies 24 distinct hours 0–23, the preceding day's 00:00 issue time, and nonmissing, nonnegative exact demand lags. Expected aggregate output is 230 train days / 5,520 hours and 53 validation days / 1,272 hours, with zero invalid days. The loader rejects a changed CSV schema or an outcome column.

These audits demonstrate exact joins, grouping, conditional aggregation, and issue-time checks. They audit the frozen contract; they do not rebuild the training data or recalculate model metrics. The earlier coursework SQL queries and row-level locked-test files are excluded.
