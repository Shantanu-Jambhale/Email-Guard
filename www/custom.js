$(document).on("input", "#email_text", function () {
  var count = $(this).val().length;
  $("#email-char-count").text(count + (count === 1 ? " character" : " characters"));
});