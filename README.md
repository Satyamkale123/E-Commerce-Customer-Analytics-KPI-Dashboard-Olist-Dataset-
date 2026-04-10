E-Commerce Customer Analytics (Olist Dataset)
End-to-End Data Engineering, Analytics & Machine Learning Project on Google Cloud Platform (GCP)
SQL BigQuery Python Cloud Composer Cloud Run Cloud Storage Power BI XGBoost Scikit-learn

🌟 Project Summary
This project builds a complete cloud-based analytics and machine learning pipeline to help an e-commerce business understand:

Customer retention & churn patterns
Repeat purchase behavior (cohorts)
Customer value using RFM segmentation
Revenue & order trends
High-value vs at-risk customers
Churn prediction using supervised ML models (Logistic Regression, Random Forest, XGBoost)

Using GCP services, SQL modeling, Python processing, Machine Learning, and Power BI dashboards, I built a production-ready analytics workflow from raw data → insights → predictions.

🚀 Architecture (GCP)
Raw CSVs → Cloud Storage → BigQuery (SQL Models) → Cloud Composer (Orchestration)
→ Cloud Run (Python RFM/Cohort/ML jobs) → Power BI Dashboards
ComponentPurposeCloud StorageRaw data landing zone & processed exportsBigQueryData warehouse, cohort models, RFM scoringCloud Composer (Airflow)Scheduled SQL & ETL orchestrationCloud RunPython scripts for RFM, cohort enrichment & ML inferencePower BIDashboards & business insightsCloud MonitoringPipeline health monitoring & alerts

🤖 Machine Learning — Churn Prediction
Problem Statement
Identify customers at risk of churning — defined as no purchase in the last 60 days — so the business can proactively run re-engagement campaigns.
Features Engineered
FeatureDescriptionrecency_daysDays since last purchasetotal_ordersTotal number of orders placednum_months_activeNumber of months customer was activetenure_daysDays between first and last purchaseavg_orders_per_monthAverage order frequency per active month
Models Trained
ModelROC-AUCRecallNotesLogistic RegressionBaselineBaselineSimple interpretable baselineRandom ForestBetterBetterEnsemble, feature importanceXGBoost (Tuned)BestBest~15% recall improvement after hyperparameter tuning
Key Results

XGBoost with GridSearchCV hyperparameter tuning achieved the best recall for high-risk churn segment
~15% recall improvement compared to base XGBoost model
Evaluated using ROC-AUC, Precision-Recall curves, F1-score, Confusion Matrix
Recency was identified as the most important feature

Key Business Insights from ML

Churn risk spikes sharply after 2 months of inactivity
Top 20% of customers (Champions + Loyal) drive majority of revenue
Customers with low purchase frequency are significantly more likely to churn
At-risk customers should be targeted with re-engagement campaigns within 45 days

Notebook
📓 churn_prediction.ipynb

📊 Dashboards (Power BI)
1️⃣ Executive KPI Dashboard

Total Orders, Total Customers, Total Revenue
Monthly revenue & order trends

2️⃣ Customer Cohort Retention Dashboard

Cohort Heatmap
Retention trend line
Cohort size by month
Repeat customer rate KPI

3️⃣ RFM Segmentation Dashboard

Segment distribution (Champions, Loyal, At-Risk, Lost)
Monetary vs Frequency scatter
Recency distribution histogram
High-value vs low-value quadrant


🛠️ Tech Stack
Google Cloud Platform

BigQuery, Cloud Storage, Cloud Composer (Airflow), Cloud Run, Cloud Monitoring, IAM Roles

Machine Learning

XGBoost, Scikit-learn (Logistic Regression, Random Forest)
GridSearchCV for hyperparameter tuning
Evaluation: ROC-AUC, Precision, Recall, F1-score, Confusion Matrix

Data Engineering

SQL (BigQuery Standard SQL), Python (Pandas, NumPy), ETL pipelines
Data modeling (Star schema views, cohort tables, RFM tables)

Visualization

Power BI, DAX measures, KPI cards, heatmaps, scatter plots


🧠 Features Implemented
Customer Cohort Analysis

First purchase month as cohort index
Month-over-month retention tracking
Customer lifecycle decay patterns
Identified churn window (2–3 months)

RFM Segmentation

Recency, Frequency, Monetary scoring (1–5 quantile based)
Segments: ⭐ Champions | ❤️ Loyal | 🔍 Potential Loyalists | ⚠️ At Risk | ❌ Lost

Churn Prediction (ML)

Supervised binary classification
Feature engineering from cohort data
Model comparison and hyperparameter tuning
Business-ready insights for retention strategy


🏗️ Project Structure
e-commerce-customer-analytics-olist/
│
├── data/                    # Sample CSVs (100 records)
├── sql/                     # BigQuery SQL models & views
├── python/
│   ├── churn_prediction.ipynb   # ML churn prediction notebook ← NEW
│   └── rfm_cohort_jobs.py       # RFM and cohort Python jobs
├── dashboards/              # PNG exports of Power BI dashboards
├── powerbi/                 # PBIX file
├── docs/                    # Architecture diagram, notes
└── README.md

⚙️ How the Pipeline Works

Cloud Storage → Raw Olist CSVs uploaded to GCS bucket
BigQuery → SQL transformations for cohort, RFM, and order summary tables
Cloud Composer (Airflow) → Orchestrates load → transform → ML inference → export
Cloud Run → Python scripts for RFM scoring, cohort enrichment, and churn prediction
Power BI → Connected to BigQuery, 3 dashboards with exported PNGs


📈 Results & Impact

Built cloud-scale analytics system handling 1M+ e-commerce records
Identified churn window at 2-3 months enabling proactive retention campaigns
XGBoost churn model improved high-risk recall by ~15% through hyperparameter tuning
Automated end-to-end pipeline with orchestration, monitoring, and ML inference
Designed professional dashboards for executive and marketing decision-making
