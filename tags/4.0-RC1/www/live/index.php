<?php

require_once("freifunkmap.class.php");

$map = new freifunkMap( );

// do this for installation
if( isset( $_REQUEST["install"])) {
	$map->install();
	exit( "install successful");
}

// do this for an update or an new entry of a node
if( isset( $_REQUEST["update"])) {
	$olsrip = isset( $_REQUEST["olsrip"]) ? $_REQUEST["olsrip"] : "";
	$batmanip = isset( $_REQUEST["batmanip"]) ? $_REQUEST["batmanip"] : "";
   $batmanconn = isset( $_REQUEST["batmanconn"]) ? $_REQUEST["batmanconn"] : "";
	$map->update( $_REQUEST["update"], $_REQUEST["updateiv"], $_REQUEST["note"], $olsrip, $batmanip, $batmanconn);
	exit( "success update");  
}

if( isset( $_REQUEST["dumpdatabase"])) {
  // $map->remove( "52.54908479923411", "13.4631147969");
  foreach( $map->dump( ) as $entry) {
    echo $entry['timestamp']."\t".
		     $entry['updateiv']."\t".
		     $entry['nodelat'].", ".
		     $entry['nodelng']."\t".
		     $entry['olsrip']."\t".
		     $entry['olsrlinks']."\t".
		     $entry['batmanip']."\t".
		     $entry['batmanlinks']."\t".
		     $entry['note']."\n";
  }
  exit( );
}

if( isset( $_REQUEST["getArea"])) {
   $areaCoords = explode( ",", $_REQUEST["getArea"]);
   $zoomlevel = 20;
   if( isset( $_REQUEST["z"])) $zoomlevel = $_REQUEST["z"];

   $lod = "";
   if( isset( $_REQUEST["details"])) $lod = $_REQUEST["details"];
   
   $map->getArea( $areaCoords[0], $areaCoords[1], $areaCoords[2], $areaCoords[3], (int) $zoomlevel, $lod);

   exit( );
}

if( isset( $_REQUEST["getNode"]) && freifunkMap::check( $_REQUEST["getNode"])) {
   preg_match( "/^(-?[0-9]{1,3}\.?[0-9]{0,16})\s*,\s*(-?[0-9]{1,3}\.?[0-9]{0,16})(.*)/", $_REQUEST["getNode"], $matches);
   $map->getNode( $matches[1], $matches[2]);
   exit();
}

if( isset( $_REQUEST["getgoogleearthkmlfile"])) {
	$map->getGoogleEarthKMLFile( );
	exit();
}

if( isset( $_REQUEST["newsearch"])) {
	$map->newSearch( $_REQUEST["newsearch"]);
	exit();
}

// default page request
$maptype = DEFAULT_MAPTYPE;
if( isset( $_REQUEST["type"])) {
   switch( $_REQUEST["type"]) {
   case "satellite":
      $maptype = "G_SATELLITE_MAP";
      break;
   case "hybrid":
      $maptype = "G_HYBRID_MAP";
      break;
   }
}

$showConn = "false";
if( isset( $_REQUEST["conn"])) {
   if( $_REQUEST["conn"] == "true") {
      $showConn = "true";
   }
}

$sp = DEFAULT_START_POSITION;
if( isset( $_REQUEST["sp"]) && freifunkMap::check( $_REQUEST["sp"])) {
   preg_match( "/^(-?[0-9]{1,3}\.[0-9]{1,16})\s*,\s*(-?[0-9]{1,3}\.[0-9]{1,16})\s*,?\s*(.*)/", $_REQUEST["sp"], $matches);
   $sp = "".$matches[1].", ".$matches[2]."";
}

$zoomlevel = DEFAULT_ZOOMLEVEL;
if( isset( $_REQUEST["z"]) && $_REQUEST["z"] != "" && $_REQUEST["z"] > 0 && $_REQUEST["z"] <= 19) {
   $zoomlevel = $_REQUEST["z"];
}

$search = "false";
if( isset( $_REQUEST["search"])) {
   $sp = $map->search( $_REQUEST["search"]);
   if( $sp != "") {
      $zoomlevel = 17;
      $searchResult = "map.addOverlay( new GMarker( new GLatLng( ".$sp.") , searchResultIcon));";
      $search = "true";
   } else {
      $sp = DEFAULT_START_POSITION;
   }
}

preg_match( "/MSIE/", $_SERVER['HTTP_USER_AGENT'], $matches);
if( strstr( $_SERVER['HTTP_USER_AGENT'], "MSIE")) {
   // fucking ie
   $browser = "true";
   $tag = "640px";
} else {
   $browser = "false";
   $tag = "100%";
}

?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml">
	<head>
		<meta http-equiv="content-type" content="text/html; charset=utf-8" />
		<title>Network Map</title>
		<link rel="stylesheet" type="text/css" href="freifunkmap.css" />
		<script type="text/javascript" src="http://maps.google.com/maps?file=api&amp;v=2&amp;key=<?php echo GOOGLE_MAPS_KEY ?>"></script>
		<script type="text/javascript" src="pdmarker.js"></script>
    <script type="text/javascript" src="freifunkmap_default.js.php"></script>
	</head>
	<body onload="init(<?php echo $sp.",".$zoomlevel.",".$maptype.",".$search.",".$browser.",".$showConn; ?>)" onunload="GUnload()">
		<div id="map" style="width: 100%; height: <?php echo $tag; ?>"></div>
	</body>
</html>
