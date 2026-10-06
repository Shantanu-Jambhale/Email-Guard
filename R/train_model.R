read_project_dataset <- function(dataset_path = file.path("data", "spam_dataset.csv")) {
  if (!file.exists(dataset_path)) {
    stop("Dataset not found at ", dataset_path,
      ". Run source('R/generate_dataset.R'); generate_dataset() first.")
  }

  dataset <- read.csv(dataset_path, stringsAsFactors = FALSE, na.strings = c("", "NA"))
  required_columns <- c("id", "email_text", "label")
  if (!all(required_columns %in% names(dataset))) {
    stop("Dataset must contain columns: ", paste(required_columns, collapse = ", "))
  }

  dataset <- dataset[!is.na(dataset$email_text) & !is.na(dataset$label), , drop = FALSE]
  dataset$label <- tolower(trimws(dataset$label))
  dataset <- dataset[dataset$label %in% c("spam", "ham"), , drop = FALSE]
  if (!all(c("spam", "ham") %in% dataset$label)) {
    stop("Dataset must contain both spam and ham labels.")
  }
  dataset
}

make_feature_matrix <- function(cleaned_documents, vocabulary) {
  corpus <- tm::Corpus(tm::VectorSource(cleaned_documents))
  document_term_matrix <- tm::DocumentTermMatrix(
    corpus,
    control = list(dictionary = vocabulary)
  )
  terms_found <- tm::Terms(document_term_matrix)
  feature_matrix <- matrix(
    0L,
    nrow = length(cleaned_documents),
    ncol = length(vocabulary),
    dimnames = list(NULL, vocabulary)
  )
  if (length(terms_found) > 0) {
    feature_matrix[, terms_found] <- as.matrix(document_term_matrix)
  }
  feature_matrix
}

as_binary_factors <- function(feature_matrix) {
  feature_frame <- as.data.frame(lapply(as.data.frame(feature_matrix), function(column) {
    factor(as.integer(column > 0), levels = c(0, 1))
  }), check.names = FALSE)
  feature_frame
}

train_models <- function(dataset_path = file.path("data", "spam_dataset.csv"), seed = 123) {
  dataset <- read_project_dataset(dataset_path)
  set.seed(seed)

  training_indices <- unlist(lapply(c("spam", "ham"), function(class_name) {
    class_indices <- which(dataset$label == class_name)
    sample(class_indices, size = floor(length(class_indices) * 0.8))
  }), use.names = FALSE)
  training_indices <- sample(training_indices)
  test_indices <- setdiff(seq_len(nrow(dataset)), training_indices)

  cleaned_text <- clean_text(dataset$email_text)
  training_text <- cleaned_text[training_indices]
  test_text <- cleaned_text[test_indices]
  training_labels <- dataset$label[training_indices]
  test_labels <- dataset$label[test_indices]

  training_dtm <- tm::DocumentTermMatrix(
    tm::Corpus(tm::VectorSource(training_text))
  )
  filtered_dtm <- tm::removeSparseTerms(training_dtm, 0.995)
  vocabulary <- tm::Terms(filtered_dtm)
  if (length(vocabulary) == 0) {
    stop("No terms remain after sparse-term filtering.")
  }

  manual_model <- build_manual_bayes(training_text, training_labels, alpha = 1)
  training_matrix <- make_feature_matrix(training_text, vocabulary)
  test_matrix <- make_feature_matrix(test_text, vocabulary)
  training_features <- as_binary_factors(training_matrix)
  test_features <- as_binary_factors(test_matrix)

  e1071_model <- e1071::naiveBayes(
    x = training_features,
    y = factor(training_labels, levels = c("spam", "ham")),
    laplace = 1
  )

  manual_predictions <- vapply(test_text, function(document) {
    predict_email(document, manual_model)$prediction
  }, character(1))
  e1071_predictions <- as.character(stats::predict(e1071_model, test_features, type = "class"))

  manual_metrics <- calculate_metrics(test_labels, manual_predictions)
  e1071_metrics <- calculate_metrics(test_labels, e1071_predictions)

  list(
    dataset = dataset,
    seed = seed,
    train_indices = training_indices,
    test_indices = test_indices,
    vocabulary = vocabulary,
    manual_model = manual_model,
    e1071_model = e1071_model,
    manual_metrics = manual_metrics,
    e1071_metrics = e1071_metrics,
    comparison = metrics_table(manual_metrics, e1071_metrics),
    test_results = data.frame(
      actual = test_labels,
      manual_prediction = manual_predictions,
      e1071_prediction = e1071_predictions,
      stringsAsFactors = FALSE
    )
  )
}