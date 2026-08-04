<div align="center">
  <img src="powerbi/assets/logo.png" width="70%" alt="Logo"/>
  <br><br><br><br>
  <img src="https://readme-typing-svg.demolab.com?font=Inter&weight=800&size=24&pause=1500&color=00D9D9&center=true&vCenter=true&width=1000&lines=SECURITY+DATA+ENGINEERING+%C3%97+MACHINE+LEARNING+%C3%97+BUSINESS+INTELLIGENCE;WINDOWS+TELEMETRY+%E2%86%92+AIRFLOW+%E2%86%92+POSTGRESQL+%E2%86%92+DBT+%E2%86%92+ML+%E2%86%92+POWER+BI;FROM+RAW+SECURITY+EVENTS+TO+DECISION-READY+INTELLIGENCE" alt="Typing SVG"/>
  <br>
  <img src="https://img.shields.io/badge/Python-142631?style=for-the-badge&logo=python&logoColor=white"/>
  <img src="https://img.shields.io/badge/Airflow-00D9D9?style=for-the-badge&logo=apacheairflow&logoColor=white"/>
  <img src="https://img.shields.io/badge/PostgreSQL-142631?style=for-the-badge&logo=postgresql&logoColor=white"/>
  <img src="https://img.shields.io/badge/dbt-00D9D9?style=for-the-badge&logo=dbt&logoColor=white"/>
  <img src="https://img.shields.io/badge/Scikit--learn-142631?style=for-the-badge&logo=scikitlearn&logoColor=white"/>
  <img src="https://img.shields.io/badge/Power_BI-00D9D9?style=for-the-badge&logo=powerbi&logoColor=white"/>
  <img src="https://img.shields.io/badge/Docker-142631?style=for-the-badge&logo=docker&logoColor=white"/>
  <br><br>

  <table>
    <tr>
      <td align="center"><b>SECURITY TELEMETRY</b><br><sub>Windows • Auth • Defender • USB • Network</sub></td>
      <td align="center"><b>DATA PLATFORM</b><br><sub>Airflow • PostgreSQL • dbt • Docker</sub></td>
      <td align="center"><b>DETECTION</b><br><sub>Isolation Forest • Risk Scoring</sub></td>
      <td align="center"><b>DECISION LAYER</b><br><sub>Power BI • SOC • Executive BI</sub></td>
    </tr>
  </table>
</div>

<br>

<div align="left">
  <img src="https://readme-typing-svg.demolab.com?font=Inter&weight=800&size=29&pause=999999&color=00D9D9&vCenter=true&width=520&lines=MISSION+CONTROL" alt="Mission Control"/>
  <img src="https://capsule-render.vercel.app/api?type=rect&color=00D9D9&height=2&width=330" alt="Line"/>
</div>

<br>

<table>
  <tr>
    <td width="50%" valign="top">
      <h3>The Problem</h3>
      <p>Security telemetry is naturally fragmented: operating-system events, authentication activity, endpoint signals, Defender records, USB information, and network evidence are generated independently.</p>
      <p>Without a governed analytical layer, analysts are left with large volumes of technical events but limited decision context.</p>
    </td>
    <td width="50%" valign="top">
      <h3>The Engineering Response</h3>
      <p><b>CyberSentinel Analytics</b> turns those signals into a reproducible security intelligence pipeline.</p>
      <p>Raw records are collected, validated, stored in a Bronze layer, transformed with dbt, enriched by authentication anomaly detection, published as Power BI-ready marts, and exposed through operational, SOC, ML, and executive dashboards.</p>
    </td>
  </tr>
</table>

> **Engineering Objective:** Preserve traceability from the original event to the final security indicator while keeping the platform modular enough for ingestion, analytics, ML, and reporting to evolve independently.

<br>

