<?php
require_once( "freifunkmap.conf.php");
?>

//<![CDATA[

/* global map variables */
var map;
var xmlhttp = null;
var drEnd = false;
var textInfoWindow = "";
var isSearch;
var searchPosition;
var resultDiv;
var showSearchResult = false;
var showOlsr = true;
var showBatman = false;
var startPosition;

/* for displaying the old map nodes */
var showOldNodes = false;

/* variables for meassuring distances */
var distPolyline = false;
var measureDistances = false;
var pointOld

/* variables for displaying the connections lines */
var connPolylines = new Array();
var showConn = false;

/* variables for displaying the LQ values */
var connLQ;
var showLQ = false;
var lqPlaced = false;

/* variables for displaying the netzone from a node */
var nodeZone = new Array();
var nodeZonePolygon = false;

var mediumicon = new GIcon();
mediumicon.image = "freifunkmap_gfx/node_medium.png";
mediumicon.iconSize = new GSize( 10, 10);
mediumicon.iconAnchor = new GPoint( 5, 5);
mediumicon.infoWindowAnchor = new GPoint( 5, 5);

var smallicon = new GIcon();
smallicon.image = "freifunkmap_gfx/node_small.png";
smallicon.iconSize = new GSize( 6, 6);
smallicon.iconAnchor = new GPoint( 3, 3);
smallicon.infoWindowAnchor = new GPoint( 3, 3);

var mediumiconOld = new GIcon();
mediumiconOld.image = "freifunkmap_gfx/node_medium_red.png";
mediumiconOld.iconSize = new GSize( 10, 10);
mediumiconOld.iconAnchor = new GPoint( 5, 5);
mediumiconOld.infoWindowAnchor = new GPoint( 5, 5);

var smalliconOld = new GIcon();
smalliconOld.image = "freifunkmap_gfx/node_small_red.png";
smalliconOld.iconSize = new GSize( 6, 6);
smalliconOld.iconAnchor = new GPoint( 3, 3);
smalliconOld.infoWindowAnchor = new GPoint( 3, 3);

var mediumblackicon = new GIcon();
mediumblackicon.image = "freifunkmap_gfx/node_medium_black.png";
mediumblackicon.iconSize = new GSize( 10, 10);
mediumblackicon.iconAnchor = new GPoint( 5, 5);
mediumblackicon.infoWindowAnchor = new GPoint( 5, 5);

var smallblackicon = new GIcon();
smallblackicon.image = "freifunkmap_gfx/node_small_black.png";
smallblackicon.iconSize = new GSize( 6, 6);
smallblackicon.iconAnchor = new GPoint( 3, 3);
smallblackicon.infoWindowAnchor = new GPoint( 3, 3);

var searchResultIcon = new GIcon();
searchResultIcon.image = "freifunkmap_gfx/search_result.png";
searchResultIcon.iconSize = new GSize( 40, 40);
searchResultIcon.iconAnchor = new GPoint( 20, 20);

/**
 * init method
 * @param String spLat   - startposition Latitude 
 * @param String spLng   - startposition Longitude
 * @param Int zoomLevel  - zoomlevel 1 - 19
 * @param String maptype - could be on of "map", "satelite" or "hybrid"
 * @param String search  - the search value
 * @param String browser - do something special for fucking IE
 */
function init(spLat, spLng, zoomLevel, maptype, search, browser, conn) {
   showConn = conn;
   startPosition = new GLatLng( spLat, spLng);
   
   if( browser) {
      map = new GMap2( document.getElementById( "map"));
   } else {
	   map = new GMap2(document.getElementById( "map"), {size : new GSize( window.innerWidth - 17, window.innerHeight - 17)});
   }

	map.setCenter( startPosition, zoomLevel);
	map.addControl( new GLargeMapControl());
	map.addControl( new GMapTypeControl());
	map.addControl( new RulerControl());
	map.addControl( new FAQControl());
	map.addControl( new LQControl());
	map.addControl( new ConnControl());
	map.addControl( new NewSearchControl());
   map.addControl( new OlsrControl());
   map.addControl( new BatmanControl());
	map.addControl( new StatsControl());
	map.setMapType( maptype);
	map.enableDoubleClickZoom();
	
	isSearch = search;
	loadNodes();

	GEvent.addListener(map, "click", function(marker, point) {
		if( point) {
			if( pointOld && measureDistances) {
				endMeassureDistance( point)
			} else if( !pointOld && measureDistances) {
				startMeassureDistance( point)
			} else {
				textInfoWindow = "" + point.y + ", " + point.x;
				map.openInfoWindowHtml( point, document.createTextNode( "" + point.y + ", " + point.x));
			}         
		}
	});
	GEvent.addListener( map, "moveend", function() {
		loadNodes();
	});
	GEvent.addListener( map, "dragend", function() {
		drEnd = true;
	});
}

