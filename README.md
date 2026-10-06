# Email Guard

### Bayesian email spam detection, made explainable

An interactive **R + Shiny** mini project that classifies email as **SPAM** or **HAM** and shows the probability calculations behind the decision.

![R](https://img.shields.io/badge/R-4.6.1%2B-276DC3?logo=r&logoColor=white)
![Shiny](https://img.shields.io/badge/interface-Shiny-75AADB)
![Models](https://img.shields.io/badge/models-Manual%20Bayes%20%2B%20e1071-267A68)

> **Academic demonstration only.** The included emails are fictional and template-generated. This project is not a production spam filter and must not be used for real security decisions.

## At a glance

- Enter an email and compare its SPAM and HAM probabilities.
- Inspect learned word likelihoods and a step-by-step manual Bayes calculation.
- Compare a hand-built multinomial model with `e1071::naiveBayes()`.
- Explore the dataset, confusion matrix, test metrics, and in-session prediction history.
- Reproduce the training split and results with a fixed random seed.

## Run it

Use **R 4.6.1 or later** and the VS Code **R** extension. Open this repository as the workspace, start an R terminal with **R: Create R Terminal**, and install the packages once:

```r
install.packages(c(
	"shiny", "shinydashboard", "dplyr", "stringr", "tm",
	"e1071", "ggplot2", "plotly", "DT"
))
```

From the project root, train and save the models:

```r
source("train.R")
```

Launch the dashboard:

```r
shiny::runApp()
```

The app opens in your browser. It also trains the models at startup and refreshes `models/naive_bayes_model.rds`.

## Deploy on Render

This project uses a **Docker web service** because Render's native language runtimes do not include R. The repository includes a `Dockerfile`, `.dockerignore`, and `render.yaml` Blueprint. The container installs the required R packages, launches Shiny on `0.0.0.0`, and reads the port supplied by Render through `PORT` (defaulting locally to `10000`). No secrets or external services are required.

### Blueprint deployment (recommended)

1. Push the project, including `Dockerfile` and `render.yaml`, to the repository's `main` branch.
2. Sign in to [Render](https://dashboard.render.com/) and choose **New + → Blueprint**.
3. Connect GitHub if prompted, then select `Shantanu-Jambhale/Email-Guard` and the `main` branch.
4. Render detects `render.yaml`. Review the service named `email-guard` and click **Apply**.
5. Open the service's **Events** or **Logs** page. Wait for the Docker build and first deploy to finish.
6. Open the `onrender.com` URL Render assigns to the service.

The Blueprint uses the Free web-service plan in Oregon, deploys from `main`, and checks `/` for health. Change the plan or region in `render.yaml` before applying if needed.

### Dashboard setup instead

If you prefer not to use a Blueprint, select **New + → Web Service**, connect this GitHub repository, and set:

| Setting | Value |
|---|---|
| Branch | `main` |
| Language / Runtime | Docker |
| Dockerfile path | `./Dockerfile` |
| Docker build context | `.` (repository root) |
| Docker command | Leave blank; use the Dockerfile `CMD` |
| Health check path | `/` |
| Plan | Free for a classroom demo, or choose a paid plan |

You do not need to enter a build command, start command, or environment variable. Render provides `PORT`; the container binds Shiny to that port on `0.0.0.0`, as required for Render web services.

### Deploy behavior and troubleshooting

- The first deploy takes longer because Docker installs R packages. Later builds can reuse cached layers.
- If startup fails, check the service's deploy logs for package installation errors, then its runtime logs for R/Shiny errors.
- Confirm the service is configured as a **Web Service** using the Docker runtime, not as a static site.
- Render's Free services can spin down when idle, so the first visit after inactivity may take longer. A paid plan avoids the free-instance sleep behavior.
- This app trains from `data/spam_dataset.csv` on startup. Its saved RDS model and prediction history are ephemeral; the app regenerates the model on restart, and history is intentionally limited to a live Shiny session. No persistent disk is needed for this demo.
- You do not need Docker Desktop to deploy through Render; Render builds the image from the repository. For local image builds, install Docker Desktop and run `docker build -t email-guard .` followed by `docker run --rm -p 10000:10000 -e PORT=10000 email-guard`.

## Try a message

**SPAM sample**

> Congratulations! You have won a free cash prize. Click now to claim your reward!

**HAM sample**

> Hello team, our project meeting has been scheduled for tomorrow at 10 AM. Please bring your report.

The dashboard includes buttons that load these examples for quick testing.

## How the classifier works

```mermaid
flowchart TD
		A[Email message] --> B[Clean and tokenize]
		B --> C[Bag-of-words features]
		C --> D[Manual Bayes: priors and smoothed likelihoods]
		C --> E[e1071 Naive Bayes]
		D --> F[SPAM and HAM posteriors]
		E --> G[Model comparison]
		F --> H[Prediction, evidence, and history]
		G --> H
```

For class $C$ and observed word $w$, Bayes' theorem is:

$$P(C \mid w)=\frac{P(w \mid C)P(C)}{P(w)}$$

For a message with words $w_1,\ldots,w_n$, Naive Bayes uses the conditional-independence assumption:

$$P(C \mid w_1,\ldots,w_n) \propto P(C)\prod_{i=1}^{n}P(w_i \mid C)$$

The manual model uses a multinomial word-count likelihood with Laplace smoothing:

$$P(w \mid C)=\frac{\operatorname{count}(w,C)+1}{\operatorname{totalTokens}(C)+|V|}$$

It adds log probabilities instead of multiplying many tiny values, then normalizes the SPAM and HAM scores into posteriors that sum to 100%. The `e1071` comparison uses binary word-presence features; the manual model uses word counts, so the feature representations are intentionally different.

### Text preparation

The shared `clean_text()` function lowercases text; removes HTML, URLs, email addresses, punctuation, and numbers; collapses whitespace; and removes English stopwords. `tm::DocumentTermMatrix()` creates the training feature matrix. Vocabulary selection and sparse-term filtering use training data only.

## Dataset and evaluation

`data/spam_dataset.csv` contains 500 fictional examples: **300 SPAM** and **200 HAM**. The seeded training pipeline uses an 80/20 stratified split, so the held-out test set contains 100 messages. Seed `123` makes the split reproducible.

| Model | Accuracy | Precision (SPAM) | Recall (SPAM) | F1 |
|---|---:|---:|---:|---:|
| Manual Bayes | 100.00% | 100.00% | 100.00% | 100.00% |
| e1071 Naive Bayes | 100.00% | 100.00% | 100.00% | 100.00% |

These values are calculated from actual predictions on the fixed test split. The manual model's confusion matrix is **TP 60, FN 0, FP 0, TN 40**. The perfect scores are expected for this small, template-generated dataset, whose vocabulary makes the classes unusually easy to distinguish. They do **not** estimate performance on natural email.

## Dashboard pages

| Page | What you can inspect |
|---|---|
| Home | Project overview, learned class prior, and vocabulary size |
| Spam Detector | Prediction, both posteriors, confidence, influential words, and model comparison |
| Bayes Calculation | Priors, detected words, conditional probabilities, log scores, and normalized result |
| Dataset | Class counts, distribution chart, and searchable messages |
| Model Performance | Calculated metrics, confusion matrix, and model comparison |
| Prediction History | Current-session predictions with a clear-history action |
| About | Method and limitations |

## Project layout

```text
.
├── app.R
├── Dockerfile
├── .dockerignore
├── render.yaml
├── train.R
├── spam_dataset.csv
├── data/
│   └── spam_dataset.csv
├── R/
│   ├── generate_dataset.R
│   ├── preprocessing.R
│   ├── manual_bayes.R
│   ├── train_model.R
│   ├── evaluation.R
│   └── prediction.R
├── models/
│   ├── naive_bayes_model.rds
│   ├── model_metrics.csv
│   └── manual_confusion_matrix.csv
├── tests/
│   ├── test_pipeline.R
│   └── test_app.R
├── www/
│   ├── style.css
│   └── custom.js
├── PROJECT_REPORT.md
└── PRESENTATION.md
```

## Test the project

Run in an R terminal from the repository root:

```r
source("tests/test_pipeline.R")
source("tests/test_app.R")
```

The checks cover data size and balance, train/test separation, both classifiers, expected sample labels, posterior normalization, evaluation outputs, Shiny startup, empty input, and history clearing.

## Project documents

- [Undergraduate project report](PROJECT_REPORT.md)
- [10-slide presentation outline](PRESENTATION.md)

## Limitations and next steps

This is a small, English-only synthetic dataset. The models treat words as conditionally independent and do not use word order, sender reputation, attachments, or email headers. A meaningful real-world evaluation would require a suitably licensed corpus, duplicate/leakage checks, cross-validation, and careful error analysis.

## License

No license has been specified for this repository. Contact the repository owner before reusing or redistributing the project.