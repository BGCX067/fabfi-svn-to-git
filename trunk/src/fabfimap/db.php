<?php

$db_user="user";
$db_password="password";
$db_server="localhost";
$map_db="meshmib";
$cacti_db="cacti";

$con = mysql_connect($db_server,$db_user,$db_password);
$cacti_con = $con;

if (!$con)
{
        die('Could not connect: ' . mysql_error());
}

if (!$cacti_con)
{
        die('Could not connect: ' . mysql_error());
}

?>