function loadNodes() {
   var bounds = map.getBounds();
   var southWest = bounds.getSouthWest();
   var northEast = bounds.getNorthEast();
 
   if (window.XMLHttpRequest) {
       xmlhttp = new XMLHttpRequest();
   } else if (window.ActiveXObject) {
       xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
   }

   xmlhttp.open( "GET", "freifunkmap.php?getArea=" + northEast.lat() + "," + northEast.lng() + "," + southWest.lat() + "," + southWest.lng() + "&z=" + map.getZoom(), true);
   xmlhttp.onreadystatechange = placeNodesXML;
   xmlhttp.send( null);
}   

function placeNodesXML() {
   if( xmlhttp.readyState != 4) return;

   var setInfoWindow = map.getInfoWindow().isHidden();
   var pointInfoWindow = map.getInfoWindow().getPoint();

   // clear the map
   map.clearOverlays();    
   if( connLQ && showLQ) {
       map.getPane( G_MAP_MAP_PANE).removeChild( connLQ);
       showLQ = false;
    }

    if( !setInfoWindow && !drEnd) map.openInfoWindow( pointInfoWindow, textInfoWindow);
    drEnd = false;
    if( nodeZonePolygon) map.addOverlay( nodeZonePolygon);

    // place the distance meassure line
    if( distPolyline) map.addOverlay( distPolyline);

    // place the ring about the search result
    if( isSearch) map.addOverlay( new GMarker( searchPosition, searchResultIcon));

    connPolylines = new Array();
    connLQ = document.createElement( "div");
    connLQ.style.position = "absolute";
    connLQ.style.color = "red";
    connLQ.style.fontSize = "x-small";
                     
 	var nodeListXML = xmlhttp.responseXML;
 	var nodeXML = nodeListXML.getElementsByTagName("node");

   // loop about all nodes
   for( var i = 0; i < nodeXML.length; i++) {
      var tooltip = nodeXML[i].getAttribute('ip');
      var nodeClass = nodeXML[i].getAttribute('nodeclass');
      var coords = (nodeXML[i].getAttribute('coords')).split( ",");

      if( showOlsr && nodeClass.search(/olsr/) != -1) {
         if( nodeClass.search( /zoom/) != -1) {
            map.addOverlay( createZoomNode( new GLatLng( coords[0], coords[1]), "olsr"));
         } else {
            map.addOverlay( createNode( new GLatLng( coords[0], coords[1]), tooltip, "olsr"));
         }
      }
      else if( showBatman && nodeClass.search(/batman/) != -1) {
         if( nodeClass.search( /zoom/) != -1) {
            map.addOverlay( createZoomNode( new GLatLng( coords[0], coords[1]), "batman"));
         } else {
            map.addOverlay( createNode( new GLatLng( coords[0], coords[1]), tooltip, "batman"));
         }
      }

      for (var j = 0; j < nodeXML[i].childNodes.length; j++) {
         with( nodeXML[i].childNodes[j]) {
            if( nodeName == "olsrneighbor" && showOlsr) {
                ncoords = (nodeXML[i].childNodes[j].getAttribute('coords')).split( ",");
                currentNode = new GLatLng( coords[0], coords[1]);
                neighborNode = new GLatLng( ncoords[0], ncoords[1]);
                connPolylines.push( new GPolyline( [ currentNode, neighborNode ], "#FF0000", 2));
                
                var currentPixel = map.fromLatLngToDivPixel( currentNode );
                var neighborPixel = map.fromLatLngToDivPixel( neighborNode);
                var div = document.createElement( "div" );
                div.style.position = "absolute";
                div.style.left = currentPixel.x - ((currentPixel.x - neighborPixel.x) / 4) + "px";
                div.style.top = currentPixel.y - ((currentPixel.y - neighborPixel.y) / 4) + "px";
                div.innerHTML = ( Math.round( nodeXML[i].childNodes[j].getAttribute('lq') * 100)) + "%";
                connLQ.appendChild( div);
            } else if( nodeName == "batmanneighbor" && showBatman) {
                ncoords = (nodeXML[i].childNodes[j].getAttribute('coords')).split( ",");
                currentNode = new GLatLng( coords[0], coords[1]);
                neighborNode = new GLatLng( ncoords[0], ncoords[1]);
                connPolylines.push( new GPolyline( [ currentNode, neighborNode ], "#000000", 2));
                
                var currentPixel = map.fromLatLngToDivPixel( currentNode );
                var neighborPixel = map.fromLatLngToDivPixel( neighborNode);
                var div = document.createElement( "div" );
                div.style.position = "absolute";
                div.style.left = currentPixel.x - ((currentPixel.x - neighborPixel.x) / 4) + "px";
                div.style.top = currentPixel.y - ((currentPixel.y - neighborPixel.y) / 4) + "px";
                div.innerHTML = ( nodeXML[i].childNodes[j].getAttribute('lq')) + "%";
                connLQ.appendChild( div);
            } 
         }
      }
   }
   placeConnections();
   placeLQ();
}

