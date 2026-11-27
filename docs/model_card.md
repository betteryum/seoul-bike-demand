# Model Card: `seoul_day_ahead_rf_v1`

## Model summary

| Item | Frozen value |
|---|---|
| Task | Predict 24 system-wide hourly rental counts for D+1 |
| Issue time | D at 00:00 `Asia/Seoul` |
| Horizons | 24–47 hours |
| Framework | `parsnip` / `workflows` with the `ranger` regression engine |
| Hyperparameters | 500 trees; `mtry = 4`; minimum node size 20; seed 32026 |
| Final refit | 6,792 chronological train-plus-validation hours |
| Model artifact | `artifacts/phase3/final/final_model.rds` |
| Artifact MD5 | `e4da864280d502584c8a899053193a58` |

The model was selected using chronological development data, frozen, refitted on train plus validation, and evaluated once on the locked test. Portfolio packaging, testing, CI, and App use do not retrain or reselect it.

## Intended use

The intended use is historical replay of a complete next-day, system-wide demand profile. The repository demonstrates an explicit prediction contract, leakage-safe temporal features, a validated inference interface, and reproducible verification. It is not a live operational service, station-level forecast, causal model, or inventory optimization system.

## Inputs and outputs

The 13 frozen predictors are:

- Historical demand: exact 48- and 168-hour lags, past-only hour-of-week mean, and past-only same-hour 7-day and 28-day means.
- Known calendar information: hour and weekday factors, hour and day-of-year cyclic terms, holiday indicator, and weekend indicator.

Realized target-day weather, the unavailable 24-hour lag, future outcomes, and full-data normalization are excluded. Observed-demand inputs must occur strictly before issue time.

The validated day-ahead interface returns exactly 24 ordered rows with:

```text
model_id, target_date, issue_timestamp, hour, prediction
```

It rejects missing or extra predictors, invalid types or ranges, unsupported factor levels, incomplete or repeated hours, mismatched dates, and invalid issue timestamps. Negative raw forecasts are clamped at zero. Evaluation retains continuous forecasts; integer rounding is display-only.

## Data and evaluation design

Eligible days must be functioning, contain all 24 target hours, and have all exact 48- and 168-hour historical matches. Missing dates and partial days are excluded rather than imputed with zero.

| Split | Dates | Eligible days | Hours | Role |
|---|---|---:|---:|---|
| Train | 2017-12-01 to 2018-07-31 | 230 | 5,520 | Model development |
| Validation | 2018-08-01 to 2018-09-30 | 53 | 1,272 | Chronological selection |
| Locked test | 2018-10-01 to 2018-11-30 | 42 | 1,008 | One final evaluation |

Primary metric: RMSE. Secondary metric: MAE. R² is supplemental.

## Final performance

| Model | Validation RMSE | Validation MAE | Locked-test RMSE | Locked-test MAE | Locked-test R² |
|---|---:|---:|---:|---:|---:|
| **`seoul_day_ahead_rf_v1`** | **385.24** | **247.20** | **276.27** | **178.48** | **0.769** |
| Past-only hour-of-week mean | 522.35 | 404.49 | 335.92 | 239.42 | 0.685 |
| Exact 168-hour lag | 547.28 | 314.23 | 383.09 | 226.77 | 0.595 |
| Exact 48-hour lag | 550.40 | 356.51 | 389.42 | 247.01 | 0.563 |

The frozen model's locked-test RMSE is 17.76% below the hour-of-week baseline in this specific period. Every compared method had lower error on the October–November test interval than on August–September validation; the apparent improvement therefore does not establish universal future gains.

## Aggregate error diagnostics

| Slice | n | RMSE | MAE | Mean error |
|---|---:|---:|---:|---:|
| Hour 00–05 | 252 | 103.61 | 63.17 | -37.73 |
| Hour 06–11 | 252 | 276.61 | 175.00 | -27.64 |
| Hour 12–17 | 252 | 316.18 | 221.02 | -105.41 |
| Hour 18–23 | 252 | 343.63 | 254.73 | -179.35 |
| October 2018 | 504 | 305.68 | 198.75 | -82.91 |
| November 2018 | 504 | 243.33 | 158.21 | -92.15 |
| Holiday | 24 | 396.48 | 301.65 | 138.30 |
| No Holiday | 984 | 272.68 | 175.47 | -93.04 |

Evening-hour errors were larger than overnight errors. Holiday evidence consists of only one 24-hour day and is too sparse for generalization. These locked-test slices are descriptive evidence, not inputs to further model selection.

## Reproducibility and integrity

- The model file and three aggregate evidence tables are checked against fixed MD5 values.
- Integration tests load the real frozen workflow and score an outcome-free 24-hour development day.
- The App uses 6,792 outcome-free train/validation rows and committed aggregate test tables; it has no row-level locked-test file reference.
- The acceptance gate checks the contract, inference behavior, artifact integrity, App boundary, and two independent SQL audits.
- The latest audited pre-documentation GitHub Actions run, [45925771208](https://github.com/betteryum/seoul-bike-demand/actions/runs/45925771208), passed 12/12 checks on Ubuntu 24.04.5 with R 4.4.1 and a synchronized 114-package lockfile. The workflow badge reports the current `main` result.

## Limitations and risks

The data cover one city and one historical year. The target is total system demand rather than station demand. Performance is not established for future years, all seasons, nonfunctioning days, or operational interventions. Inventory, events, prices, transit disruptions, and genuine weather forecasts are unavailable. Historical patterns can change, and the late-autumn test period may not represent future use.

The model should not be used for real allocation decisions without new out-of-time evaluation, appropriate operational features, monitoring, and a clearly defined retraining and failure-handling process.
