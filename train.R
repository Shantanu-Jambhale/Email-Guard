source("R/generate_dataset.R")
source("R/preprocessing.R")
source("R/manual_bayes.R")
source("R/evaluation.R")
source("R/train_model.R")

if (!file.exists(file.path("data", "spam_dataset.csv"))) {
  generate_dataset()
}

model_bundle <- train_models(seed = 123)
dir.create("models", showWarnings = FALSE)
saveRDS(model_bundle, file.path("models", "naive_bayes_model.rds"))
write.csv(model_bundle$comparison, file.path("models", "model_metrics.csv"), row.names = FALSE)
write.csv(
  as.data.frame(model_bundle$manual_metrics$confusion),
  file.path("models", "manual_confusion_matrix.csv"),
  row.names = FALSE
)

cat("Test-set metrics (computed from held-out predictions):\n")
print(model_bundle$comparison)
cat("\nManual Bayes confusion matrix (actual rows, predicted columns):\n")
print(model_bundle$manual_metrics$confusion)