/**
 * creates a new node
 * @param GLatLng point  - the coordinates of the point
 * @param String tooltip - the tooltip to display on mouseover
 * @param String type    - could be one of batman or olsr
 */
function createNode( point, tooltip, type) {
   // on small zoomlevel take a smaller icon
	var icon = new GIcon( mediumicon);
	if( map.getZoom() < 14) {
      if( type == "olsr") { icon = new GIcon( smallicon); }
      else if( type == "batman") { icon = new GIcon( smallblackicon); }
   } else {
      if( type == "olsr") { icon = new GIcon( mediumicon); }
      else if( type == "batman") { icon = new GIcon( mediumblackicon); }
   }

   // create the node as GMarker
	var ffnode = new GMarker( point, { icon: icon, title: tooltip });

   // add mouse click function
	GEvent.addListener(ffnode, 'click', function() {
		if( pointOld && measureDistances) {
			endMeassureDistance( point, ffnode);
		} else if( !pointOld && measureDistances) {
			startMeassureDistance( point, ffnode);
		} else {
         // simple click on a node should display the node informations
         GDownloadUrl("freifunkmap.php?getNode=" + point.y + "," + point.x, function(data, responseCode) {
            var xml = GXml.parse( data);
            var nodeDescription = "";
            if( xml.documentElement.getElementsByTagName("description")[0].firstChild) {
               nodeDescription = xml.documentElement.getElementsByTagName("description")[0].firstChild.data;
            }

            var ips = "";
				if( xml.documentElement.getElementsByTagName("node")[0].getAttribute('ip')) {
				var olsrip = "";
				var batmanip = "";
				if( xml.documentElement.getElementsByTagName("node")[0].getAttribute('ip').split( ",")[0] ) {
					olsrip += "Olsr: " + xml.documentElement.getElementsByTagName("node")[0].getAttribute('ip').split( ",")[0] + "<br />";
				}
							if( xml.documentElement.getElementsByTagName("node")[0].getAttribute('ip').split( ",")[1]) {
								batmanip += "Batman: " + xml.documentElement.getElementsByTagName("node")[0].getAttribute('ip').split( ",")[1] + "<br />";
							}
							ips += olsrip + batmanip;
							if( ips != "") ips += "<br />";
						}

            var antennaDescription = "";
            if( xml.documentElement.getElementsByTagName("antenna")[0]) {
               // parse the antenna informations
               var antenna = xml.documentElement.getElementsByTagName("antenna")[0];
               if( antenna.getAttribute('type') != "") antennaDescription += "<?php echo TEXT_ANTENNA_TYPE; ?>: " + antenna.getAttribute('type') + "<br />";
               if( antenna.getAttribute('gain') != "") antennaDescription += "<?php echo TEXT_ANTENNA_GAIN; ?>: " + antenna.getAttribute('gain') + "dBi<br />";
               if( antenna.getAttribute('angp') != "") antennaDescription += "<?php echo TEXT_ANTENNA_BEAM_W; ?>: " + antenna.getAttribute('angp') + "&deg;<br />";
               if( antenna.getAttribute('ango') != "") antennaDescription += "<?php echo TEXT_ANTENNA_BEAM_O; ?>: " + antenna.getAttribute('ango') + "&deg;<br />";
               if( antenna.getAttribute('vpos') != "") antennaDescription += "<?php echo TEXT_ANTENNA_HEIGHT; ?>: " + antenna.getAttribute('vpos') + "m<br />";
               if( antenna.getAttribute('hdir') != "") antennaDescription += "<?php echo TEXT_ANTENNA_DIRECTION; ?>: " + antenna.getAttribute('hdir') + "&deg;<br />";
               if( antenna.getAttribute('vdir') != "") antennaDescription += "<?php echo TEXT_ANTENNA_TILT; ?>: " + antenna.getAttribute('vdir') + "&deg;<br />";
               if( antenna.getAttribute('pole') != "") antennaDescription += "<?php echo TEXT_ANTENNA_POLARIZATION; ?>: " + antenna.getAttribute('pole') + "<br />";
            }
            textInfoWindow = "<small>" + nodeDescription + "<hr /><p style=\"font-size:x-small;\">" + ips + antennaDescription + "</p></small>";
            ffnode.openInfoWindowHtml( textInfoWindow);
         });
		}
	});
	return ffnode;
}

