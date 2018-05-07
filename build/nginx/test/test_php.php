<html>
  <head>
  <title>LEMP Stack Test: PHP-FPM</title>
  </head>
  <body>
    <p>Test Links:</p>
    <ul>
      <li><a href="/test_php.php/">/test_php.php/</a></li>
      <li><a href="/test_php.php/foo">/test_php.php/foo</a></li>
      <li><a href="/test_php.php/foo/bar.php">/test_php.php/foo/bar.php</a></li>
      <li><a href="/test_php.php/foo/bar.php?v=1">/test_php.php/foo/bar.php?v=1</a></li>
      <li><a href="/test.gif/malicious_test.php?">/test.gif/malicious_test.php?"</a></li>
    </ul>
    Source: <a href="http://wiki.nginx.org/PHPFcgiExample" target="_blank">http://wiki.nginx.org/PHPFcgiExample</a>
    <br />
    <br />
    <hr />
    <p>Values of note:</p>
    <ul>
    <?php
      echo 'REQUEST_URI: &nbsp'; var_export($_SERVER['REQUEST_URI']);
      echo '<br />SCRIPT_NAME: &nbsp'; var_export($_SERVER['SCRIPT_NAME']);
      echo '<br />PATH_INFO: &nbsp'; var_export($_SERVER['PATH_INFO']);
      echo '<br />PHP_SELF: &nbsp'; var_export($_SERVER['PHP_SELF']);
    ?>
    </ul>
    <hr />
    <p>All Values:</p>
    <pre><?php var_export($_SERVER)?></pre>
</body>
</html>
