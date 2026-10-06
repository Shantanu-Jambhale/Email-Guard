predict_with_e1071 <- function(email_text, model_bundle) {
  cleaned_text <- clean_text(email_text)
  feature_matrix <- make_feature_matrix(cleaned_text, model_bundle$vocabulary)
  feature_frame <- as_binary_factors(feature_matrix)
  raw_probabilities <- stats::predict(
    model_bundle$e1071_model,
    feature_frame,
    type = "raw"
  )
  probabilities <- raw_probabilities[1, c("spam", "ham")]

  list(
    prediction = names(probabilities)[which.max(probabilities)],
    spam_probability = unname(probabilities[["spam"]]),
    ham_probability = unname(probabilities[["ham"]]),
    confidence = max(probabilities)
  )
}

predict_all_models <- function(email_text, model_bundle) {
  cleaned_text <- clean_text(email_text)
  list(
    cleaned_text = cleaned_text,
    manual = predict_email(cleaned_text, model_bundle$manual_model),
    e1071 = predict_with_e1071(email_text, model_bundle)
  )
}