function createZoomNode( point, type) {
   var icon = new GIcon( mediumicon);
   if( map.getZoom() < 14) icon = new GIcon( smallicon);
   if( type == "old") {
      icon = new GIcon( mediumiconOld);
      if( map.getZoom() < 14) icon = new GIcon( smalliconOld);
   } else if( type == "batman") {
      icon = new GIcon( mediumblackicon);
      if( map.getZoom() < 14) icon = new GIcon( smallblackicon);
   }

	var ffnode = new PdMarker( point, { icon: icon, title: "zoom in" });
   ffnode.setCursor("\"url(freifunkmap_gfx/lens.gif), move\"");

   GEvent.addListener(ffnode, 'click', function() {
      map.setCenter( point, map.getZoom() + 1);
	});
	return ffnode;
}

function startMeassureDistance( point, ffnode) {
   map.removeOverlay( distPolyline);
   distPolyline = false;
   textInfoWindow = "Start";
   if( ffnode) {
      ffnode.openInfoWindowHtml( textInfoWindow);
   } else {
      map.openInfoWindowHtml( point, document.createTextNode( textInfoWindow ));
   }
   pointOld = point;                                                
}

function endMeassureDistance( point, ffnode) {
   var gPointOld = new GLatLng( pointOld.y, pointOld.x, true);
   var gPointNew = new GLatLng( point.y, point.x, true);
   distPolyline = new GPolyline( [ gPointOld, gPointNew ], "#FF0000", 3);
   map.addOverlay( distPolyline);
   var distance = gPointOld.distanceFrom( gPointNew);
   textInfoWindow = "<?php echo TEXT_DISTANCE; ?>: " + Math.round( distance) + " m";
   if( ffnode) {
      ffnode.openInfoWindowHtml( textInfoWindow );
   } else {
      map.openInfoWindowHtml( point, document.createTextNode( textInfoWindow ));
   }
   pointOld = false;
} 

function placeConnections() {
   if( showConn) {
      for( var i = 0; i < connPolylines.length; i++) {
         map.addOverlay( connPolylines[i]);
      }
   } else {
      for( var i = 0; i < connPolylines.length; i++) {
         map.removeOverlay( connPolylines[i]);
      }
   }
}

function placeLQ() {
   if( lqPlaced) {
      map.getPane( G_MAP_MAP_PANE).appendChild( connLQ);
      showLQ = true;
   } else {
      if( connLQ && showLQ) {
         map.getPane( G_MAP_MAP_PANE).removeChild( connLQ);
         showLQ = false;
      }
   } 
}

function RulerControl() {
}
RulerControl.prototype = new GControl();