<div align="left">
  <img src="https://readme-typing-svg.demolab.com?font=Inter&weight=800&size=29&pause=999999&color=00D9D9&vCenter=true&width=760&lines=SYSTEM+ARCHITECTURE+%E2%80%94+END+TO+END" alt="System Architecture"/>
  <img src="https://capsule-render.vercel.app/api?type=rect&color=00D9D9&height=2&width=450" alt="Line"/>
</div>

<br>

```mermaid
flowchart LR
    subgraph S["01 · SECURITY SOURCES"]
      S1["Windows System"]
      S2["Windows Application"]
      S3["Authentication"]
      S4["Microsoft Defender"]
      S5["USB / Endpoint"]
      S6["Network / Firewall"]
      S7["Public EVTX"]
    end

    subgraph I["02 · INGESTION & CONTROL"]
      I1["Python Collectors"]
      I2["Validators"]
      I3["Metadata Enrichment"]
      I4["Quarantine / Reports"]
    end

    subgraph B["03 · POSTGRESQL BRONZE"]
      B1["Raw Security Tables"]
      B2["Collection Metadata"]
      B3["Indexes & Traceability"]
    end

    subgraph T["04 · DBT TRANSFORMATION"]
      T1["Staging / Silver"]
      T2["Intermediate"]
      T3["Warehouse Marts"]
    end

    subgraph M["05 · ML SECURITY ENGINE"]
      M1["Authentication Features"]
      M2["RobustScaler"]
      M3["Isolation Forest"]
      M4["Risk Engine"]
    end

    subgraph P["06 · SERVING & BI"]
      P1["Power BI Models"]
      P2["SOC Dashboards"]
      P3["ML Alert Analytics"]
      P4["Executive Overview"]
    end

    S --> I --> B --> T --> M --> P
    T --> P

    A["Apache Airflow · Daily 02:00"] -. orchestrates .-> I
    A -. orchestrates .-> B
    A -. orchestrates .-> T
    A -. orchestrates .-> M
```

<br>

### Architecture Contract

| Zone | What enters | Engineering responsibility | What leaves |
| :--- | :--- | :--- | :--- |
| **Sources** | Host & security telemetry | Preserve original evidence and source identity | Collectable security records |
| **Ingestion** | Local/public raw files | Validation, metadata, controlled loading | Trusted Bronze inputs |
| **Bronze** | Validated raw events | Durable PostgreSQL persistence and indexing | Traceable raw analytical data |
| **dbt** | Bronze tables | Standardization → reusable transformations → marts | Analytics-ready warehouse |
| **ML** | Authentication behavior features | Anomaly detection + security interpretation | Scores, labels, reasons, and actions |
| **Power BI** | Warehouse & ML marts | Operational, SOC, and executive decision support | Security intelligence |

<br>

<div align="left">
  <img src="https://readme-typing-svg.demolab.com?font=Inter&weight=800&size=29&pause=999999&color=00D9D9&vCenter=true&width=620&lines=AIRFLOW+ORCHESTRATION" alt="Airflow Orchestration"/>
  <img src="https://capsule-render.vercel.app/api?type=rect&color=00D9D9&height=2&width=360" alt="Line"/>
</div>

<br>

The repository defines a real Airflow DAG named `cybersentinel_security_pipeline`. It is configured for a daily 02:00 run, `max_active_runs=1`, environment validation, and retry handling.

```mermaid
flowchart TD
    A[check_environment] --> B[initialize_database_schemas_and_tables]
    B --> C[load_local_files_to_postgresql_bronze]
    C --> D[dbt_debug]
    D --> E[dbt_build_staging]
    E --> F[dbt_build_intermediate]
    F --> G[dbt_build_marts]
    G --> H[run_authentication_ml]
    H --> I[dbt_build_powerbi_models]
```

> **Note:** This order is intentional: ML never scores unmodeled raw events, and the Power BI serving models are built only after the warehouse and authentication scoring stages have completed.

<br>

