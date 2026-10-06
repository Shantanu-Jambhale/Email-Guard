source("R/generate_dataset.R")
source("R/preprocessing.R")
source("R/manual_bayes.R")
source("R/evaluation.R")
source("R/train_model.R")
source("R/prediction.R")

if (!file.exists(file.path("data", "spam_dataset.csv"))) {
  generate_dataset()
}

bundle <- train_models(seed = 123)
spam_sample <- predict_all_models(
  "Congratulations! You have won a free cash prize. Click now to claim your reward!",
  bundle
)
ham_sample <- predict_all_models(
  "Hello team, our project meeting has been scheduled for tomorrow at 10 AM. Please bring your report.",
  bundle
)

stopifnot(
  nrow(bundle$dataset) == 500,
  sum(bundle$dataset$label == "spam") == 300,
  sum(bundle$dataset$label == "ham") == 200,
  length(intersect(bundle$train_indices, bundle$test_indices)) == 0,
  length(bundle$test_indices) == 100,
  spam_sample$manual$prediction == "spam",
  spam_sample$e1071$prediction == "spam",
  ham_sample$manual$prediction == "ham",
  ham_sample$e1071$prediction == "ham",
  abs(spam_sample$manual$spam_probability + spam_sample$manual$ham_probability - 1) < 1e-10,
  abs(ham_sample$manual$spam_probability + ham_sample$manual$ham_probability - 1) < 1e-10,
  abs(sum(bundle$manual_model$priors) - 1) < 1e-10,
  sum(bundle$manual_metrics$confusion) == length(bundle$test_indices),
  all(vapply(bundle$comparison[, -1], function(column) all(is.finite(column)), logical(1)))
)

cat("PASS: dataset, split, both classifiers, posteriors, and evaluation metrics.\n")