RulerControl.prototype.initialize = function( map) {
	var container = document.createElement( "div");
	container.title = "<?php echo TEXT_MEASSURE_DISTANCE; ?>";
	var rulerImg = document.createElement( "img");
	rulerImg.src = "freifunkmap_gfx/ruler.png";
	rulerImg.width = "34";
	rulerImg.height = "17";
	rulerImg.style.border = "1px solid black";
	rulerImg.style.cursor = "pointer";
	container.appendChild( rulerImg);
	GEvent.addDomListener( rulerImg, "click", function() {
		if( measureDistances) {
			measureDistances = false;
			rulerImg.src = "freifunkmap_gfx/ruler.png";
			map.removeOverlay( distPolyline);
			distPolyline = false;
		} else {
			measureDistances = true;
			rulerImg.src = "freifunkmap_gfx/ruler_selected.png";
		}
	});
	map.getContainer().appendChild(container);
	return container;
}

RulerControl.prototype.getDefaultPosition = function() {
	return new GControlPosition( G_ANCHOR_TOP_RIGHT, new GSize( 207, 7));
}

function FAQControl() {
}
FAQControl.prototype = new GControl();

FAQControl.prototype.initialize = function( map) {
	var container = getDefaultControlContainer( "<?php echo TEXT_FAQ_DESCRIPTION; ?>");
	 var innerDiv = document.createElement( "div");
	innerDiv.style.borderStyle = "solid";
	innerDiv.style.borderColor = "white rgb(176, 176, 176) rgb(176, 176, 176) white";
	innerDiv.style.borderWidth = "1px";
	innerDiv.appendChild( document.createTextNode( "FAQ"));
	container.appendChild( innerDiv);
	GEvent.addDomListener( container, "click", function() {
		innerDiv.style.borderColor = "rgb(176, 176, 176) white white rgb(176, 176, 176)";
		innerDiv.style.fontWeight = "bold";
		faqwindow = window.open( "http://www.layereight.de/freifunkmap_faq.html", "MapFAQ", "scrollbars=yes,width=600,height=400,left=100,top=200");
		faqwindow.focus();
	});
	GEvent.addDomListener( container, "mouseout", function() {
		innerDiv.style.borderColor = "white rgb(176, 176, 176) rgb(176, 176, 176) white";
		innerDiv.style.fontWeight = "normal";
	});
	map.getContainer().appendChild( container);
	return container;
}

FAQControl.prototype.getDefaultPosition = function() {
	return new GControlPosition(G_ANCHOR_BOTTOM_RIGHT, new GSize( 70, 20));
}

function StatsControl() {
}
StatsControl.prototype = new GControl();

StatsControl.prototype.initialize = function( map) {
	var container = getDefaultControlContainer( "<?php echo TEXT_STATISTICS; ?>");
	var innerDiv = document.createElement( "div");
	innerDiv.style.borderStyle = "solid";
	innerDiv.style.borderColor = "white rgb(176, 176, 176) rgb(176, 176, 176) white";
	innerDiv.style.borderWidth = "1px";
	innerDiv.appendChild( document.createTextNode( "Stats"));
	container.appendChild( innerDiv);
	GEvent.addDomListener( container, "click", function() {
		innerDiv.style.borderColor = "rgb(176, 176, 176) white white rgb(176, 176, 176)";
		innerDiv.style.fontWeight = "bold";
		faqwindow = window.open( "http://www.layereight.de/freifunkmap_stats.html", "MapStats", "scrollbars=yes,width=620,height=490,left=100,top=100");
		faqwindow.focus();
	});
	GEvent.addDomListener( container, "mouseout", function() {
		innerDiv.style.borderColor = "white rgb(176, 176, 176) rgb(176, 176, 176) white";
		innerDiv.style.fontWeight = "normal";
	});
	map.getContainer().appendChild( container);
	return container;
}

StatsControl.prototype.getDefaultPosition = function() {
	return new GControlPosition(G_ANCHOR_BOTTOM_RIGHT, new GSize( 5, 20));
}

function LQControl() {
}
LQControl.prototype = new GControl();