<div align="left">
  <img src="https://readme-typing-svg.demolab.com?font=Inter&weight=800&size=29&pause=999999&color=00D9D9&vCenter=true&width=660&lines=DATA+MODELING+STRATEGY" alt="Data Modeling Strategy"/>
  <img src="https://capsule-render.vercel.app/api?type=rect&color=00D9D9&height=2&width=380" alt="Line"/>
</div>

<br>

| dbt Layer | Models in repository | Design role |
| :--- | :---: | :--- |
| **Staging / Silver** | 12 | Normalize source-specific structures and types |
| **Intermediate** | 1 | Build reusable security transformations |
| **Warehouse / Marts** | 22 | Facts, dimensions, and analytical security models |
| **Power BI Serving** | 1 | Stable report-facing datasets |

The warehouse is deliberately separated from the visualization layer. Power BI does not need to understand raw EVTX-style structures or reproduce cleansing logic: the semantic responsibility stays in the data platform.

```mermaid
flowchart TD
    RAW[RAW SECURITY RECORD] --> B[PostgreSQL Bronze]
    B --> S[dbt Staging / Silver]
    S --> I[dbt Intermediate Models]
    I --> W[Security Warehouse Marts]
    I --> F[Authentication Feature Mart]
    F --> ML[ML Scoring Results]
    W --> PBI[Power BI Serving Models]
    ML --> PBI
```

<br>

<div align="left">
  <img src="https://readme-typing-svg.demolab.com?font=Inter&weight=800&size=29&pause=999999&color=00D9D9&vCenter=true&width=680&lines=AUTHENTICATION+ML+ENGINE" alt="Authentication ML Engine"/>
  <img src="https://capsule-render.vercel.app/api?type=rect&color=00D9D9&height=2&width=390" alt="Line"/>
</div>

<br>

<table>
  <tr>
    <td width="33%" valign="top">
      <h3>01 · Feature Layer</h3>
      <p>Behavior is represented using authentication-window features such as:</p>
      <ul>
        <li><code>hour</code></li>
        <li><code>failed_login_count</code></li>
        <li><code>successful_login_count</code></li>
        <li><code>total_events</code></li>
        <li><code>unique_source_ips</code></li>
        <li><code>failed_login_ratio</code></li>
        <li><code>is_night_login</code></li>
        <li><code>events_per_minute</code></li>
      </ul>
    </td>
    <td width="33%" valign="top">
      <h3>02 · Detection Layer</h3>
      <p>The model uses:</p>
      <ul>
        <li><b>RobustScaler</b> → reduces sensitivity to extreme feature ranges</li>
        <li><b>Isolation Forest</b> → identifies unusual authentication behavior</li>
      </ul>
      <p>The repository uses 300 estimators and a dynamic contamination strategy.</p>
    </td>
    <td width="33%" valign="top">
      <h3>03 · Security Layer</h3>
      <p>A raw anomaly result is not the final output. The risk engine adds:</p>
      <ul>
        <li>ML anomaly score</li>
        <li>Security risk score</li>
        <li>Risk level</li>
        <li>Investigation flag</li>
        <li>Reason & Recommended action</li>
      </ul>
    </td>
  </tr>
</table>

### Scoring Contract

```text
Normal behavior                       Investigation zone
0 ─────────────────────── 69.99 │ 70.00 ───────────────────────── 100
                              ▲
                        anomaly threshold
```

The result is persisted with model metadata (`model_name`, `model_version`, `model_run_id`, `scored_at`) so the BI layer can distinguish security interpretation from model execution metadata.

<br>

<div align="left">
  <img src="https://readme-typing-svg.demolab.com?font=Inter&weight=800&size=29&pause=999999&color=00D9D9&vCenter=true&width=700&lines=POWER+BI+%E2%80%94+SECURITY+COMMAND+CENTER" alt="Power BI Command Center"/>
  <img src="https://capsule-render.vercel.app/api?type=rect&color=00D9D9&height=2&width=440" alt="Line"/>
</div>

<br>

