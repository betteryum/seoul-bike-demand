# Data Provenance and Use

Source: Easwaramoorthy, S. (2020). *Seoul Bike Sharing Demand* [Dataset]. UCI Machine Learning Repository. DOI: [10.24432/C5F62R](https://doi.org/10.24432/C5F62R). [Dataset page](https://archive.ics.uci.edu/dataset/560/seoul+bike+sharing+demand). UCI lists the dataset under Creative Commons Attribution 4.0 International (CC BY 4.0).

The UCI record describes 8,760 hourly observations with rented-bike counts, weather, holiday, and date information. This forecasting project treats the hourly count as the target. Weather observed on a future target day cannot be used as a day-ahead feature; the frozen model uses past demand and known calendar information instead.

The eligible modeled cohort has 7,800 system-hours over 325 complete functioning days with exact 48- and 168-hour historical matches. The split manifest records eligibility and the chronological allocation. It is metadata, not a row-level locked-test outcome file.

The App's `app/data/demo_forecast_inputs.csv` contains outcome-free development-period inputs for historical replay. The three final CSV tables under `artifacts/phase3/final/` are aggregate performance evidence. The frozen `.rds` is checked by MD5 before use. Neither the App nor its public CI should read row-level locked-test features, predictions, or outcomes.

Course recovery materials, graded exercises, staff templates, and the private recovery repository history are excluded from this independent portfolio. The source dataset's license and attribution do not change those coursework boundaries.
