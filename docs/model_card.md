# Model Card: `seoul_day_ahead_rf_v1`

## Intended use

Historical replay of 24 system-wide hourly rental-count forecasts for D+1, issued at 00:00 `Asia/Seoul` on D. This is a portfolio demonstration, not a live operational service or a station-level forecast.

## Frozen model

`ranger` regression in a `parsnip`/`workflows` workflow: 500 trees, `mtry = 4`, minimum node size 20, seed 32026. It was refitted on 6,792 train-plus-validation hours after chronological selection. Model artifact MD5: `e4da864280d502584c8a899053193a58`. Forecasts are clamped to zero below; the metric input is not rounded.

The predictors are exact 48- and 168-hour demand lags, past-only demand profiles, hour and weekday factors, cyclic hour and day-of-year terms, and holiday/weekend indicators. Realized target-day weather is excluded.

## Evaluation

| Split | Hours | RMSE | MAE | R² |
|---|---:|---:|---:|---:|
| Validation | 1,272 | 385.24 | 247.20 | 0.635 |
| Locked test | 1,008 | 276.27 | 178.48 | 0.769 |

The locked-test hour-of-week baseline RMSE is 335.92, giving a 17.76% reduction in this period. Model choice was frozen before the one final locked-test evaluation. The lower test error reflects a different, easier period and is not a forecast of future gains.

## Error slices and limitations

On the locked test, the 18–23 hour band has RMSE 343.63, compared with 103.61 for 00–05. These aggregate slices describe October–November 2018; they are not a basis for further model selection. A single holiday day has 24 hourly observations, too few to generalize its holiday error.

The data cover one year and system-wide counts. No station, inventory, event, price, transit, or actual weather-forecast inputs are available. Missing dates restrict eligible histories. Performance is not established for future years, all seasons, nonfunctioning days, or station decisions.
