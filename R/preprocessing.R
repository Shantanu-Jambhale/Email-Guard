clean_text <- function(text) {
  if (is.null(text) || length(text) == 0) {
    return(character())
  }

  text <- as.character(text)
  text[is.na(text)] <- ""

  vapply(text, function(value) {
    value <- stringr::str_replace_all(value, "<[^>]*>", " ")
    value <- stringr::str_replace_all(value, "(?i)https?://\\S+|www\\.\\S+", " ")
    value <- stringr::str_replace_all(
      value,
      "[[:alnum:]._%+-]+@[[:alnum:].-]+\\.[A-Za-z]{2,}",
      " "
    )
    value <- stringr::str_to_lower(value)
    value <- stringr::str_replace_all(value, "[^a-z\\s]", " ")
    value <- stringr::str_squish(value)

    tokens <- unlist(strsplit(value, "\\s+"), use.names = FALSE)
    tokens <- tokens[nzchar(tokens)]
    tokens <- tokens[!tokens %in% tm::stopwords("en")]

    paste(tokens, collapse = " ")
  }, character(1), USE.NAMES = FALSE)
}

tokenize_clean_text <- function(cleaned_text) {
  if (length(cleaned_text) == 0 || is.na(cleaned_text) || !nzchar(cleaned_text)) {
    return(character())
  }

  unlist(strsplit(cleaned_text, "\\s+"), use.names = FALSE)
}