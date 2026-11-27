# Day-Ahead Prediction Contract

At 00:00 in `Asia/Seoul` on day D, issue 24 forecasts for the system-wide hourly rented-bike counts on D+1. Forecast hours are 00–23, with horizons 24–47 hours. Every observed-demand input must precede the issue timestamp; the most recent observed hour is D-1 23:00.

| Item | Frozen definition |
|---|---|
| Prediction unit | One system-hour |
| Target | `RENTED_BIKE_COUNT` |
| Output | `model_id`, `target_date`, `issue_timestamp`, `hour`, `prediction` |
| Complete day | Exactly 24 rows, each hour 0–23 once |
| Primary metric | Hourly RMSE on the eligible chronological split |
| Secondary metrics | MAE; supplemental R² |

The prediction function validates the issue timestamp, date, hour set, input schema, and finite input values. It clamps negative forecasts at zero. Display rounding does not change the continuous predictions used for evaluation.

## Feature availability

Allowed features are exact timestamp demand lags of 48 and 168 hours, same-hour means over the previous 7 and 28 days, a past-only hour-of-week mean, and known calendar, holiday, weekday, and cyclic terms. Past-only summaries filter history to timestamps strictly before the issue time. The holiday flag assumes an advance-published calendar.

Target-day realized weather and future outcomes are excluded. A 24-hour lag for D+1 refers to day D, whose demand is not available when the forecast is issued at D 00:00. Row-offset lags cannot substitute for exact timestamps across missing days. During model selection, each fit used only its allowed training or analysis period. After model choice was frozen, the final workflow was refitted on train plus validation. Locked-test outcomes were never used for fitting or selection.

Eligible target days are functioning days with all 24 target hours and exact 48- and 168-hour historical matches. Missing calendar dates and partial days are excluded, never filled with zeros. The final eligible cohort contains 325 days and 7,800 hourly rows.

| Split | Dates | Eligible days | Hours |
|---|---|---:|---:|
| Train | 2017-12-01 to 2018-07-31 | 230 | 5,520 |
| Validation | 2018-08-01 to 2018-09-30 | 53 | 1,272 |
| Locked test | 2018-10-01 to 2018-11-30 | 42 | 1,008 |

Model selection used train and validation. The chosen workflow was refitted on their combined 6,792 hours after selection, then evaluated once on the locked test. The frozen model is not retrained during portfolio packaging or App use. Aggregate test metrics are retained for reporting; row-level locked-test inputs and outcomes are outside the public App and CI scope.
