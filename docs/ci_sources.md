# Independent CI Scope and Sources

This workflow checks the frozen day-ahead inference contract in a future independent repository. The workflow is a staged candidate until that repository has been audited, committed, and run successfully. A local clean R session passed 12 acceptance checks on macOS R 4.4.1, including the SQL audit; this is not a claim of GitHub Actions success.

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

The sparse working tree is a runtime boundary, not a publication audit of Git history. Before any repository becomes public, its entire independent history and committed contents must pass a separate source and secret review. No recovery repository history may be imported.