LQControl.prototype.initialize = function( map) {
	var container = getDefaultControlContainer( "<?php echo TEXT_SHOW_LQ_DESCRIPTION; ?>");
	var innerDiv = document.createElement( "div");
	innerDiv.style.borderStyle = "solid";
	innerDiv.style.borderColor = "white rgb(176, 176, 176) rgb(176, 176, 176) white";
	innerDiv.style.borderWidth = "1px";
	innerDiv.appendChild( document.createTextNode( "LQ"));
	container.appendChild( innerDiv);
	GEvent.addDomListener( container, "click", function() {
		if( lqPlaced) {
			lqPlaced = false;
			innerDiv.style.borderColor = "white rgb(176, 176, 176) rgb(176, 176, 176) white";
			innerDiv.style.fontWeight = "normal";
			placeLQ();
		} else {
			lqPlaced = true;
			innerDiv.style.borderColor = "rgb(176, 176, 176) white white rgb(176, 176, 176)";
			innerDiv.style.fontWeight = "bold";
			placeLQ();
		}
	});
	map.getContainer().appendChild( container);
	return container;
}

LQControl.prototype.getDefaultPosition = function() {
	return new GControlPosition( G_ANCHOR_TOP_RIGHT, new GSize( 7, 94));
}

function ConnControl() {
}
ConnControl.prototype = new GControl();

ConnControl.prototype.initialize = function( map) {
	var container = getDefaultControlContainer( "<?php echo TEXT_SHOW_CONN_DESCRIPTION; ?>");
	var innerDiv = document.createElement( "div");
	innerDiv.style.borderStyle = "solid";
   if( showConn) {
      innerDiv.style.borderColor = "rgb(176, 176, 176) white white rgb(176, 176, 176)";
      innerDiv.style.fontWeight = "bold";
   } else {
      innerDiv.style.borderColor = "white rgb(176, 176, 176) rgb(176, 176, 176) white";
      innerDiv.style.fontWeight = "normal";
   }
   innerDiv.style.borderWidth = "1px";
	innerDiv.appendChild( document.createTextNode( "Conn"));
	container.appendChild( innerDiv);
	GEvent.addDomListener( container, "click", function() {
		if( showConn) {
			showConn = false;
			innerDiv.style.borderColor = "white rgb(176, 176, 176) rgb(176, 176, 176) white";
			innerDiv.style.fontWeight = "normal";
			placeConnections();
		} else {
			showConn = true;
			innerDiv.style.borderColor = "rgb(176, 176, 176) white white rgb(176, 176, 176)";
			innerDiv.style.fontWeight = "bold";
			placeConnections();
		}
	});
	map.getContainer().appendChild( container);
	return container;
}
ConnControl.prototype.getDefaultPosition = function() {
	return new GControlPosition( G_ANCHOR_TOP_RIGHT, new GSize( 7, 74));
}

function OlsrControl() {
}
OlsrControl.prototype = new GControl();

OlsrControl.prototype.initialize = function( map) {
  	var container = getDefaultControlContainer( "<?php echo TEXT_SHOW_OLSR_DESCRIPTION; ?>");
	var innerDiv = document.createElement( "div");
	innerDiv.style.borderStyle = "solid";
	innerDiv.style.borderColor = "rgb(176, 176, 176) white white rgb(176, 176, 176)";
   innerDiv.style.fontWeight = "bold";
	innerDiv.style.borderWidth = "1px";
	innerDiv.appendChild( document.createTextNode( "olsr"));
	container.appendChild( innerDiv);
	GEvent.addDomListener( container, "click", function() {
		if( showOlsr) {
			showOlsr = false;
			innerDiv.style.borderColor = "white rgb(176, 176, 176) rgb(176, 176, 176) white";
			innerDiv.style.fontWeight = "normal";
			placeNodesXML();
		} else {
			showOlsr = true;
			innerDiv.style.borderColor = "rgb(176, 176, 176) white white rgb(176, 176, 176)";
			innerDiv.style.fontWeight = "bold";
			placeNodesXML();
		}
	});
	map.getContainer().appendChild( container);
	return container;
}

OlsrControl.prototype.getDefaultPosition = function() {
   return new GControlPosition( G_ANCHOR_TOP_RIGHT, new GSize( 7, 34));
}

function BatmanControl() {
}
BatmanControl.prototype = new GControl();

