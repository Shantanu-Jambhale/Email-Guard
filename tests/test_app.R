source("app.R")

shiny::testServer(server, {
  session$setInputs(
    email_text = "Congratulations! You won a free prize. Click to claim your reward.",
    analyze = 1
  )
  spam_summary <- output$prediction_summary$html
  stopifnot(grepl(">SPAM<", spam_summary, fixed = TRUE))
  stopifnot(length(as.character(output$bayes_word_table)) > 0)

  session$setInputs(email_text = "", analyze = 2)
  session$setInputs(clear_history = 1)

  session$setInputs(
    email_text = "Hello team, our project meeting is tomorrow. Please bring the report.",
    analyze = 3
  )
  ham_summary <- output$prediction_summary$html
  stopifnot(grepl(">HAM<", ham_summary, fixed = TRUE))
})

cat("PASS: Shiny startup, both sample labels, Bayes table, empty input, and history reset.\n")