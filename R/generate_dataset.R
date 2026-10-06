generate_dataset <- function(output_directory = "data", seed = 123) {
  set.seed(seed)

  spam_openers <- c(
    "Congratulations, you are today's lucky winner!",
    "An exclusive offer is waiting for you.",
    "Urgent reward notice for your account.",
    "You have been selected for a bonus prize.",
    "A limited-time promotion is now available.",
    "Claim your free gift before the offer expires.",
    "Your cash reward and discount are ready.",
    "A special investment opportunity has arrived.",
    "You may qualify for a flexible credit or loan offer.",
    "The weekly lottery draw has announced a winner."
  )
  spam_details <- c(
    "Receive a money prize with no purchase required.",
    "This deal includes a bonus and a free reward.",
    "Our promotion has a discount for selected customers.",
    "The cash offer is available for a short time.",
    "Your winning number was chosen in the lottery.",
    "Explore a new investment plan with a special return.",
    "A credit review may unlock a larger loan amount.",
    "The reward includes a complimentary gift card.",
    "Winners can claim the prize after a quick review.",
    "This exclusive deal includes extra bonus money."
  )
  spam_calls <- c(
    "Click now to claim your reward.",
    "Reply today to accept this offer.",
    "Visit the link to collect your prize.",
    "Act quickly before this promotion ends.",
    "Confirm your details to receive the bonus.",
    "Claim the cash reward using the secure form.",
    "Click to view the discount and deal.",
    "Respond now to enter the next lottery draw.",
    "Accept the free offer while it is available.",
    "Contact our team to unlock your reward."
  )

  ham_openers <- c(
    "Hello team, the project meeting is scheduled for tomorrow.",
    "The professor shared an update about the next lecture.",
    "Please review the assignment before the deadline.",
    "Our college class will meet in the laboratory this week.",
    "The presentation team has revised the project report.",
    "A reminder about attendance and the class schedule.",
    "The exam preparation notes are available for review.",
    "The submission deadline is listed on the course page.",
    "We will discuss the laboratory results after the lecture.",
    "The group meeting has moved to the seminar room."
  )
  ham_details <- c(
    "Please bring your notes and the latest report.",
    "The assignment covers the topics from this week's class.",
    "Our team will share the project schedule with everyone.",
    "The professor asked us to prepare questions for the lecture.",
    "Review the submission guidelines before uploading your work.",
    "The laboratory attendance sheet is on the front desk.",
    "We can discuss the exam plan during tomorrow's meeting.",
    "The presentation draft needs feedback from the project team.",
    "Class notes and the updated timetable are attached.",
    "Please send the report to the course group this afternoon."
  )
  ham_closings <- c(
    "Thank you, see you in class.",
    "Please let the team know if the schedule changes.",
    "Regards, the project group.",
    "I will bring the notes to the meeting.",
    "Best, your course representative.",
    "Please reply with any questions about the assignment.",
    "We can review the presentation together tomorrow.",
    "Thanks for coordinating the laboratory session.",
    "The report is due before Friday's deadline.",
    "See you at the lecture."
  )

  make_messages <- function(count, first, second, third) {
    vapply(seq_len(count), function(index) {
      paste(
        sample(first, 1),
        sample(second, 1),
        sample(third, 1),
        sep = " "
      )
    }, character(1), USE.NAMES = FALSE)
  }

  dataset <- data.frame(
    id = seq_len(500),
    email_text = c(
      make_messages(300, spam_openers, spam_details, spam_calls),
      make_messages(200, ham_openers, ham_details, ham_closings)
    ),
    label = c(rep("spam", 300), rep("ham", 200)),
    stringsAsFactors = FALSE
  )
  dataset <- dataset[sample(seq_len(nrow(dataset))), , drop = FALSE]
  rownames(dataset) <- NULL

  dir.create(output_directory, recursive = TRUE, showWarnings = FALSE)
  write.csv(dataset, file.path(output_directory, "spam_dataset.csv"), row.names = FALSE)
  write.csv(dataset, "spam_dataset.csv", row.names = FALSE)

  invisible(dataset)
}