<p align="center">
The reporting layer follows the same visual system as the platform itself: <b>deep navy surfaces, cyan/teal security accents, compact KPI cards, analyst-first navigation, and progressive drill-down from executive posture to event detail.</b>
</p>

<br>

### 01 / Global Security Overview
<p align="center"><img src="powerbi/assets/page1.jpg" width="96%"/></p>
<p align="center"><sub>Environment-wide security posture, event activity, severity, authentication behavior, and recent operational signals.</sub></p>

### 02 / Event Intelligence
<p align="center"><img src="powerbi/assets/page2.jpg" width="96%"/></p>
<p align="center"><sub>Security event volume, severity, providers, event IDs, affected machines, and detailed event exploration.</sub></p>

### 03 / Authentication Intelligence
<p align="center"><img src="powerbi/assets/page3.jpg" width="96%"/></p>
<p align="center"><sub>Successful and failed logons, users, source behavior, machines, and authentication patterns.</sub></p>

### 04 / Endpoint Intelligence
<p align="center"><img src="powerbi/assets/page4.jpg" width="96%"/></p>
<p align="center"><sub>Endpoint inventory and operational visibility across machine status, operating systems, and device context.</sub></p>

### 05 / SOC Security Monitoring
<p align="center"><img src="powerbi/assets/page5.jpg" width="96%"/></p>
<p align="center"><sub>SOC-oriented monitoring of security domains, severity, providers, ports, and temporal activity.</sub></p>

### 06 / Network Intelligence
<p align="center"><img src="powerbi/assets/page6.jpg" width="96%"/></p>
<p align="center"><sub>Connections, protocols, ports, geographic context, and network behavior.</sub></p>

### 07 / Data Quality Observatory
<p align="center"><img src="powerbi/assets/page7.jpg" width="96%"/></p>
<p align="center"><sub>Collection health, validation, source systems, pipeline status, and data-quality evolution.</sub></p>

### 08 / Executive Security Overview
<p align="center"><img src="powerbi/assets/page8.jpg" width="96%"/></p>
<p align="center"><sub>Management-level view of security score, critical activity, protected machines, risk, and security-domain exposure.</sub></p>

### 09 / Security Reporting
<p align="center"><img src="powerbi/assets/page9.jpg" width="96%"/></p>
<p align="center"><sub>Reporting-period consolidation of high-level indicators, activity trends, and supporting security detail.</sub></p>

### 10 / ML Alert Intelligence
<p align="center"><img src="powerbi/assets/page10.jpg" width="96%"/></p>
<p align="center"><sub>Authentication anomaly investigation combining ML score, security risk, user behavior, and analyst-ready context.</sub></p>

<br>

<div align="left">
  <img src="https://readme-typing-svg.demolab.com?font=Inter&weight=800&size=29&pause=999999&color=00D9D9&vCenter=true&width=620&lines=ENGINEERING+PRINCIPLES" alt="Engineering Principles"/>
  <img src="https://capsule-render.vercel.app/api?type=rect&color=00D9D9&height=2&width=360" alt="Line"/>
</div>

<br>

<table>
  <tr>
    <td align="center"><b>TRACEABILITY</b><br><sub>Source → Bronze → dbt → mart → score → dashboard</sub></td>
    <td align="center"><b>SEPARATION OF CONCERNS</b><br><sub>Collection, storage, transformation, ML, and BI remain modular</sub></td>
  </tr>
  <tr>
    <td align="center"><b>REPRODUCIBILITY</b><br><sub>Docker Compose + explicit SQL initialization + Airflow orchestration</sub></td>
    <td align="center"><b>DECISION CONTEXT</b><br><sub>ML output is enriched with risk, reason, and recommended action</sub></td>
  </tr>
  <tr>
    <td align="center"><b>DATA QUALITY</b><br><sub>Validation and quality are part of the platform, not an afterthought</sub></td>
    <td align="center"><b>BI-READY MODELING</b><br><sub>Power BI consumes dedicated serving models instead of raw telemetry</sub></td>
  </tr>
