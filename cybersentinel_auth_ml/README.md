# CyberSentinel Authentication ML

This package reads dbt-generated authentication features from PostgreSQL, scores them with Isolation Forest, applies explainable security-risk rules, and upserts the results into PostgreSQL for Power BI.

## Input

`warehouse.ml_authentication_features`

## Output

`ml.authentication_anomaly_scores`

## Run from the project root

```bash
python -m cybersentinel_auth_ml.main
```

The `.env` file supplies PostgreSQL credentials. Inside Docker, use `POSTGRES_HOST=postgres`; outside Docker, use `POSTGRES_HOST=localhost`.
