# 10-Slide Presentation: Email Spam Detection Using Bayes' Theorem

## Slide 1 — Title

**Email Spam Detection Using Bayes' Theorem**  
An R and Shiny mini project  
Email Guard | Student name | Department | Institution

## Slide 2 — Problem Statement

- Unwanted messages compete with useful communication.
- Classify a message as SPAM or HAM from its text.
- The decision should be explainable, not only a black-box label.
- Scope: classroom demonstration using a fictional dataset.

## Slide 3 — Objectives

- Clean and tokenize email text.
- Learn priors and conditional word probabilities from labeled examples.
- Implement manual Bayes scoring with smoothing and log probabilities.
- Compare with `e1071::naiveBayes()`.
- Evaluate held-out predictions and show results in Shiny.

## Slide 4 — Bayes' Theorem

$$P(C \mid W)=\frac{P(W \mid C)P(C)}{P(W)}$$

- Prior $P(C)$: frequency of a class in training labels.
- Likelihood $P(W \mid C)$: probability of a word under that class.
- Posterior $P(C \mid W)$: updated class probability after observing words.
- Compare normalized SPAM and HAM posteriors.

## Slide 5 — Naive Bayes Classification

$$P(C \mid W_1,\ldots,W_n) \propto P(C)\prod_i P(W_i \mid C)$$

- Assumes words are conditionally independent given the class.
- Uses Laplace smoothing: $(count+1)/(class\ token\ total+|V|)$.
- Calculates sums of log probabilities to avoid underflow.
- Manual model: multinomial word counts; e1071 comparison: binary word presence.

## Slide 6 — System Architecture

```text
User email → clean text → tokenize / bag of words
                              ↓
             Manual Bayes + e1071 Naive Bayes
                              ↓
     posterior, word evidence, label, history, metrics
```

## Slide 7 — Dataset & Preprocessing

- 500 fictional messages: 300 SPAM, 200 HAM.
- Seeded generator, fixed seed 123.
- HTML, URLs, email addresses, punctuation, digits, and stopwords removed.
- Stratified 80/20 split: 400 training, 100 test messages.
- Vocabulary and sparse-term filtering learned from training data only.

## Slide 8 — Shiny Application

- Pages: Home, Spam Detector, Bayes Calculation, Dataset, Model Performance, Prediction History, About.
- Displays both class probabilities, confidence, and evidence words.
- Includes sample messages, data summaries, confusion matrix, and clear-history action.
- Built entirely in R with Shiny.

## Slide 9 — Results & Confusion Matrix

- Manual Bayes: accuracy 100%, precision 100%, recall 100%, F1 100%.
- e1071 Naive Bayes: accuracy 100%, precision 100%, recall 100%, F1 100%.
- Manual test confusion matrix: TP 60, FN 0, FP 0, TN 40.
- These are computed from the actual seeded split.
- **Caveat:** synthetic template language makes the classes unusually easy to separate; real-world performance is unknown.

## Slide 10 — Conclusion & Future Scope

- Demonstrated preprocessing, learned likelihoods, priors, smoothing, and posterior classification.
- Manual probability calculations are visible and explainable.
- Next: public licensed corpus, duplicate/leakage checks, cross-validation, n-grams, calibration, and error analysis.
- Not intended for real email-security use.
