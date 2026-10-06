build_manual_bayes <- function(cleaned_documents, labels, alpha = 1) {
  labels <- as.character(labels)
  classes <- c("spam", "ham")
  if (!all(classes %in% labels)) {
    stop("Training data must contain both spam and ham examples.")
  }

  document_tokens <- lapply(cleaned_documents, tokenize_clean_text)
  vocabulary <- sort(unique(unlist(document_tokens, use.names = FALSE)))
  if (length(vocabulary) == 0) {
    stop("The training documents produced an empty vocabulary.")
  }

  class_word_counts <- lapply(classes, function(class_name) {
    tokens <- unlist(document_tokens[labels == class_name], use.names = FALSE)
    counts <- table(factor(tokens, levels = vocabulary))
    stats::setNames(as.numeric(counts), vocabulary)
  })
  names(class_word_counts) <- classes

  class_token_totals <- vapply(class_word_counts, sum, numeric(1))
  class_document_counts <- table(factor(labels, levels = classes))

  list(
    classes = classes,
    vocabulary = vocabulary,
    word_counts = class_word_counts,
    token_totals = class_token_totals,
    document_counts = as.numeric(class_document_counts),
    priors = stats::setNames(
      as.numeric(class_document_counts) / length(labels),
      classes
    ),
    alpha = alpha
  )
}

calculate_prior <- function(model, class_name) {
  if (!class_name %in% model$classes) {
    stop("Unknown class: ", class_name)
  }
  unname(model$priors[[class_name]])
}

calculate_word_probability <- function(word, class_name, model) {
  if (!class_name %in% model$classes) {
    stop("Unknown class: ", class_name)
  }
  if (!word %in% model$vocabulary) {
    return(model$alpha / (model$token_totals[[class_name]] +
      model$alpha * length(model$vocabulary)))
  }

  (model$word_counts[[class_name]][[word]] + model$alpha) /
    (model$token_totals[[class_name]] +
      model$alpha * length(model$vocabulary))
}

calculate_class_log_score <- function(tokens, class_name, model) {
  score <- log(calculate_prior(model, class_name))
  if (length(tokens) == 0) {
    return(score)
  }

  token_counts <- table(tokens)
  for (word in names(token_counts)) {
    score <- score + as.numeric(token_counts[[word]]) *
      log(calculate_word_probability(word, class_name, model))
  }
  score
}

calculate_spam_probability <- function(tokens, model) {
  spam_score <- calculate_class_log_score(tokens, "spam", model)
  ham_score <- calculate_class_log_score(tokens, "ham", model)
  maximum_score <- max(spam_score, ham_score)
  exp(spam_score - maximum_score) /
    (exp(spam_score - maximum_score) + exp(ham_score - maximum_score))
}

calculate_ham_probability <- function(tokens, model) {
  1 - calculate_spam_probability(tokens, model)
}

predict_email <- function(cleaned_text, model) {
  tokens <- tokenize_clean_text(cleaned_text)
  log_scores <- c(
    spam = calculate_class_log_score(tokens, "spam", model),
    ham = calculate_class_log_score(tokens, "ham", model)
  )
  maximum_score <- max(log_scores)
  unnormalized <- exp(log_scores - maximum_score)
  probabilities <- unnormalized / sum(unnormalized)

  detected_tokens <- unique(tokens[tokens %in% model$vocabulary])
  word_details <- data.frame(
    word = detected_tokens,
    spam_probability = vapply(
      detected_tokens,
      calculate_word_probability,
      numeric(1),
      class_name = "spam",
      model = model
    ),
    ham_probability = vapply(
      detected_tokens,
      calculate_word_probability,
      numeric(1),
      class_name = "ham",
      model = model
    ),
    stringsAsFactors = FALSE
  )
  if (nrow(word_details) > 0) {
    word_details$evidence <- log(word_details$spam_probability /
      word_details$ham_probability)
    word_details <- word_details[order(-abs(word_details$evidence)), , drop = FALSE]
  } else {
    word_details$evidence <- numeric()
  }

  list(
    prediction = names(probabilities)[which.max(probabilities)],
    spam_probability = unname(probabilities[["spam"]]),
    ham_probability = unname(probabilities[["ham"]]),
    confidence = max(probabilities),
    log_scores = log_scores,
    word_details = word_details,
    token_count = length(tokens)
  )
}