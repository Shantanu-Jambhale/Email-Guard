# Email Spam Detection Using Bayes' Theorem Using R Programming

## 1. Title

Email Spam Detection Using Bayes' Theorem Using R Programming

## 2. Abstract

This mini project develops Email Guard, an interactive R Shiny application that classifies an email as SPAM or HAM. It preprocesses message text, builds bag-of-words features, and estimates posterior class probabilities with a manual multinomial Naive Bayes implementation. Laplace smoothing prevents zero likelihoods, and log-space scoring avoids numerical underflow. A second model uses `e1071::naiveBayes()` for comparison. The dashboard displays class probabilities, influential word likelihoods, a step-by-step Bayes calculation, dataset statistics, a confusion matrix, evaluation metrics, and session prediction history. Experiments use a deterministic synthetic dataset of 500 fictional messages. Both models scored 100% on the generated 100-message test split; this demonstrates the implementation but is not evidence of real-world filtering performance because the synthetic templates have easily separated vocabulary.

## 3. Introduction

Email is widely used for academic and professional communication, but unsolicited promotional messages can obscure useful mail. Text classification offers a way to assign messages to known categories from examples. Probability provides a principled way to combine prior class frequency with the observed words in a message. This project focuses on Naive Bayes because its calculation is compact enough to explain in a viva and efficient enough for an interactive demonstration.

## 4. Problem Statement

Given a labeled collection of email messages and a new message, determine whether the new message is SPAM or HAM. The system must learn word statistics from training data, estimate both class probabilities, and expose the reasoning behind its result.

## 5. Objectives

- Implement a reusable email preprocessing function in R.
- Train a manual, Laplace-smoothed Bayesian text classifier.
- Compare it with the `e1071` Naive Bayes implementation.
- Produce actual held-out metrics and a confusion matrix.
- Build a Shiny interface for prediction, explanation, analysis, and history.
- Make the results repeatable with a fixed random seed.

## 6. Scope

The project is a local academic demonstration for English-language text. It includes a fictional 500-row dataset, two classifiers, a seeded stratified split, and an interactive dashboard. It does not connect to mail servers, send or receive email, inspect attachments, or claim production-grade threat detection.

## 7. Existing System

Basic filtering systems often rely on manually selected keywords or opaque external services. A keyword-only rule can miss unfamiliar wording and may label ordinary messages incorrectly. A black-box prediction is also difficult to explain in a classroom setting.

## 8. Proposed System

Email Guard learns class priors and word probabilities from labeled examples. It applies the same deterministic split to a manual multinomial model and an `e1071` binary-feature model. The Shiny application presents the manual calculation and model comparison, rather than hiding the probability calculation behind a single prediction call.

## 9. Technologies Used

| Technology | Role |
| --- | --- |
| R | Application and statistical programming language |
| Shiny, shinydashboard | Interactive dashboard |
| dplyr, stringr | Data summaries and text operations |
| tm | Corpus and document-term matrix construction |
| e1071 | Standard Naive Bayes comparison model |
| ggplot2, plotly | Static and interactive visualizations |
| DT | Searchable and paginated tables |
| CSV | Dataset storage |

## 10. Dataset

`data/spam_dataset.csv` contains 500 fictional messages with columns `id`, `email_text`, and `label`: 300 SPAM and 200 HAM. SPAM examples use fictional promotional vocabulary such as *free*, *prize*, *claim*, and *reward*. HAM examples use academic and coordination vocabulary such as *meeting*, *assignment*, *project*, *lecture*, and *report*. A seeded generator creates the data; the dataset is intended to demonstrate an algorithm, not model real mail.

## 11. Data Preprocessing

The `clean_text()` function lowercases each message; removes HTML tags, URLs, email addresses, punctuation, and numbers; collapses repeated whitespace; and removes English stopwords from `tm`. The resulting string is tokenized for the manual model. A training-only document-term matrix defines the feature vocabulary; sparse terms are removed before fitting the comparison model. The test split does not contribute to vocabulary selection.

## 12. Bayes' Theorem

For a class $C$ and observed word $W$, Bayes' theorem is:

$$P(C \mid W)=\frac{P(W \mid C)P(C)}{P(W)}$$

Here, $P(C)$ is the prior, $P(W \mid C)$ is the class-conditional likelihood, and $P(C \mid W)$ is the posterior. For multiple words, Naive Bayes makes a conditional-independence approximation:

$$P(C \mid W_1,\ldots,W_n) \propto P(C)\prod_{i=1}^{n}P(W_i \mid C)$$

The manual model uses multinomial token counts with Laplace smoothing:

$$P(w \mid C)=\frac{\operatorname{count}(w,C)+1}{\operatorname{totalTokens}(C)+|V|}$$

The implementation adds log likelihoods instead of multiplying many small probabilities. It then normalizes the two class scores with a stable softmax, yielding SPAM and HAM probabilities that sum to 1.

