# Seoul Bike Demand: Day-Ahead Hourly Forecasting

An R portfolio project that forecasts the 24 system-wide hourly bike rental counts for the next day. At 00:00 in `Asia/Seoul` on day D, the model issues forecasts for hours 00–23 on D+1. Inputs use calendar information and demand observed strictly before issue time; realized target-day weather is excluded.

## Results and evaluation

The final `ranger` regression workflow was selected using chronological validation, then frozen before one locked-test evaluation. All metrics below use continuous, nonnegative hourly forecasts. Display rounding is separate.

| Model | Validation RMSE | Validation MAE | Locked-test RMSE | Locked-test MAE |
|---|---:|---:|---:|---:|
| Final random forest | 385.24 | 247.20 | 276.27 | 178.48 |
| Past-only hour-of-week mean | 522.35 | 404.49 | 335.92 | 239.42 |
| Exact 168-hour lag | 547.28 | 314.23 | 383.09 | 226.77 |
| Exact 48-hour lag | 550.40 | 356.51 | 389.42 | 247.01 |

The final model's locked-test R² is 0.769. Its RMSE is 17.76% below the hour-of-week baseline on this particular test period. October–November 2018 was easier than the validation period; the lower test error is not evidence of a general improvement in future performance. The locked test contains 1,008 hours on 42 eligible days.

## Prediction and data contracts

- Unit: one system-hour; output: one complete 24-hour target day.
- Issue time: 00:00 on D; target: D+1; horizons: 24–47 hours.
- Historical inputs: exact 48- and 168-hour demand lags and past-only hour profiles.
- Known inputs: calendar, weekday, holiday, and cyclic time terms.
- Excluded: realized target-day weather, 24-hour lag, future outcomes, and full-data normalization.
- Chronological split: train December 2017–July 2018 (5,520 hours); validation August–September 2018 (1,272); locked test October–November 2018 (1,008).

Missing dates and partial days are excluded by the eligibility contract. The holiday feature assumes a published calendar is available at issue time. See [prediction contract](docs/prediction_contract.md) and [model card](docs/model_card.md).

## What the repository demonstrates

- R functions for timestamp-aligned lags, past-only profiles, baseline evaluation, controlled statistical models, and frozen inference.
- Two SQLite audits: exact timestamp lag joins on a synthetic missing-hour fixture, and issue-time / complete-day checks on the outcome-free development demo. Run `python3 scripts/audit_sql.py`; see [SQL audit scope](sql/README.md). These are independent queries, not the earlier course SQL exercises.
- A Shiny historical forecast replay, aggregate performance views, and contract explanation. Replay inputs have no outcome column; the App does not read row-level locked-test files.
- A model artifact whose MD5 is `e4da864280d502584c8a899053193a58`, checked before inference.

The independent `testthat` suite, locked `renv` environment, and one-command acceptance have passed locally in a clean R session. GitHub Actions is staged but has not run in a new repository. See [reproduction](docs/reproduction.md) for commands, evidence, and the remaining CI gate.

## Data provenance and origin

The source dataset is [Seoul Bike Sharing Demand at UCI](https://archive.ics.uci.edu/dataset/560/seoul+bike+sharing+demand), cited as Easwaramoorthy, S. (2020), DOI [10.24432/C5F62R](https://doi.org/10.24432/C5F62R), under CC BY 4.0. See [data provenance](docs/data_provenance.md) for attribution and scope.

This independent forecasting project developed from a coursework topic. The day-ahead contract, chronological evaluation, engineering code, SQL audit, and App are presented as independent work. Course prompts, graded notebooks, staff code, and recovered solutions are not part of this repository. Earlier course-model metrics are not compared with the day-ahead results because their prediction questions differ.

## Limitations

One year of system-level observations does not support station-level forecasts or claims across future years. The eligible test period is late Autumn only. Inventory, events, pricing, transit disruptions, and genuine weather forecasts are unavailable. The Shiny App replays historical development inputs; it is not a live forecasting service.