BatmanControl.prototype.initialize = function( map) {
  	var container = getDefaultControlContainer( "<?php echo TEXT_SHOW_BATMAN_DESCRIPTION; ?>");
	var innerDiv = document.createElement( "div");
	innerDiv.style.borderStyle = "solid";
	innerDiv.style.borderColor = "white rgb(176, 176, 176) rgb(176, 176, 176) white";
	innerDiv.style.borderWidth = "1px";
	innerDiv.appendChild( document.createTextNode( "batman"));
	container.appendChild( innerDiv);
	GEvent.addDomListener( container, "click", function() {
		if( showBatman) {
			showBatman = false;
			innerDiv.style.borderColor = "white rgb(176, 176, 176) rgb(176, 176, 176) white";
			innerDiv.style.fontWeight = "normal";
			placeNodesXML();
		} else {
			showBatman = true;
			innerDiv.style.borderColor = "rgb(176, 176, 176) white white rgb(176, 176, 176)";
			innerDiv.style.fontWeight = "bold";
			placeNodesXML();
		}
	});
	map.getContainer().appendChild( container);
	return container;
}

BatmanControl.prototype.getDefaultPosition = function() {
   return new GControlPosition( G_ANCHOR_TOP_RIGHT, new GSize( 7, 54));
}

function NewSearchControl() { 
}
NewSearchControl.prototype = new GControl();

NewSearchControl.prototype.initialize = function( map) {
 	var container = document.createElement( "div");
	container.title = "<?php echo TEXT_SEARCH_BUTTON_DESCRIPTION; ?>";
	var connForm = document.createElement( "form");
	connForm.name = "ffmapForm";
	connForm.onsubmit ="newSearch();";
	connForm.action = "javascript:newSearch();";
	var connInputText = document.createElement( "input");
	connInputText.type = "text";
	connInputText.name = "searchinput";
	connInputText.size = "30";
	connInputText.maxlength = "30";
	connInputText.style.fontSize = "70%";
	connInputText.tabindex = "1";

	var outerDiv = document.createElement( "div");
   var outerDivClassAttr = document.createAttribute( "class");
   outerDivClassAttr.nodeValue = "gmnoprint";
   outerDiv.setAttributeNode( outerDivClassAttr);
	outerDiv.style.border = "1px solid black";
	outerDiv.style.backgroundColor = "white";
	outerDiv.style.textAlign = "center";
	outerDiv.style.width = "5em";
	outerDiv.style.cursor = "pointer";
	outerDiv.style.fontFamily = "Arial,sans-serif";
	outerDiv.style.fontSize = "12px";
	outerDiv.style.mozUserSelect = "none";
	outerDiv.title = "<?php echo TEXT_SEARCH_BUTTON_DESCRIPTION; ?>";
	outerDiv.tabindex = "2";
	var innerDiv = document.createElement( "div");
	innerDiv.style.borderStyle = "solid";
	innerDiv.style.borderColor = "white rgb(176, 176, 176) rgb(176, 176, 176) white";
	innerDiv.style.borderWidth = "1px";
	innerDiv.appendChild( document.createTextNode( "<?php echo TEXT_SEARCH; ?>"));
	outerDiv.appendChild( innerDiv);
	
	var connTable = document.createElement( "table");
	var connTr = document.createElement( "tr");
	var connTd1 = document.createElement( "td");
	connTd1.valign = "middle";
	var connTd2 = document.createElement( "td");
	connTd2.valign = "middle"
	connTd1.appendChild( connInputText);
	connTd2.appendChild( outerDiv);
	connTr.appendChild( connTd1);
	connTr.appendChild( connTd2);
	connTable.appendChild( connTr);
	connForm.appendChild( connTable);
	container.appendChild( connForm);

	resultDiv = document.createElement( "div");
	var classAttr = document.createAttribute( "class");
	classAttr.nodeValue = "searchResult";
	resultDiv.setAttributeNode( classAttr);
	
	resultDiv.style.position = "absolute";
	resultDiv.style.top = "100px";
	resultDiv.style.left = "80px";
	resultDiv.style.width = "500px";
	newSearchH1 = document.createElement( "h2");
	newSearchH1.appendChild( document.createTextNode( "<?php echo TEXT_SEARCH_RESULT; ?>"));
	newSearchH1.align = "center";
	resultDiv.appendChild( newSearchH1);
	resultDiv.appendChild( document.createElement( "br"));
	resultDiv.appendChild( document.createElement( "br"));
		
 	GEvent.addDomListener( outerDiv, "click", function () {
 		innerDiv.style.borderColor = "rgb(176, 176, 176) white white rgb(176, 176, 176)";
		innerDiv.style.fontWeight = "bold";
 		newSearch();
 	});
  
  GEvent.addDomListener( outerDiv, "mouseout", function() {
		innerDiv.style.borderColor = "white rgb(176, 176, 176) rgb(176, 176, 176) white";
		innerDiv.style.fontWeight = "normal";
	});
	
	map.getContainer().appendChild( container);
	return container;
}

