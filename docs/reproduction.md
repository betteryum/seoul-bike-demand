# Reproduce Frozen Inference

## Scope

This repository reproduces the frozen 24-hour inference interface and its contract checks. It does not retrain or reselect the model, download live inputs, or recompute locked-test metrics from row-level outcomes. The App replays outcome-free development inputs and displays committed aggregate evidence.

Use R 4.4.1 and Python 3 with the standard-library `sqlite3` module from the project root. `renv.lock` records 114 R packages. A clean restore may download packages from the configured CRAN repository; no credentials or external data API are needed. The frozen model and three aggregate CSV files are checked against recorded MD5 values before inference.

## Restore and accept

In RStudio Terminal at the root of this independent repository, run each complete command:

```sh
Rscript --vanilla -e 'Sys.setenv(RENV_PROJECT = getwd()); source("renv/activate.R"); renv::restore(prompt = FALSE); stopifnot(isTRUE(renv::status(project = getwd())$synchronized))'
Rscript --vanilla -e 'Sys.setenv(RENV_PROJECT = getwd()); source("renv/activate.R"); source("scripts/90_phase5_acceptance.R")'
```

The first command activates this project's package library explicitly, restores the exact lockfile, and checks synchronization. It does not call `renv::snapshot()`. The second starts a separate clean R session, runs four `testthat` groups including frozen-model integration, and checks the model, aggregate evidence, App access boundary, prediction contract, and two SQL audits. It writes `artifacts/phase5/acceptance/checks.csv`, `acceptance.md`, and `test_log.txt`, plus a Desktop checkpoint. On systems without a Desktop directory, create `~/Desktop` before the second command.

Acceptance requires 12/12 `PASS` with no warnings. A failing check stops the command and records the detail in the checkpoint. Run the App separately from the project root with `shiny::runApp("app")` in the activated RStudio session.

## Verified status

- On macOS with R 4.4.1, a restore into this independent staging project's `renv/library` synchronized all 114 locked packages. Restore runtime was 10.7 seconds, mostly using the local package cache; that timing does not estimate a first download.
- After the SQL extension, a separate `Rscript --vanilla` invocation with explicit staging activation passed all 12 checks with zero warnings. The installer checkpoint recorded 8.37 seconds for preflight, the standalone SQL audits, and the clean-session acceptance together. The Mac SQL precheck reported Python 3.9.6 and SQLite 3.39.5.
- The frozen model and three aggregate evidence hashes were unchanged. The App and tests accessed no row-level locked-test files.
- The first independent GitHub Actions [run 45920704558](https://github.com/betteryum/seoul-bike-demand/actions/runs/45920704558), on commit `8f311e9e0bc165689cab69150bbe1b5494ec6162`, passed on Ubuntu 24.04.5 with R 4.4.1. The runner had no package-cache hit, restored the locked environment, reported `renv::status()` synchronized, and passed all 12 acceptance checks with no R test warnings. See [verification evidence](verification.md) for versions, timings, and log classification.
- The documentation commit passed GitHub Actions [run 45922044658](https://github.com/betteryum/seoul-bike-demand/actions/runs/45922044658) at `83506577ff58497b75f6ba19446e2c626504eb95`. The Ubuntu 24.04.5 runner restored the existing cache, still executed `renv::restore()`, confirmed synchronization, and passed the same 12 checks in 3.88 seconds. Two `gdebi` Python `SyntaxWarning` lines, a `libx11-dev` setup advisory, and a temporary Git branch-name hint came from runner setup; the R acceptance and four `testthat` groups produced no warnings or errors.

These recorded results establish local staging and two independent CI reproductions. Every later commit must pass its own CI run before public release. Historical raw-data preparation is documented in the R functions, but rebuilding and refitting the historical model are outside this frozen inference reproduction.
