# Reproduction and Verification Evidence

## Audited GitHub Actions runs

| Run | Commit and purpose | Environment | Evidence |
|---|---|---|---|
| [45920704558](https://github.com/betteryum/seoul-bike-demand/actions/runs/45920704558) | `8f311e9e0bc165689cab69150bbe1b5494ec6162`; initial independent commit | Ubuntu 24.04.5, R 4.4.1; cold dependency restore | 114 locked packages synchronized; 12/12 PASS; four warning-free test groups |
| [45922044658](https://github.com/betteryum/seoul-bike-demand/actions/runs/45922044658) | `83506577ff58497b75f6ba19446e2c626504eb95`; verification documentation | Ubuntu 24.04.5, R 4.4.1; package-cache hit followed by restore | 12/12 PASS; unchanged hashes; no locked-test row access |
| [45924701331](https://github.com/betteryum/seoul-bike-demand/actions/runs/45924701331) | `9aa092af07d22f3f282d64ec9c7fdaca78573792`; public release | Ubuntu 24.04.5, R 4.4.1 | every job step succeeded; 12/12 PASS; four warning-free test groups |
| [45925771208](https://github.com/betteryum/seoul-bike-demand/actions/runs/45925771208) | `f8f690d8b20be114d098c5d1dc6714071e9b94e6`; README Shiny preview | Ubuntu 24.04.5, R 4.4.1 | synchronized environment; 12/12 PASS; four warning-free test groups |

The initial run's restore action took about 75.8 seconds and the complete job about 125 seconds. Its log records `renv` 1.1.4, `ranger` 0.17.0, `parsnip` 1.4.1, `workflows` 1.3.0, and `testthat` 3.2.3. `renv.lock` is the authoritative full dependency record.

External runner setup emitted a temporary Git branch-name hint and, in the documentation run, two Ubuntu `gdebi` Python `SyntaxWarning` lines plus a system-package advisory concerning `libx11-dev` for the unrelated `clipr` package. These were runner or system setup messages, not R/test warnings. The project environment synchronized, every acceptance check passed, and every workflow step concluded successfully.

## Acceptance coverage

The single acceptance command records 12 checks:

1. Required inference inputs present.
2. Frozen model MD5 unchanged.
3. Aggregate test-metrics MD5 unchanged.
4. Aggregate slice-audit MD5 unchanged.
5. Validation-versus-test evidence MD5 unchanged.
6. App source contains no row-level locked-test file reference.
7. Restricted course, test-row, credential, and secret paths are absent.
8. Both independent SQL audits pass.
9. Contract tests pass without warnings.
10. Frozen inference integration tests pass without warnings.
11. Artifact integrity tests pass without warnings.
12. App-boundary tests pass without warnings.

## Local clean-session evidence

On macOS with R 4.4.1, the independent repository's project library synchronized with all 114 locked packages. Restore took 10.7 seconds using the existing local package cache. A separate `Rscript --vanilla` invocation passed all 12 checks and both SQL audits with zero R/test warnings. The SQL precheck recorded Python 3.9.6 and SQLite 3.39.5.

## Shiny visual evidence

The three-page App passed 14/14 visual checks: successful launch; a Forecast Replay page with three value boxes, one plot and a 24-row table; working replay dates in train and validation; readable axes and labels; correct RMSE, MAE and R² cards; all model, metric and slice controls; a correct validation/test table; a complete Prediction Contract page; and no visible overflow, browser error, or R Console error. Three final review screenshots were retained for the public README.

## History and publication audit

The pre-publication review covered both independent commits through `83506577ff58497b75f6ba19446e2c626504eb95`, all 47 historical paths, source, documentation, dependency metadata, links, frozen artifacts, aggregate evidence, and model strings. It found no imported recovery history, course prompt or answer files, row-level locked-test features, predictions or outcomes, credentials, API keys, or local user paths.

The release checkpoint then verified that `9aa092af07d22f3f282d64ec9c7fdaca78573792` was a documentation-only child commit with a 47-file tree and unchanged frozen hashes. Its commit-specific CI passed before the repository visibility changed to public. A later checkpoint verified the single-image README-preview child `f8f690d8b20be114d098c5d1dc6714071e9b94e6`, its 48-file tree, clean local and remote state, unchanged frozen evidence, and successful commit-specific CI. The private recovery repository remained clean at audited HEAD `8dbec1271de6df9776f2871bf804eebf9c2d5412` and was never published or imported.

## Frozen evidence boundary

| File | MD5 |
|---|---|
| `artifacts/phase3/final/final_model.rds` | `e4da864280d502584c8a899053193a58` |
| `artifacts/phase3/final/test_metrics.csv` | `057d92258d98ce275acc91edc240425e` |
| `artifacts/phase3/final/test_slice_audit.csv` | `2ffe9c7c551d2ffdb08aa25d04690794` |
| `artifacts/phase3/final/validation_vs_test.csv` | `d2647a8ff9eb1efc54758cefefdd8e0b` |

The tests and App use the outcome-free development demo, split manifest, frozen model, and aggregate evidence. They do not fit a new model or open row-level locked-test features, predictions, or outcomes. Generated acceptance outputs are local and excluded from Git tracking.