NewSearchControl.prototype.getDefaultPosition = function() {
	return new GControlPosition( G_ANCHOR_BOTTOM_RIGHT, new GSize( 132, 16));
}

function searchResultClickHandling( searchLat, searchLng) {
	searchPosition = new GLatLng( searchLat, searchLng);
	map.closeInfoWindow();
	map.panTo( searchPosition);
	isSearch = true;
}

function searchResultClose() {
	map.getContainer().removeChild( resultDiv);
}

function newSearch() {
		showSearchResult = true;
		resultDiv.innerHTML = "";
		var newSearchTable = document.createElement("table");
		newSearchTable.width = "100%";
		var newSearchTr = document.createElement("tr");
		var newSearchTd = document.createElement("td");
		var newSearchTd2 = document.createElement("td");
		newSearchTd2.width = "5px";
		newSearchTd.align = "right";
		
		newSearchCloseLink = document.createElement("a");
		newSearchCloseLink.href = "javascript:searchResultClose();";
		
		newSearchCloseImg = document.createElement("img");
		newSearchCloseImg.src = "freifunkmap_gfx/search_result_close.png";
		newSearchCloseImg.style.position = "absolute";
		newSearchCloseImg.style.top = "0px";
		newSearchCloseImg.style.width = "12px";
		newSearchCloseImg.style.height = "12px";
		newSearchCloseImg.border = "0";
		newSearchCloseLink.appendChild( newSearchCloseImg);
		// newSearchTd.appendChild( newSearchCloseImg);
		newSearchTd.appendChild( newSearchCloseLink);
		newSearchTr.appendChild( newSearchTd);
		newSearchTr.appendChild( newSearchTd2);
		newSearchTable.appendChild( newSearchTr);
		
		// resultDiv.appendChild( newSearchCloseImg);
		resultDiv.appendChild( newSearchTable);
		
		newSearchH1 = document.createElement( "h2");
		newSearchH1.appendChild( document.createTextNode( "<?php echo TEXT_SEARCH_RESULT; ?>"));
		newSearchH1.align = "center";
		resultDiv.appendChild( newSearchH1);
		
		GDownloadUrl("freifunkmap.php?newsearch=" + document.ffmapForm.searchinput.value, function( data, responseCode) {
			var xml = GXml.parse( data);
			var resultText = "";
						
			for( i = 0; i < xml.getElementsByTagName("node").length; i++) {
				resultDiv.appendChild( document.createTextNode((i + 1) + ". "));
				resultLink = document.createElement("a");
				resultLinkAttrHref = document.createAttribute( "href");
				var resultCoords = xml.getElementsByTagName("node")[i].getAttribute('coords');
				resultLink.href = "javascript:searchResultClickHandling(" + resultCoords + ");";
				resultLink.appendChild( document.createTextNode( resultCoords));
				
				resultDiv.appendChild( resultLink);
				resultDiv.appendChild( document.createTextNode( " " + xml.getElementsByTagName("node")[i].getAttribute('ip')));
				resultDiv.appendChild( document.createElement( "br"));
				if( i > 18) break;
			}
			
			map.getContainer().appendChild( resultDiv);				
	});
}

function getDefaultControlContainer( title) {
	var container = document.createElement( "div");
	container.title = title;
	container.style.border = "1px solid black";
	container.style.position = "absolute";
	container.style.backgroundColor = "white";
	container.style.textAlign = "center";
	container.style.width = "5em";
	container.style.cursor = "pointer";
	container.style.fontFamily = "Arial,sans-serif";
	container.style.fontSize = "12px";
	container.style.right = "11em";
	return container;
}

//]]>
