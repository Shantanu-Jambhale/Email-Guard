required_packages <- c(
  "shiny", "shinydashboard", "dplyr", "stringr", "tm",
  "e1071", "ggplot2", "plotly", "DT"
)
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0) {
  stop(
    "Install the required packages before starting the app: ",
    paste(missing_packages, collapse = ", ")
  )
}

library(shiny)
library(shinydashboard)

source("R/preprocessing.R")
source("R/manual_bayes.R")
source("R/evaluation.R")
source("R/train_model.R")
source("R/prediction.R")

model_bundle <- train_models()
dir.create("models", showWarnings = FALSE)
saveRDS(model_bundle, file.path("models", "naive_bayes_model.rds"))

format_percent <- function(value) {
  sprintf("%.2f%%", value * 100)
}

ui <- shinydashboard::dashboardPage(
  skin = "green",
  dashboardHeader(title = "EMAIL GUARD", titleWidth = 235),
  dashboardSidebar(
    width = 235,
    sidebarMenu(
      id = "tabs",
      menuItem("Home", tabName = "home", icon = icon("home")),
      menuItem("Spam Detector", tabName = "detector", icon = icon("envelope")),
      menuItem("Bayes Calculation", tabName = "bayes", icon = icon("calculator")),
      menuItem("Dataset", tabName = "dataset", icon = icon("table")),
      menuItem("Model Performance", tabName = "performance", icon = icon("chart-column")),
      menuItem("Prediction History", tabName = "history", icon = icon("clock-rotate-left")),
      menuItem("About", tabName = "about", icon = icon("circle-info"))
    )
  ),
  dashboardBody(
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "style.css"),
      tags$script(src = "custom.js")
    ),
    tabItems(
      tabItem(
        tabName = "home",
        fluidRow(
          column(
            width = 8,
            div(
              class = "home-intro",
              p(class = "eyebrow", "A probability-first classifier"),
              h1("EMAIL GUARD"),
              p(class = "lead-copy", "Bayesian Email Spam Detection"),
              p(
                "A transparent email classifier built in R. Inspect the learned word probabilities,",
                " compare two Naive Bayes approaches, and see why each message receives its label."
              ),
              actionButton("go_detector", "Analyze an email", icon = icon("arrow-right"), class = "primary-action")
            )
          ),
          column(
            width = 4,
            div(
              class = "formula-panel",
              p(class = "eyebrow", "Posterior probability"),
              div(class = "formula", "P(Spam | words) ∝ P(Spam) × ∏ P(word | Spam)"),
              p("The same calculation is repeated for HAM, then both scores are normalized.")
            )
          )
        ),
        fluidRow(
          box(
            width = 4, title = "01 / Clean", status = "primary", solidHeader = FALSE,
            p("Remove markup, links, addresses, punctuation, numbers, and common stopwords.")
          ),
          box(
            width = 4, title = "02 / Count", status = "warning", solidHeader = FALSE,
            p("Represent messages as word occurrences and estimate class-conditional probabilities.")
          ),
          box(
            width = 4, title = "03 / Compare", status = "success", solidHeader = FALSE,
            p("Combine priors and likelihoods in log space, then compare SPAM and HAM posteriors.")
          )
        ),
        fluidRow(
          valueBoxOutput("home_message_count", width = 4),
          valueBoxOutput("home_spam_prior", width = 4),
          valueBoxOutput("home_vocabulary_size", width = 4)
        )
      ),
      tabItem(
        tabName = "detector",
        fluidRow(
          box(
            width = 7, title = "Analyze an email", status = "primary", solidHeader = TRUE,
            textAreaInput(
              "email_text", "Email message", rows = 8,
              placeholder = "Paste an email message here...",
              width = "100%"
            ),
            div(id = "email-char-count", "0 characters"),
            div(
              class = "button-row",
              actionButton("analyze", "Analyze email", icon = icon("magnifying-glass"), class = "primary-action"),
              actionButton("sample_spam", "Try spam sample", icon = icon("triangle-exclamation")),
              actionButton("sample_ham", "Try ham sample", icon = icon("envelope-open-text"))
            )
          ),
          box(
            width = 5, title = "Classification", status = "success", solidHeader = TRUE,
            uiOutput("prediction_summary"),
            plotly::plotlyOutput("probability_plot", height = "235px")
          )
        ),
        fluidRow(
          box(
            width = 7, title = "Words influencing the manual prediction", status = "warning",
            solidHeader = TRUE, DT::DTOutput("important_words")
          ),
          box(
            width = 5, title = "Model comparison for this message", status = "primary",
            solidHeader = TRUE, uiOutput("model_comparison")
          )
        )
      ),
      tabItem(
        tabName = "bayes",
        fluidRow(
          box(
            width = 12, title = "Manual Bayes calculation", status = "primary", solidHeader = TRUE,
            uiOutput("bayes_steps")
          )
        )
      ),
      tabItem(
        tabName = "dataset",
        fluidRow(
          valueBoxOutput("dataset_total", width = 3),
          valueBoxOutput("dataset_spam", width = 3),
          valueBoxOutput("dataset_ham", width = 3),
          valueBoxOutput("dataset_balance", width = 3)
        ),
        fluidRow(
          box(width = 5, title = "Spam vs HAM distribution", status = "success", solidHeader = TRUE,
              plotOutput("dataset_distribution", height = "300px")),
          box(width = 7, title = "Fictional academic dataset", status = "primary", solidHeader = TRUE,
              DT::DTOutput("dataset_table"))
        )
      ),
      tabItem(
        tabName = "performance",
        fluidRow(
          valueBoxOutput("accuracy_box", width = 3),
          valueBoxOutput("precision_box", width = 3),
          valueBoxOutput("recall_box", width = 3),
          valueBoxOutput("f1_box", width = 3)
        ),
        fluidRow(
          box(width = 6, title = "Manual Bayes confusion matrix", status = "primary", solidHeader = TRUE,
              plotOutput("confusion_plot", height = "320px")),
          box(width = 6, title = "Held-out model comparison", status = "success", solidHeader = TRUE,
              DT::DTOutput("comparison_table"))
        ),
        fluidRow(
          box(width = 12, title = "Evaluation details", status = "warning", solidHeader = TRUE,
              p("Metrics are calculated from the reproducible 20% stratified test split. SPAM is treated as the positive class."),
              verbatimTextOutput("confusion_counts"))
        )
      ),
      tabItem(
        tabName = "history",
        fluidRow(
          box(
            width = 12, title = "This session's predictions", status = "primary", solidHeader = TRUE,
            actionButton("clear_history", "Clear history", icon = icon("trash"), class = "clear-action"),
            br(), br(), DT::DTOutput("history_table")
          )
        )
      ),
      tabItem(
        tabName = "about",
        fluidRow(
          box(
            width = 8, title = "About this mini project", status = "primary", solidHeader = TRUE,
            h3("A transparent classroom demonstration"),
            p("The training data is generated locally from fictional academic and promotional message templates. It is intended to demonstrate text classification, not to represent real-world email traffic."),
            p("The manual classifier uses a multinomial word-count model with Laplace smoothing. Its posterior is calculated from class priors and learned conditional word probabilities in log space."),
            p("The comparison classifier uses e1071::naiveBayes() with binary bag-of-words features and Laplace smoothing. Both are trained on the same seeded split."),
            h4("Important limitation"),
            p("Predictions reflect the vocabulary and style of this small synthetic dataset. Do not use this model for security, production email filtering, or decisions about real messages.")
          ),
          box(
            width = 4, title = "Project facts", status = "warning", solidHeader = TRUE,
            tags$ul(
              tags$li("Language: R"),
              tags$li("Interface: Shiny dashboard"),
              tags$li("Features: term presence and term counts"),
              tags$li("Split: stratified 80% train / 20% test"),
              tags$li("Random seed: 123")
            )
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  latest_result <- reactiveVal(NULL)
  history <- reactiveVal(data.frame(
    Time = character(), Preview = character(), Prediction = character(),
    `Spam %` = character(), `HAM %` = character(),
    check.names = FALSE, stringsAsFactors = FALSE
  ))

  observeEvent(input$go_detector, updateTabItems(session, "tabs", "detector"))

  observeEvent(input$sample_spam, {
    updateTextAreaInput(
      session, "email_text",
      value = "Congratulations! You have won a free cash prize. Click now to claim your reward!"
    )
  })
  observeEvent(input$sample_ham, {
    updateTextAreaInput(
      session, "email_text",
      value = "Hello team, our project meeting has been scheduled for tomorrow at 10 AM. Please bring your report."
    )
  })

  observeEvent(input$analyze, {
    email <- trimws(input$email_text %||% "")
    if (!nzchar(email)) {
      showNotification("Enter an email message before analyzing.", type = "warning")
      return()
    }

    result <- tryCatch(
      predict_all_models(email, model_bundle),
      error = function(error) {
        showNotification(paste("Prediction failed:", conditionMessage(error)), type = "error")
        NULL
      }
    )
    if (is.null(result)) {
      return()
    }

    latest_result(result)
    preview <- stringr::str_trunc(gsub("\\s+", " ", email), 90)
    new_entry <- data.frame(
      Time = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
      Preview = preview,
      Prediction = toupper(result$manual$prediction),
      `Spam %` = format_percent(result$manual$spam_probability),
      `HAM %` = format_percent(result$manual$ham_probability),
      check.names = FALSE,
      stringsAsFactors = FALSE
    )
    history(rbind(new_entry, history()))
  })

  observeEvent(input$clear_history, {
    history(data.frame(
      Time = character(), Preview = character(), Prediction = character(),
      `Spam %` = character(), `HAM %` = character(),
      check.names = FALSE, stringsAsFactors = FALSE
    ))
  })

  output$home_message_count <- renderValueBox({
    valueBox(nrow(model_bundle$dataset), "Training messages", icon = icon("envelope"), color = "green")
  })
  output$home_spam_prior <- renderValueBox({
    valueBox(format_percent(model_bundle$manual_model$priors[["spam"]]), "SPAM prior", icon = icon("chart-pie"), color = "yellow")
  })
  output$home_vocabulary_size <- renderValueBox({
    valueBox(length(model_bundle$vocabulary), "Learned features", icon = icon("font"), color = "teal")
  })

  output$prediction_summary <- renderUI({
    result <- latest_result()
    if (is.null(result)) {
      return(div(class = "empty-state", "Enter a message and analyze it to see both posterior probabilities."))
    }
    prediction <- result$manual
    class_name <- toupper(prediction$prediction)
    div(
      class = paste("prediction-result", prediction$prediction),
      p(class = "eyebrow", "MANUAL BAYES PREDICTION"),
      h2(class = "prediction-label", class_name),
      div(class = "probability-pair",
          div(span("SPAM"), strong(format_percent(prediction$spam_probability))),
          div(span("HAM"), strong(format_percent(prediction$ham_probability)))),
      p(class = "confidence-line", paste("Confidence", format_percent(prediction$confidence)))
    )
  })

  output$probability_plot <- plotly::renderPlotly({
    result <- latest_result()
    validate(need(!is.null(result), "Analyze a message to display its probabilities."))
    probability_data <- data.frame(
      Class = factor(c("SPAM", "HAM"), levels = c("HAM", "SPAM")),
      Probability = c(result$manual$spam_probability, result$manual$ham_probability)
    )
    chart <- ggplot2::ggplot(
      probability_data,
      ggplot2::aes(x = Class, y = Probability, fill = Class)
    ) +
      ggplot2::geom_col(width = 0.58) +
      ggplot2::coord_flip() +
      ggplot2::scale_fill_manual(values = c(HAM = "#267a68", SPAM = "#d96a45")) +
      ggplot2::scale_y_continuous(
        limits = c(0, 1),
        labels = function(value) paste0(round(value * 100), "%")
      ) +
      ggplot2::labs(x = NULL, y = "Posterior probability") +
      ggplot2::theme_minimal(base_size = 12) +
      ggplot2::theme(legend.position = "none", panel.grid.minor = ggplot2::element_blank())
    plotly::ggplotly(chart, tooltip = c("x", "y"))
  })

  output$important_words <- DT::renderDT({
    result <- latest_result()
    validate(need(!is.null(result), "Analyze a message to inspect its evidence words."))
    details <- result$manual$word_details
    if (nrow(details) == 0) {
      return(DT::datatable(data.frame(Note = "No message words were found in the learned vocabulary."), options = list(dom = "t")))
    }
    details <- head(details, 12)
    display <- data.frame(
      Word = details$word,
      `P(word | SPAM)` = vapply(details$spam_probability, format_percent, character(1)),
      `P(word | HAM)` = vapply(details$ham_probability, format_percent, character(1)),
      Evidence = ifelse(details$evidence >= 0, "SPAM", "HAM"),
      check.names = FALSE
    )
    DT::datatable(display, rownames = FALSE, options = list(dom = "t", ordering = FALSE, pageLength = 12))
  })

  output$model_comparison <- renderUI({
    result <- latest_result()
    if (is.null(result)) {
      return(div(class = "empty-state", "The e1071 model will classify the same message after analysis."))
    }
    div(
      class = "comparison-lines",
      p(strong("Manual Bayes"), paste(" ", toupper(result$manual$prediction), " · ", format_percent(result$manual$confidence))),
      p(strong("e1071 Naive Bayes"), paste(" ", toupper(result$e1071$prediction), " · ", format_percent(result$e1071$confidence)))
    )
  })

  output$bayes_steps <- renderUI({
    result <- latest_result()
    if (is.null(result)) {
      return(div(class = "empty-state", "Analyze a message first. Its priors, detected words, likelihoods, and normalized posterior will appear here."))
    }

    prediction <- result$manual
    detected_words <- prediction$word_details
    prior_spam <- calculate_prior(model_bundle$manual_model, "spam")
    prior_ham <- calculate_prior(model_bundle$manual_model, "ham")
    word_list <- if (nrow(detected_words) == 0) {
      tags$p("No in-vocabulary words were detected; the prediction falls back to the class priors.")
    } else {
      tags$ul(lapply(detected_words$word, tags$li))
    }
    likelihood_table <- if (nrow(detected_words) == 0) {
      NULL
    } else {
      DT::DTOutput("bayes_word_table")
    }

    tagList(
      div(class = "bayes-step", h3("1. Class priors"),
          p(sprintf("P(SPAM) = %s; P(HAM) = %s. These are learned from the training labels.", format_percent(prior_spam), format_percent(prior_ham)))),
      div(class = "bayes-step", h3("2. Detected message words"), word_list),
      div(class = "bayes-step", h3("3. Conditional word probabilities"), likelihood_table),
      div(class = "bayes-step", h3("4. Combine prior and likelihoods"),
          p("For each class, add log(P(class)) to the sum of word counts multiplied by log(P(word | class)). The log form is mathematically equivalent to multiplying probabilities, but avoids numerical underflow."),
          code(sprintf("SPAM log score = %.4f", prediction$log_scores[["spam"]])), br(),
          code(sprintf("HAM log score = %.4f", prediction$log_scores[["ham"]]))),
      div(class = "bayes-step", h3("5. Normalize the scores"),
          p(sprintf("P(SPAM | words) = %s", format_percent(prediction$spam_probability))),
          p(sprintf("P(HAM | words) = %s", format_percent(prediction$ham_probability))),
          p("The normalized values sum to 100% and are the stable softmax of the two log scores.")),
      div(class = "bayes-step final-step", h3("6. Final prediction"),
          p(strong(toupper(prediction$prediction)), " selected because it has the higher posterior probability."))
    )
  })

  output$bayes_word_table <- DT::renderDT({
    result <- latest_result()
    req(result)
    details <- result$manual$word_details
    display <- data.frame(
      Word = details$word,
      `P(word | SPAM)` = vapply(details$spam_probability, format_percent, character(1)),
      `P(word | HAM)` = vapply(details$ham_probability, format_percent, character(1)),
      check.names = FALSE
    )
    DT::datatable(display, rownames = FALSE, options = list(dom = "t", ordering = FALSE))
  })

  output$dataset_total <- renderValueBox({
    valueBox(nrow(model_bundle$dataset), "Total emails", icon = icon("envelope"), color = "green")
  })
  output$dataset_spam <- renderValueBox({
    spam_count <- sum(model_bundle$dataset$label == "spam")
    valueBox(spam_count, "SPAM", icon = icon("triangle-exclamation"), color = "yellow")
  })
  output$dataset_ham <- renderValueBox({
    ham_count <- sum(model_bundle$dataset$label == "ham")
    valueBox(ham_count, "HAM", icon = icon("envelope-open"), color = "teal")
  })
  output$dataset_balance <- renderValueBox({
    spam_share <- mean(model_bundle$dataset$label == "spam")
    valueBox(format_percent(spam_share), "SPAM share", icon = icon("chart-pie"), color = "red")
  })
  output$dataset_distribution <- renderPlot({
    distribution <- dplyr::count(model_bundle$dataset, label)
    ggplot2::ggplot(distribution, ggplot2::aes(x = label, y = n, fill = label)) +
      ggplot2::geom_col(width = 0.58) +
      ggplot2::scale_fill_manual(values = c(ham = "#267a68", spam = "#d96a45")) +
      ggplot2::labs(x = NULL, y = "Emails", title = "Class counts") +
      ggplot2::theme_minimal(base_size = 13) +
      ggplot2::theme(legend.position = "none", panel.grid.minor = ggplot2::element_blank())
  })
  output$dataset_table <- DT::renderDT({
    DT::datatable(
      model_bundle$dataset,
      rownames = FALSE,
      filter = "top",
      options = list(pageLength = 8, scrollX = TRUE)
    )
  })

  output$accuracy_box <- renderValueBox({
    valueBox(format_percent(model_bundle$manual_metrics$accuracy), "Accuracy", icon = icon("bullseye"), color = "green")
  })
  output$precision_box <- renderValueBox({
    valueBox(format_percent(model_bundle$manual_metrics$precision), "Precision (SPAM)", icon = icon("crosshairs"), color = "yellow")
  })
  output$recall_box <- renderValueBox({
    valueBox(format_percent(model_bundle$manual_metrics$recall), "Recall (SPAM)", icon = icon("magnifying-glass"), color = "teal")
  })
  output$f1_box <- renderValueBox({
    valueBox(format_percent(model_bundle$manual_metrics$f1), "F1 Score", icon = icon("scale-balanced"), color = "red")
  })
  output$confusion_plot <- renderPlot({
    confusion_data <- as.data.frame(model_bundle$manual_metrics$confusion)
    ggplot2::ggplot(confusion_data, ggplot2::aes(x = Predicted, y = Actual, fill = Freq)) +
      ggplot2::geom_tile(color = "white", linewidth = 1.2) +
      ggplot2::geom_text(ggplot2::aes(label = Freq), size = 7, fontface = "bold") +
      ggplot2::scale_fill_gradient(low = "#edf4ef", high = "#267a68") +
      ggplot2::labs(x = "Predicted label", y = "Actual label", fill = "Count") +
      ggplot2::theme_minimal(base_size = 13) +
      ggplot2::theme(panel.grid = ggplot2::element_blank())
  })
  output$comparison_table <- DT::renderDT({
    comparison <- model_bundle$comparison
    comparison[, -1] <- lapply(comparison[, -1, drop = FALSE], function(column) {
      vapply(column, format_percent, character(1))
    })
    DT::datatable(comparison, rownames = FALSE, options = list(dom = "t", ordering = FALSE))
  })
  output$confusion_counts <- renderPrint({
    metrics <- model_bundle$manual_metrics
    cat("                 Predicted SPAM   Predicted HAM\n")
    cat(sprintf("Actual SPAM        %13d   %12d\n", metrics$true_positive, metrics$false_negative))
    cat(sprintf("Actual HAM         %13d   %12d\n", metrics$false_positive, metrics$true_negative))
    cat("\nSPAM is the positive class.\n")
  })

  output$history_table <- DT::renderDT({
    DT::datatable(history(), rownames = FALSE, options = list(pageLength = 10, order = list(list(0, "desc"))))
  })
}

shinyApp(ui = ui, server = server)