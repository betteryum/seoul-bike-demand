# Reproduce Frozen Inference

## Scope

This repository reproduces the frozen 24-hour inference interface, contract checks, SQL audits, and Shiny historical replay. It does not retrain or reselect the model, download live inputs, or recompute locked-test metrics from row-level outcomes. The App uses outcome-free development inputs and committed aggregate evidence.

Use R 4.4.1 and Python 3 with the standard-library `sqlite3` module from the project root. `renv.lock` records 114 R packages. A clean restore may download packages from the configured CRAN repository; no credential or external data API is required. Before inference, the model and three aggregate evidence files are checked against their frozen MD5 values.

## Restore and accept

From an RStudio Terminal opened at the repository root, run:

```sh
Rscript --vanilla -e 'Sys.setenv(RENV_PROJECT = getwd()); source("renv/activate.R"); renv::restore(prompt = FALSE); stopifnot(isTRUE(renv::status(project = getwd())$synchronized))'
Rscript --vanilla -e 'Sys.setenv(RENV_PROJECT = getwd()); source("renv/activate.R"); source("scripts/90_phase5_acceptance.R")'
```

The restore command activates this repository's project library, restores the exact lockfile, and checks synchronization; it does not call `renv::snapshot()`. The acceptance command starts a separate clean R process, executes two SQL audits and four `testthat` groups, and verifies the model, aggregate evidence, App boundary, and prediction contract.

Local generated outputs are written to `artifacts/phase5/acceptance/checks.csv`, `acceptance.md`, and `test_log.txt`, plus a Desktop checkpoint. They are excluded from Git tracking. On a system without a Desktop directory, create `~/Desktop` before running acceptance.

Acceptance requires exactly 12/12 `PASS` and no test warnings.

## Launch the App

After restore, run from the repository root:

```sh
Rscript --vanilla -e 'Sys.setenv(RENV_PROJECT = getwd()); source("renv/activate.R"); shiny::runApp("app")'
```

The App exposes Forecast Replay, Model Performance, and Prediction Contract views. Replay dates are limited to complete development-period days and contain no outcome column. The performance page reads only committed aggregate evidence.

## Verified environments

- **macOS, R 4.4.1:** all 114 locked packages synchronized. A separate clean `Rscript --vanilla` session passed all 12 checks, both SQL audits, and all four test groups without warnings. The SQL precheck recorded Python 3.9.6 and SQLite 3.39.5.
- **Initial Ubuntu CI:** [run 45920704558](https://github.com/betteryum/seoul-bike-demand/actions/runs/45920704558) restored the lockfile without a package-cache hit and passed 12/12 at `8f311e9e0bc165689cab69150bbe1b5494ec6162`.
- **Documentation Ubuntu CI:** [run 45922044658](https://github.com/betteryum/seoul-bike-demand/actions/runs/45922044658) executed `renv::restore()`, confirmed synchronization, and passed 12/12 at `83506577ff58497b75f6ba19446e2c626504eb95`.
- **Public-release Ubuntu CI:** [run 45924701331](https://github.com/betteryum/seoul-bike-demand/actions/runs/45924701331) passed at `9aa092af07d22f3f282d64ec9c7fdaca78573792` on Ubuntu 24.04.5 with R 4.4.1. Every job step succeeded, the same 12 checks passed, and all four R test groups were warning-free.
- **README-preview Ubuntu CI:** [run 45925771208](https://github.com/betteryum/seoul-bike-demand/actions/runs/45925771208) passed at `f8f690d8b20be114d098c5d1dc6714071e9b94e6` on Ubuntu 24.04.5 with R 4.4.1. The environment synchronized, all 12 checks passed, and all four R test groups were warning-free.

Runner setup logs included external system advisories in earlier runs, but no R acceptance or `testthat` warning occurred. See [verification evidence](verification.md) for classification, history review, and exact frozen hashes.

Historical data preparation, feature engineering, resampling, and model construction are documented in `R/`. Rebuilding or refitting the historical model is intentionally outside this frozen-inference reproduction.
