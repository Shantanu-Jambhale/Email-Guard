calculate_metrics <- function(actual, predicted) {
  class_levels <- c("spam", "ham")
  actual <- factor(as.character(actual), levels = class_levels)
  predicted <- factor(as.character(predicted), levels = class_levels)
  confusion <- table(Actual = actual, Predicted = predicted)

  true_positive <- unname(confusion["spam", "spam"])
  false_negative <- unname(confusion["spam", "ham"])
  false_positive <- unname(confusion["ham", "spam"])
  true_negative <- unname(confusion["ham", "ham"])
  safe_divide <- function(numerator, denominator) {
    if (denominator == 0) 0 else numerator / denominator
  }

  precision <- safe_divide(true_positive, true_positive + false_positive)
  recall <- safe_divide(true_positive, true_positive + false_negative)
  f1 <- safe_divide(2 * precision * recall, precision + recall)

  list(
    accuracy = safe_divide(true_positive + true_negative, sum(confusion)),
    precision = precision,
    recall = recall,
    f1 = f1,
    confusion = confusion,
    true_positive = true_positive,
    false_negative = false_negative,
    false_positive = false_positive,
    true_negative = true_negative
  )
}

metrics_table <- function(manual_metrics, e1071_metrics) {
  data.frame(
    Model = c("Manual Bayes", "e1071 Naive Bayes"),
    Accuracy = c(manual_metrics$accuracy, e1071_metrics$accuracy),
    Precision = c(manual_metrics$precision, e1071_metrics$precision),
    Recall = c(manual_metrics$recall, e1071_metrics$recall),
    `F1 Score` = c(manual_metrics$f1, e1071_metrics$f1),
    check.names = FALSE
  )
}