# Independent CI Scope and Sources

This workflow checks the frozen day-ahead inference contract in the independent repository. The first private [GitHub Actions run](https://github.com/betteryum/seoul-bike-demand/actions/runs/45920704558) passed at commit `8f311e9e0bc165689cab69150bbe1b5494ec6162`: locked package restore, synchronized `renv`, SQL audit, and 12 acceptance checks. The documentation commit then passed [run 45922044658](https://github.com/betteryum/seoul-bike-demand/actions/runs/45922044658) at `83506577ff58497b75f6ba19446e2c626504eb95`. Local clean-session acceptance also passed on macOS R 4.4.1. The workflow badge and current Actions result are the release gate for later commits.

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

Only explicit source paths, outcome-free development demo inputs, SQL audit scripts, the split manifest, the frozen model artifact, and aggregate performance evidence are checked out. The CI job checks for private course materials, row-level locked-test files, test-access markers, and common secret files before restoring dependencies. The tests do not train, select, or evaluate a new model and do not deploy the App. The SQL audit uses an in-memory synthetic exact-lag fixture and the development-only demo; it does not load locked-test rows.

The sparse working tree is a runtime boundary, not a publication audit of Git history. A separate pre-publication review audited both independent commits through `83506577ff58497b75f6ba19446e2c626504eb95`, all 47 historical paths, tracked source, documentation, dependency metadata, links, and frozen hashes. It found no recovery history, course prompts or solutions, row-level locked-test files, credentials, API keys, or local user paths. Later release-only documentation changes remain subject to their own CI run before visibility changes.
