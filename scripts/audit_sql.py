"""Run the independent SQL contract audits without external Python packages."""

import csv
import sqlite3
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEMO = ROOT / "app/data/demo_forecast_inputs.csv"
EXACT_LAG_SQL = ROOT / "sql/01_exact_lag_audit.sql"
DAY_AUDIT_SQL = ROOT / "sql/02_development_day_audit.sql"
DEMO_COLUMNS = (
    "split", "target_date", "hour", "issue_timestamp", "weekday", "weekend",
    "holiday_indicator", "lag_48", "lag_168", "hour_of_week_mean",
    "same_hour_mean_7d", "same_hour_mean_28d", "hour_sin", "hour_cos",
    "day_of_year_sin", "day_of_year_cos",
)


def audit_exact_lag_fixture(connection):
    connection.executescript(
        """
        CREATE TABLE development_targets (
          row_id INTEGER PRIMARY KEY,
          timestamp TEXT NOT NULL,
          issue_timestamp TEXT NOT NULL,
          lag_48_timestamp TEXT NOT NULL,
          lag_168_timestamp TEXT NOT NULL
        );
        CREATE TABLE hourly_history (
          timestamp TEXT PRIMARY KEY,
          rented_bike_count INTEGER NOT NULL
        );
        """
    )
    connection.executemany(
        "INSERT INTO development_targets VALUES (?, ?, ?, ?, ?)",
        [
            (1, "2018-01-10 00:00:00", "2018-01-09 00:00:00",
             "2018-01-08 00:00:00", "2018-01-03 00:00:00"),
            (2, "2018-01-10 01:00:00", "2018-01-09 00:00:00",
             "2018-01-08 01:00:00", "2018-01-03 01:00:00"),
        ],
    )
    # Deliberately unsorted; one exact 48-hour timestamp is absent.
    connection.executemany(
        "INSERT INTO hourly_history VALUES (?, ?)",
        [
            ("2018-01-03 01:00:00", 95),
            ("2018-01-08 00:00:00", 120),
            ("2018-01-09 12:00:00", 999),
            ("2018-01-03 00:00:00", 90),
        ],
    )
    rows = connection.execute(EXACT_LAG_SQL.read_text(encoding="utf-8")).fetchall()
    assert [(row[0], row[3], row[4]) for row in rows] == [
        (1, 120, 90), (2, None, 95)
    ], "Exact timestamp joins failed the missing-hour fixture"
    print("SQL_EXACT_LAG_FIXTURE_PASS: 2 synthetic targets")


def audit_development_demo(connection):
    with DEMO.open(newline="", encoding="utf-8") as source:
        reader = csv.DictReader(source)
        assert tuple(reader.fieldnames or ()) == DEMO_COLUMNS, (
            "Development demo schema changed or contains an outcome column"
        )
        connection.execute(
            """CREATE TABLE development_demo (
                 split TEXT NOT NULL, target_date TEXT NOT NULL,
                 hour INTEGER NOT NULL, issue_timestamp TEXT NOT NULL,
                 lag_48 REAL, lag_168 REAL
               )"""
        )
        connection.executemany(
            "INSERT INTO development_demo VALUES (?, ?, ?, ?, ?, ?)",
            (
                (row["split"], row["target_date"], int(row["hour"]),
                 row["issue_timestamp"], float(row["lag_48"]),
                 float(row["lag_168"]))
                for row in reader
            ),
        )

    rows = connection.execute(DAY_AUDIT_SQL.read_text(encoding="utf-8")).fetchall()
    assert rows == [
        ("train", 230, 5520, 0),
        ("validation", 53, 1272, 0),
    ], "Development day counts or issue-time contract failed"
    print("SQL_DEVELOPMENT_DAY_AUDIT_PASS: train=230/5520, validation=53/1272, invalid=0")


def main():
    with sqlite3.connect(":memory:") as connection:
        audit_exact_lag_fixture(connection)
        audit_development_demo(connection)


if __name__ == "__main__":
    main()
