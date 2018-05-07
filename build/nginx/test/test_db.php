<html>
  <head>
  <title>test LEMP Stack</title>
    <style>
      .header{background-color:#000; color:#FFF; font-weight:200;}
      .odd{background-color:#ccc;}
      .even{background-color:#F5F5F5;}
    </style>
  </head>
  <body>
    <h1><font color="blue">test your LEMP stack...</font></h1>
    <form method="post">
      <table border="0" width="600px">
        <tbody>
          <tr>
            <td valign="middle">Comment:</td>
            <td valign="middle"><input style="width: 385px" type="text" name="comment"></td>
            <td valign="middle"><input style="width: 130px" type="submit" value="Send Comment"></td>
          </tr>
        </tbody>
      </table>
    </form>
  </body>
</html>

<?php


// Load database connection config
$config = parse_ini_file('/etc/mysql/conf.d/mariadb.cnf');

// Connect to database
//$mysqli = new mysqli($config['host'],$config['user'],$config['password'],$config['dbname']);
$mysqli = new mysqli($config['host']['user']['password']['dbname']);

// Output any connection error
if ($mysqli->connect_error) {
    die('Error : ('. $mysqli->connect_errno .') '. $mysqli->connect_error);
}





// database env variables (defined in docker-composer.yml)
// servername = "192.168.99.100";
// username = "smoke_usr";
// password = "FyHFd63L_Z1Rc";
// dbname = "smoke_db";
//
// create connection
// $conn = new mysqli($servername, $username, $password, $dbname);
// if ($conn->connect_error) {
//   die("Connection failed: " . $conn->connect_error);
// }

// query variable: create
$qCreate = "CREATE TABLE IF NOT EXISTS comments (
  comment_id int(11) NOT NULL AUTO_INCREMENT,
  comment_date TIMESTAMP,
  comment varchar(500) Not NULL,
  PRIMARY KEY (comment_id)
) ENGINE=InnoDBi DEFAULT CHARSET=utf8";

// create: table & columns
// $rCreate = $conn->query($qCreate) or die('table not created: ' . mysql_error());
$rCreate = $mysqli->query($qCreate) or die('table not created: ' . mysql_error());

// if form is submitted with a comment
if (isset($_POST["comment"])) {
  // query variable: insert
  $qInsert = "INSERT into comments (comment) values ('".$_POST["comment"]."')";
  // insert: comments
  $rInsert = $mysqli->query($qInsert) or die('comment not sent: ' . mysql_error());
}

// query variable: select
$qSelect = "SELECT date_format(comment_date, '%m/%d/%Y %k:%i')
  comment_date, comment FROM comments ORDER BY comment_id DESC";
// select: comments
$rSelect = $mysqli->query($qSelect);

// how many rows are in table?
$row_cnt = $rSelect->num_rows;

// initialize row even/odd variable
$c = true;

// do if comments exist
if ($row_cnt > "0" ) {
  // print results
  echo '<p><table width=600px>';
  // loop through results & embed row ouput into table rows & apply zebra stripes
  echo '<tr class="header"><td>Date Posted (UTC):</td><td>Comment:</td></tr>';
  while ( $row = mysqli_fetch_object($rSelect) ) {
    echo '<tr'.(($c = !$c)?' class="odd"':' class="even"').">";
    // loop through results & embed columns output into table columns
    foreach ($row AS $col_value) {
      echo "<td>$col_value</td>";
    }
    echo '</tr>';
  }
  echo '</table>';
}
else {
  // no comments exist; don't display annything
}

// free query memory
mysqli_free_result($rSelect);

// close db connection
$mysqli->close();
?>
