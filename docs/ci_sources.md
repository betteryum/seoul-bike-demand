# Independent CI Scope and Sources

The workflow verifies the frozen day-ahead inference contract without retraining, reselecting, or opening row-level locked-test files. Four audited runs establish the independent repository baseline, public release, and README preview:

| Run | Commit | Repository state | Result |
|---|---|---|---|
| [45920704558](https://github.com/betteryum/seoul-bike-demand/actions/runs/45920704558) | `8f311e9e0bc165689cab69150bbe1b5494ec6162` | Initial private commit | SUCCESS; cold restore; 12/12 PASS |
| [45922044658](https://github.com/betteryum/seoul-bike-demand/actions/runs/45922044658) | `83506577ff58497b75f6ba19446e2c626504eb95` | Documentation commit | SUCCESS; restored cache; 12/12 PASS |
| [45924701331](https://github.com/betteryum/seoul-bike-demand/actions/runs/45924701331) | `9aa092af07d22f3f282d64ec9c7fdaca78573792` | Public-release commit | SUCCESS; synchronized environment; 12/12 PASS |
| [45925771208](https://github.com/betteryum/seoul-bike-demand/actions/runs/45925771208) | `f8f690d8b20be114d098c5d1dc6714071e9b94e6` | README Shiny preview commit | SUCCESS; synchronized environment; 12/12 PASS |

Local clean-session acceptance also passed on macOS R 4.4.1. For later commits, the workflow badge and the commit-specific Actions result remain the acceptance gate.

## First-party references

- [GitHub Actions workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax): events, job settings, and read-only `contents` permission.
- [actions/checkout](https://github.com/actions/checkout): exact sparse checkout with non-cone mode, shallow fetch, and disabled credential persistence.
- [r-lib/actions](https://github.com/r-lib/actions): `setup-r@v2` and `setup-renv@v2` for the R version and packages recorded in `renv.lock`.
- [renv CI guidance](https://rstudio.github.io/renv/articles/ci.html): restoring committed package versions in GitHub Actions.
- [testthat directory tests](https://testthat.r-lib.org/reference/test_dir.html): running the four test groups from a non-package project.
- [Python sqlite3](https://docs.python.org/3/library/sqlite3.html): in-memory SQLite execution without an external database or Python packages.
- [SQLite date functions](https://www.sqlite.org/lang_datefunc.html): issue-date checks in the development-only SQL audit.
- [GitHub Ubuntu runner image](https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2404-Readme.md): Python 3 and SQLite availability on the selected runner image.

## Access boundary

The workflow checks out only explicit source paths, outcome-free development demo inputs, SQL audit scripts, the split manifest, the frozen model, aggregate performance evidence, dependency metadata, and tests. Before dependency restoration it rejects private course directories, row-level locked-test files, test-access markers, and common credential files.

The tests do not train, select, or evaluate a new model and do not deploy the App. The SQL audit uses an in-memory synthetic exact-lag fixture and the development-only demo. The App and CI never load row-level locked-test features, predictions, or outcomes.

Sparse checkout is a runtime boundary, not a substitute for history review. The separate pre-publication audit covered both independent commits through `83506577ff58497b75f6ba19446e2c626504eb95`, all 47 then-existing historical paths, tracked source, documentation, dependency metadata, links, frozen artifacts, aggregate evidence, and model strings. The release checkpoint then verified the documentation-only child commit, unchanged frozen hashes, a 47-file tree, successful public-release CI, and an unchanged private recovery repository before visibility changed. The later README-preview checkpoint verified its single-image child commit, a 48-file tree, unchanged frozen evidence, synchronized `origin/main`, clean portfolio and recovery worktrees, and successful commit-specific CI.
