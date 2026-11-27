# Reproduction and Verification Evidence

## Independent CI baseline

The first private-repository [GitHub Actions run 45920704558](https://github.com/betteryum/seoul-bike-demand/actions/runs/45920704558) completed successfully for the initial independent commit `8f311e9e0bc165689cab69150bbe1b5494ec6162` on `main`. The repository was created with one new root commit; no private recovery history was imported. This record describes that commit. Later commits require their own successful CI run.

| Check | Observed evidence |
|---|---|
| Runner | Ubuntu 24.04.5 LTS, x86-64; R 4.4.1 |
| Dependencies | No initial package-cache hit; 114 packages in `renv.lock`; `renv::status()` reported synchronized |
| Acceptance | `source("scripts/90_phase5_acceptance.R")`; 12/12 PASS; 3.88 seconds |
| Test suite | Four `testthat` groups passed without warnings; `testthat` 3.2.3 |
| SQL | Synthetic exact-lag fixture and 6,792-row outcome-free development demo audit passed |
| Frozen inference | Model loaded; complete 24-hour schema and nonnegative finite predictions verified |
| Boundaries | Restricted files absent in sparse checkout; App source contains no row-level locked-test reference |

The package restore action took about 75.8 seconds; the whole job ran about 125 seconds. The run log reports `renv` 1.1.4, `ranger` 0.17.0, `parsnip` 1.4.1, and `workflows` 1.3.0. `renv.lock` is the complete dependency version record.

The test output contained no warnings or errors. Checkout printed a Git hint about the default name of its temporary initialization branch; it subsequently checked out this repository's `main`. This is a runner advisory, with no effect on the project branch or test result. Post-job cache save succeeded.

## Documentation commit verification

The private-repository [GitHub Actions run 45922044658](https://github.com/betteryum/seoul-bike-demand/actions/runs/45922044658) completed successfully for documentation commit `83506577ff58497b75f6ba19446e2c626504eb95` on `main`.

| Check | Observed evidence |
|---|---|
| Runner | Ubuntu 24.04.5 LTS, x86-64; R 4.4.1 |
| Dependencies | Existing package-cache hit; `renv::restore()` executed; `renv::status()` reported synchronized |
| Acceptance | 12/12 PASS; 3.88 seconds; four `testthat` groups passed without warnings |
| Frozen evidence | Model and three aggregate evidence MD5 values matched exactly |
| Boundaries | Restricted files absent; no row-level locked-test access; no model refit or selection |

Runner setup printed two Python `SyntaxWarning` lines from Ubuntu's `gdebi`, a system-package advisory that `libx11-dev` was not installed for the unrelated `clipr` package, and a Git hint about the temporary initialization branch. These were not R or test warnings: the restored project was synchronized, every acceptance check passed, and every job step concluded successfully.

## Local clean-session evidence

On macOS with R 4.4.1, the independent staging project's restored library synchronized with the 114-package lockfile. Restore took 10.7 seconds, mostly linking an existing local package cache. A separate `Rscript --vanilla` invocation with explicit staging activation passed all 12 acceptance checks and the two SQL audits with zero warnings. The installation checkpoint's 8.37-second runtime includes its preflight, standalone SQL audit, and clean-session acceptance. The SQL precheck recorded Python 3.9.6 and SQLite 3.39.5.

## Pre-publication history audit

The independent history through `83506577ff58497b75f6ba19446e2c626504eb95` contains exactly two commits and 47 historical paths. The audit covered both complete commit trees, all tracked source and documentation, the lockfile, workflow, links, frozen artifacts, aggregate evidence, and model strings. It found no imported recovery history, course prompt or answer files, row-level locked-test features, predictions or outcomes, credentials, API keys, or local user paths. The repository owner accepted publication of the existing commit author metadata.

## Frozen evidence boundary

| File | MD5 |
|---|---|
| `artifacts/phase3/final/final_model.rds` | `e4da864280d502584c8a899053193a58` |
| `artifacts/phase3/final/test_metrics.csv` | `057d92258d98ce275acc91edc240425e` |
| `artifacts/phase3/final/test_slice_audit.csv` | `2ffe9c7c551d2ffdb08aa25d04690794` |
| `artifacts/phase3/final/validation_vs_test.csv` | `d2647a8ff9eb1efc54758cefefdd8e0b` |

The tests and CI use the outcome-free development demo, split manifest, frozen model, and aggregate metrics. They do not open row-level locked-test features, predictions, or outcomes; they do not fit a new model. Generated acceptance CSV, Markdown, and test log are local outputs excluded from Git tracking. The committed workflow and its logs provide the public CI evidence after release.