## 13. Naive Bayes Algorithm

1. Estimate SPAM and HAM priors from the training labels.
2. Count vocabulary terms in each class.
3. Smooth each conditional probability with $\alpha=1$.
4. Clean and tokenize the input message.
5. For each class, add the log prior and token-count-weighted log likelihoods.
6. Normalize the log scores and select the class with the larger posterior.

The e1071 model receives binary word-presence predictors, whereas the manual model scores token frequency. Both demonstrate Naive Bayes, but their feature encodings differ.

## 14. System Architecture

```text
User message
    ↓
Text cleaning and stopword removal
    ↓
Tokenization / bag-of-words features
    ↓
Manual Bayes scoring ─────── e1071 Naive Bayes scoring
    ↓                                  ↓
Normalized SPAM/HAM posterior     Comparison prediction
    ↓
Shiny result, word evidence, Bayes steps, history
```

## 15. Methodology

The generator sets seed 123 and writes the labeled CSV. The training pipeline cleans the messages and performs a stratified 80/20 split, resulting in 400 training and 100 test examples. The vocabulary and model parameters are learned from training data only. Each model predicts the held-out set; `calculate_metrics()` derives the confusion matrix, accuracy, SPAM precision, SPAM recall, and F1. The app trains on startup and stores the model bundle in `models/`.

## 16. Implementation

The application is organized into focused files. `preprocessing.R` contains cleaning/tokenization; `manual_bayes.R` implements priors, smoothed likelihoods, log scores, and posterior predictions; `train_model.R` handles the split, term matrix, and model fitting; `evaluation.R` computes metrics; and `prediction.R` applies both models to new text. `app.R` builds the dashboard and reactive outputs. `generate_dataset.R` creates both CSV copies. `train.R` provides a reusable command to export fitted models and metrics.

## 17. Results

The following values were computed from the fixed 100-example holdout using actual predictions:

| Model | Accuracy | Precision | Recall | F1 Score |
| --- | ---: | ---: | ---: | ---: |
| Manual Bayes | 100.00% | 100.00% | 100.00% | 100.00% |
| e1071 Naive Bayes | 100.00% | 100.00% | 100.00% | 100.00% |

Both sample emails also receive their expected demonstration labels: the prize/reward message is SPAM and the class-meeting/report message is HAM. These outcomes are valid for this synthetic dataset only. Template-derived phrases make the classes unusually separable, so the scores are likely much higher than those on natural email.

## 18. Confusion Matrix

For the manual model, SPAM is the positive class:

| Actual / Predicted | SPAM | HAM |
| --- | ---: | ---: |
| SPAM | TP = 60 | FN = 0 |
| HAM | FP = 0 | TN = 40 |

These counts correspond to 60 SPAM and 40 HAM examples in the held-out split. The Shiny page visualizes this matrix with a ggplot tile chart.

## 19. Advantages

- The posterior is visible and mathematically interpretable.
- Laplace smoothing handles unseen words without zero likelihoods.
- Log scoring is stable for longer messages.
- A fixed stratified split makes the result reproducible.
- The second implementation provides a useful library-model comparison.

## 20. Limitations

- The dataset is small, synthetic, English-only, and generated from a limited template set.
- Word independence is an approximation; word order and context are not modeled.
- No sender, attachment, URL reputation, or header features are used.
- Evaluation on one held-out split is not a substitute for external validation or cross-validation.
- The system must not be used for real security or filtering decisions.

## 21. Future Scope

Use an appropriately licensed public dataset; deduplicate and audit it for leakage; report cross-validation and error analysis; explore n-grams and probability calibration; compare complementary classifiers; and test robustness to misspellings, obfuscation, and class imbalance.

## 22. Conclusion

This project demonstrates a complete probability-based text-classification workflow in R. It combines preprocessing, a manual Bayes calculation, a standard Naive Bayes comparison, computed evaluation, and an interactive Shiny explanation. The dashboard supports learning how priors, likelihoods, smoothing, and posteriors produce a classification. The perfect synthetic holdout score should be interpreted only as a demonstration of the controlled dataset, not as evidence of practical email-filter quality.

## 23. References

1. Thomas Bayes, “An Essay towards solving a Problem in the Doctrine of Chances,” *Philosophical Transactions of the Royal Society of London*, 1763.
2. R Core Team, *R: A Language and Environment for Statistical Computing*, <https://www.r-project.org/>.
3. Posit Software, *Shiny Documentation*, <https://shiny.posit.co/>.
4. Meyer, D. et al., *e1071: Misc Functions of the Department of Statistics, Probability Theory Group*, R package documentation, <https://cran.r-project.org/package=e1071>.
5. Feinerer, I. and Hornik, K., *tm: Text Mining Package*, R package documentation, <https://cran.r-project.org/package=tm>.