</table>

<br>

<div align="left">
  <img src="https://readme-typing-svg.demolab.com?font=Inter&weight=800&size=29&pause=999999&color=00D9D9&vCenter=true&width=580&lines=RUNTIME+TOPOLOGY" alt="Runtime Topology"/>
  <img src="https://capsule-render.vercel.app/api?type=rect&color=00D9D9&height=2&width=340" alt="Line"/>
</div>

<br>

```mermaid
flowchart TB
    U["Engineer / Analyst"] --> AW["Airflow Webserver :8080"]
    AW --> AS["Airflow Scheduler"]
    AS --> DAG["CyberSentinel DAG"]

    DAG --> PG["cybersentinel-postgres :5432"]
    DAG --> DBT["dbt Project"]
    DAG --> ML["Authentication ML Package"]

    APG["airflow-postgres"] --> AW
    APG --> AS

    PG --> PBI["Power BI"]

    subgraph Docker["Docker Compose · cyber_network"]
      AW
      AS
      APG
      PG
    end
```

> The Compose stack separates the CyberSentinel analytical PostgreSQL database from the Airflow metadata PostgreSQL database, while the Airflow webserver and scheduler share the project mounts required to execute SQL, dbt, and ML workloads.

<br>

<div align="left">
  <img src="https://readme-typing-svg.demolab.com?font=Inter&weight=800&size=29&pause=999999&color=00D9D9&vCenter=true&width=520&lines=TECHNOLOGY+MAP" alt="Technology Map"/>
  <img src="https://capsule-render.vercel.app/api?type=rect&color=00D9D9&height=2&width=310" alt="Line"/>
</div>

<br>

| Domain | Technology | Responsibility |
| :--- | :--- | :--- |
| **Collection & Engineering** | Python | ingestion, validation, metadata, loading |
| **Orchestration** | Apache Airflow | ordered execution, retries, scheduling |
| **Persistence** | PostgreSQL 16 | Bronze, warehouse, and ML persistence |
| **Transformation** | dbt + SQL | staging, intermediate, marts, and Power BI models |
| **Machine Learning** | scikit-learn | RobustScaler + Isolation Forest |
| **Security Interpretation**| Python risk engine | risk level, investigation decision, reason, action |
| **Analytics** | Power BI | SOC, operational, ML, and executive reporting |
| **Runtime** | Docker Compose | reproducible local service topology |
| **Versioning** | Git / GitHub | source control and project distribution |

<br>

<div align="left">
  <img src="https://readme-typing-svg.demolab.com?font=Inter&weight=800&size=29&pause=999999&color=00D9D9&vCenter=true&width=560&lines=REPOSITORY+MAP" alt="Repository Map"/>
  <img src="https://capsule-render.vercel.app/api?type=rect&color=00D9D9&height=2&width=330" alt="Line"/>
</div>

<br>

```text
cybersentinel-analytics/
│
├── airflow/
│   ├── dags/                    # production pipeline orchestration
│   ├── logs/                    # Airflow execution history
│   └── plugins/
│
├── cybersentinel_auth_ml/       # authentication anomaly-detection package
│   ├── config.py
│   ├── database.py
│   ├── data_loader.py
│   ├── feature_engineering.py
│   ├── ml_model.py
│   ├── risk_engine.py
│   ├── repository.py
│   ├── reporting.py
│   ├── metadata.py
│   ├── pipeline.py
│   └── main.py
│
├── data/
│   ├── raw/
│   │   ├── local/               # local PC security telemetry
│   │   └── public_evtx/         # public EVTX datasets
│   ├── quarantine/
│   └── reports/
│
├── dbt/
│   ├── models/
│   │   ├── staging/             # source normalization / Silver layer
│   │   ├── intermediate/        # reusable transformations
│   │   └── marts/
│   │       └── powerbi/         # report-facing serving models
│   ├── macros/
│   ├── dbt_project.yml
│   └── profiles.yml
│
├── ingestion/                    # validators, metadata and PostgreSQL loader
├── scripts/                      # Bronze loading entry point
├── sql/                          # schemas, raw tables, indexes and ML tables
├── powerbi/
│   └── assets/                   # CyberSentinel dashboard gallery
├── docker/
│   └── airflow/                  # custom Airflow runtime image
├── tests/
├── docker-compose.yml
├── requirements.txt
└── README.md
```

