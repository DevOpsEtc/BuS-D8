<!-- http://wiki.dreamhost.com/PHP_mail() -->

<?php

// multiple recipients (note the commas)
$to = "Greg@, ";
//$to .= "nobody@example.com, ";
//$to .= "somebody_else@example.com";

// subject
$subject = "Test message...";

// compose message
$message = "
<html>
  <head>
    <title>Hooray!</title>
  </head>
  <body>
    <h1>PHP Email Results</h1>
    <p>Smtp relay to gmail is working</p>
  </body>
</html>
";

// To send HTML mail, the Content-type header must be set
$headers = "From: Greg@\r\n";
$headers .= "Reply-To: Greg@\r\n";
$headers .= "MIME-Version: 1.0\r\n";
$headers .= "Content-type: text/html; charset=iso-8859-1\r\n";

// send email
mail($to, $subject, $message, $headers);
?>