<br>

<div align="left">
  <img src="https://readme-typing-svg.demolab.com?font=Inter&weight=800&size=29&pause=999999&color=00D9D9&vCenter=true&width=470&lines=RUN+THE+STACK" alt="Run the Stack"/>
  <img src="https://capsule-render.vercel.app/api?type=rect&color=00D9D9&height=2&width=290" alt="Line"/>
</div>

<br>

Keep credentials outside Git. The repository uses environment variables and a local `.env`; do not publish real database or Airflow credentials.

<div align="center">
  <img src="powerbi/assets/terminal-setup.svg" width="90%" alt="Terminal Setup Execution">
</div>

```bash
docker compose down
docker compose build --no-cache airflow-init airflow-webserver airflow-scheduler
docker compose up -d
```

Open the Airflow environment and validate dbt:

```bash
docker exec -it cybersentinel-airflow-scheduler bash
dbt debug --profiles-dir dbt --target dev
```

<br>

<div align="left">
  <img src="https://readme-typing-svg.demolab.com?font=Inter&weight=800&size=29&pause=999999&color=00D9D9&vCenter=true&width=620&lines=WHY+CYBERSENTINEL" alt="Why CyberSentinel"/>
  <img src="https://capsule-render.vercel.app/api?type=rect&color=00D9D9&height=2&width=350" alt="Line"/>
</div>

<br>

<div align="center">

This is not a collection of disconnected dashboards. <br>
<b>CyberSentinel Analytics is a security data product.</b>

<i>Security Telemetry → Data Engineering → Warehouse Modeling → Machine Learning → Risk Context → Decision Intelligence</i>

The value of the project is the connection between those layers: an authentication event can move from raw evidence to a modeled behavioral feature, become an anomaly score, receive a security interpretation, and finally appear inside an analyst-facing Power BI investigation workflow.

</div>

<br>

<div align="center">

<img src="https://readme-typing-svg.demolab.com?font=Inter&weight=800&size=22&pause=2200&color=00D9D9&center=true&vCenter=true&width=1000&lines=ENGINEERED+FOR+TRACEABILITY.+BUILT+FOR+SECURITY+ANALYTICS.;FROM+EVENT+COLLECTION+TO+EXECUTIVE+DECISION+SUPPORT.;CYBERSENTINEL+ANALYTICS+%E2%80%94+TURNING+SECURITY+DATA+INTO+CONTEXT." alt="Footer Typing SVG"/>

<br><br>

<h2>CHARAF SOUBI</h2>

<p><b>Data Analytics • Data Engineering • Business Intelligence • Cybersecurity Analytics</b></p>

<a href="https://soubicharaf.netlify.app/"><img src="https://img.shields.io/badge/PORTFOLIO-142631?style=for-the-badge&logo=googlechrome&logoColor=white"/></a><a href="https://github.com/charaf12-u"><img src="https://img.shields.io/badge/GITHUB-142631?style=for-the-badge&logo=github&logoColor=white"/></a><a href="https://www.linkedin.com/in/charaf-soubi/"><img src="https://img.shields.io/badge/LINKEDIN-142631?style=for-the-badge&logo=linkedin&logoColor=white"/></a><a href="mailto:soubicharaf@gmail.com"><img src="https://img.shields.io/badge/GMAIL-142631?style=for-the-badge&logo=gmail&logoColor=white"/></a>

<br><br>

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:142631,100:00D9D9&height=105&section=footer" alt="Wave Footer"/>

</div>
