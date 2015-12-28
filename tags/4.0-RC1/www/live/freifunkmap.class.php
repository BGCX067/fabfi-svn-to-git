<?php
/**
Copyright (C) 2007 Gerald Schnabel
*/

require_once( "freifunkmap.conf.php");

class freifunkMap 
{
	/** the databaseconnection sqlite */
	private $db;
	/** configures the minimum length between two nodes in meters */
	private $maxDist = array( "653760", "326880", "163440", "81720", "40960", "20480", "10240", "5120", "2560", "1280", 
		"640", "320", "160", "80", "40", "20", "10", "5", "5", "0", "0", "0");
	
	/**
	 * 
	 */
	public function __construct() {
		if( !$this->db = sqlite_open( PATH_TO_DATABASE.DATABASE_FILE, 0666, $sqliteerror)) {
			exit( $sqliteerror);
		}
	}
	
	/**
	 * if the PATH_TO_DATABASE writeable for the webuser, this will create the database file
	 * with the table 'nodes' and the columns 'timestamp', 'updateiv', 'nodelat', 'nodelng', 'olsrlinks' and 'note'
	 */
   public function install( ) {
      sqlite_query($this->db, 'CREATE TABLE nodes (
         timestamp varchar(10), 
         updateiv varchar(10), 
         nodelat REAL, 
         nodelng REAL,
         olsrip varchar(15),
         olsrlinks varchar(4096), 
         batmanip varchar(15),
         batmanlinks varchar(4096),
         note varchar(4096));', SQLITE_ASSOC, $sqliteerror);
      if( $sqliteerror) exit( $sqliteerror);
   }
	
	/**
	 *
	 */
	public function update( $updateString, $updateintervall, $note, $olsrip = "", $batmanip = "", $batmanconn = "") {
		$update = self::check( $updateString);

		$batmanlinks = "";

		// get the latitude, the longitude and the rest (neighbors)
		preg_match( "/^(-?[0-9]{1,3}\.[0-9]{1,16})\s*,\s*(-?[0-9]{1,3}\.[0-9]{1,16})\s*,?\s*(.*)/", $updateString, $matches);
		if( $matches[1] ==  "" || $matches[2] == "") {
			exit( "lat or lng zero, no update");
		}

		$neighbordata = "";
		$neighbors = explode( ",", $matches[3]);
		$i = 0;
		if( count( $neighbors) > 2) {
			// save allready printed Neighbors, to print every neighbor only once, (someone want to corrupt the system)
			$printedNeighbors = array();
			// loop about all neighbors
			while( $i < count( $neighbors)) {
			  $dist = self::getDistance( $matches[1], $matches[2], $neighbors[$i], $neighbors[$i + 1]);
			  $olsrlinks = ltrim($neighbors[$i++].",".$neighbors[$i++]);
			  // links over more than 20000m seem to be not realistic, ignore them
			  if( $dist > $this->maxDist[$zoomLevel] && $dist < 20000 && !in_array( $olsrlinks, $printedNeighbors)) {
		      if( $neighbordata != "") $neighbordata .= ", ";
		      array_push( $printedNeighbors, $olsrlinks);
		      $neighbordata .= $olsrlinks.",".$neighbors[$i++];
			  } else {
		      $i++;
			  }
			}
		} 

      $batmanneighbordata = "";
		$batmanneighbors = explode( ",", $batmanconn);
		$i = 0;
		if( count( $batmanneighbors) > 2) {
			// save allready printed Neighbors, to print every neighbor only once, (someone want to corrupt the system)
			$printedNeighbors = array();
			// loop about all neighbors
			while( $i < count( $batmanneighbors)) {
			  $dist = self::getDistance( $matches[1], $matches[2], $batmanneighbors[$i], $batmanneighbors[$i + 1]);
			  $batmanlinks = ltrim($batmanneighbors[$i++].",".$batmanneighbors[$i++]);
			  // links over more than 20000m seem to be not realistic, ignore them
			  if( $dist > $this->maxDist[$zoomLevel] && $dist < 20000 && !in_array( $batmanlinks, $printedNeighbors)) {
		      if( $batmanneighbordata != "") $batmanneighbordata .= ", ";
		      array_push( $printedNeighbors, $batmanlinks);
		      $batmanneighbordata .= $batmanlinks.",".$batmanneighbors[$i++];
			  } else {
		      $i++;
			  }
			}
		}

		$timestamp = time();
		if( $updateintervall == "") $updateintervall = DEFAULT_UPDATEINTERVALL;

		// check node information
		// TODO: is this correct?
		$note = str_replace( "", "\n", $note);
		$note = str_replace( "\xa7", "$", $note);
      $note = str_replace( "\xc2", "", $note);
		$note = htmlentities( $note);
		$note = str_replace( "\\&quot;", "&quot;", $note);
		$note = str_replace( "\n", "<br />", $note);
		$note = str_replace( "\'", "'", $note);
		$note = utf8_encode( rtrim( $note));
		
		$found = -1;
		$result = sqlite_query($this->db, "SELECT * FROM nodes WHERE nodelat = '".$matches[1]."' AND nodelng = '".$matches[2]."';", SQLITE_ASSOC, $sqliteerror);
		if( $sqliteerror) exit( $sqliteerror);
		$found = sqlite_num_rows($result);
      
		if( $found == 0) {
         $result = sqlite_query($this->db, 
            "INSERT INTO nodes VALUES( '$timestamp', 
						                           '$updateintervall', 
						                           '$matches[1]', 
						                           '$matches[2]',
						                           '$olsrip',
						                           '$neighbordata',
						                           '$batmanip',
						                           '$batmanneighbordata',
						                           \"$note\")", 
            SQLITE_ASSOC, $sqliteerror);
         if( $sqliteerror) exit( $sqliteerror);
      } elseif( $found == 1) {
         $result = sqlite_query($this->db, 
            "UPDATE nodes SET timestamp='$timestamp', 
               updateiv='$updateintervall',
					olsrip='$olsrip', 
               olsrlinks='$neighbordata', 
					batmanip='$batmanip',
					batmanlinks='$batmanneighbordata',
               note=\"$note\" WHERE nodelat='$matches[1]' AND nodelng='$matches[2]';", 
            SQLITE_ASSOC, $sqliteerror);
         if( $sqliteerror) exit( $sqliteerror);
      } else {
         exit( "error during update: found node more than once, this should never happend");
      }
   }
	
   /**
	 * 
	 */
	public function dump( ) {
		// $this->remove( 52.595295555557, 13.368696111111);
		$result = sqlite_query( $this->db, "SELECT * FROM nodes ORDER BY timestamp;", SQLITE_ASSOC, $sqliteerror);
		if( $sqliteerror) exit( $sqliteerror);
		return sqlite_fetch_all( $result, SQLITE_ASSOC);
	}
	
	public function newSearch( $searchString) {
		header('Content-type: text/xml');
		echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
		echo "<ffmap version=\"1.0\">";
		$xmlContent = array();
		
      $query = "SELECT * FROM nodes WHERE note LIKE '%".$searchString."%' OR olsrip LIKE '%".$searchString."%' OR batmanip LIKE '%".$searchString."%' AND updateiv != 99999;";
		$result = sqlite_query( $this->db, $query, SQLITE_ASSOC, $sqliteerror);
		
		if( $sqliteerror) exit( $sqliteerror);
		
		foreach( sqlite_fetch_all( $result, SQLITE_ASSOC) as $entry) {
			$zoomNode = false;
			$xmlNode = "";
			$nodeClass = ( $entry['updateiv'] == 99999) ? "nodeclass=\"old\"" : "";
			$note = $this->prepareNodeInformation( $entry['note']);
			$nodeip = ( $entry['olsrip'] != "") ?	$noteip = $entry['olsrip'] : "";
			$nodeip = ( $entry['batmanip'] != "" && $nodeip != "") ? $nodeip.",".$entry['batmanip'] : ($entry['batmanip'] == "") ? $nodeip : $entry['batmanip'];
		
			$xmlNode .= "<node coords=\"".$entry['nodelat'].", ".$entry['nodelng']."\" ".
			            "ip=\"".$nodeip."\" ".$nodeClass.">";
		
			$details = explode(",", $lod);
			$xmlNode .= "<description>".$note['description']."</description>";
                                
			$xmlNode .= "</node>";

    	if( !$zoomNode && $entry['updateiv'] != 99999) {	
    		$xmlContent[$entry['nodelat'].",".$entry['nodelng']] = $xmlNode;
			} else if( !$zoomNode && $entry['updateiv'] == 99999) {
				$xmlOldContent[$entry['nodelat'].",".$entry['nodelng']] = $xmlNode;
			}
		}
      
		foreach( $xmlContent as $entry) {
			echo $entry;
		}
		echo "</ffmap>\n";
	}

   /**
    * 
    * @return: all Nodes from the specified area xml formated
    */
	public function getArea( $northEastLat, $northEastLng, $southWestLat, $southWestLng, $zoomLevel = 19, $lod = "") {
		header('Content-type: text/xml');
      
		echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
		echo "<ffmap version=\"1.0\">";
		$xmlContent = array();
		$xmlOldContent = array();

		$result = sqlite_query( $this->db, 
		    "SELECT * FROM nodes WHERE nodelat BETWEEN ".$southWestLat." AND ".$northEastLat." AND 
		                              nodelng BETWEEN ".$southWestLng." AND ".$northEastLng.";",
		    SQLITE_ASSOC, $sqliteerror);
		if( $sqliteerror) exit( $sqliteerror);

		foreach( sqlite_fetch_all( $result, SQLITE_ASSOC) as $entry) {
			// only nodes wich are updates within the double of the updateintervall
			if( $entry['timestamp'] + ( 2 * $entry['updateiv'] ) < time()) {
			  if( $entry['updateiv'] != 99999) {
			      $this->remove( $entry['nodelat'], $entry['nodelng']);
			      continue;
			  }
			}
		    
			$zoomNode = false;
			$xmlNode = "";
			$nodeClass = ( $entry['updateiv'] == 99999) ? "old" : "olsr";
			$note = $this->prepareNodeInformation( $entry['note']);
			$nodeip = "";
         if( $entry['olsrip'] != "") {
            ( $nodeip != "") ? $nodeip .= ",".$entry['olsrip'] : $nodeip = $entry['olsrip'];
            // $nodeClass = "olsr,".$nodeClass;
            ( $nodeClass != "") ? $nodeClass .= ",olsr" : $nodeClass = "olsr";
         }
         if( $entry['batmanip'] != "") {
            ( $nodeip != "") ? $nodeip .= ",".$entry['batmanip'] : $nodeip = $entry['batmanip'];
            //$nodeip = $nodeip.$entry['batmanip'];
            ( $nodeClass != "") ? $nodeClass .= ",batman" : $nodeClass = "batman";
         }

			$xmlNode .= "<node coords=\"".$entry['nodelat'].", ".$entry['nodelng']."\" ".
			            "ip=\"".$nodeip."\" nodeclass=\"".$nodeClass."\">";

         $details = explode(",", $lod);
         if( in_array( "description", $details)) {
            $xmlNode .= "<description>".$note['description']."</description>";
         }
                                     
         if( in_array( "antenna", $details)) {
            $xmlNode .= "<antenna ".$note['antenna']."/>";
         }
        
         $neighbors = explode( ",", $entry['olsrlinks']);
         $i = 0;
         if( count( $neighbors) > 2) {
            while( $i < count( $neighbors)) {
               $dist = self::getDistance( $entry['nodelat'], $entry['nodelng'], $neighbors[$i], $neighbors[$i+1]);
               $existsres = sqlite_query( $this->db, 
                  "SELECT * FROM nodes WHERE nodelat='".ltrim( $neighbors[$i])."' AND nodelng='".ltrim( $neighbors[$i+1])."';", 
                  SQLITE_ASSOC, $sqliteerror);
               $exists = sqlite_num_rows( $existsres) > 0 ? true : false;
               if( $sqliteerror) exit( $sqliteerror);
               
               if( $dist > $this->maxDist[$zoomLevel] && $exists) {
                  $olsrlinks = ltrim($neighbors[$i++].",".$neighbors[$i++]);
                  $xmlNode .= "<olsrneighbor coords=\"".$olsrlinks."\" lq=\"".$neighbors[$i++]."\" />";
               } else {
                  $i = $i + 3;
               }
            }
         }
         $neighbors = explode( ",", $entry['batmanlinks']);
         $i = 0;
         if( count( $neighbors) > 2) {
            while( $i < count( $neighbors)) {
               $dist = self::getDistance( $entry['nodelat'], $entry['nodelng'], $neighbors[$i], $neighbors[$i+1]);
               $existsres = sqlite_query( $this->db, 
                  "SELECT * FROM nodes WHERE nodelat='".ltrim( $neighbors[$i])."' AND nodelng='".ltrim( $neighbors[$i+1])."';", 
                  SQLITE_ASSOC, $sqliteerror);
               $exists = sqlite_num_rows( $existsres) > 0 ? true : false;
               if( $sqliteerror) exit( $sqliteerror);
               
               if( $dist > $this->maxDist[$zoomLevel] && $exists) {
                  $batmanlinks = ltrim($neighbors[$i++].",".$neighbors[$i++]);
                  $xmlNode .= "<batmanneighbor coords=\"".$batmanlinks."\" lq=\"".$neighbors[$i++]."\" />";
               } else {
                  $i = $i + 3;
               }
            }
         }


         $xmlNode .= "</node>";

         // summarize nodes to zoomNodes if they are close to another accordingly to the zoomLevel
         if( $entry['updateiv'] != 99999) {
            foreach( $xmlContent as $key => $value) {
               $placedCoords = explode( ",", $key);
               $dist = self::getDistance( $entry['nodelat'], $entry['nodelng'], $placedCoords[0], $placedCoords[1]);
               if( $dist < $this->maxDist[$zoomLevel + 2]) {
                  $pattern = "/nodeclass=\"([,A-Za-z]*)\">(.*)<\/node>/";
                  preg_match( $pattern, $value, $matches1);
                  preg_match( $pattern, $xmlNode, $matches2);
                  $allClasses = implode(",", array_unique( explode( ",", "zoom,".$matches1[1].",".$matches2[1])));
                  $xmlContent[$key] = "<node coords=\"".$key."\" nodeclass=\"".$allClasses."\">".$matches1[2].$matches2[2]."</node>";
                  $zoomNode = true;
                  break;
               }
            }
         } else {
            /* ignore old nodes
            foreach( $xmlOldContent as $key => $value) {
               $placedCoords = explode( ",", $key);
               $dist = self::getDistance( $entry['nodelat'], $entry['nodelng'], $placedCoords[0], $placedCoords[1]);
               if( $dist < $this->maxDist[$zoomLevel + 2]) {
                  $xmlOldContent[$key] = "<node coords=\"".$key."\" class=\"oldzoom\"></node>";
                  $zoomNode = true;
                  break;
               }
            }
            */
         }
         
         if( !$zoomNode && $entry['updateiv'] != 99999) {
            $xmlContent[$entry['nodelat'].",".$entry['nodelng']] = $xmlNode;
         } else if( !$zoomNode && $entry['updateiv'] == 99999) {
            $xmlOldContent[$entry['nodelat'].",".$entry['nodelng']] = $xmlNode;
         }
      }
      
      foreach( $xmlContent as $entry) {
            echo $entry;
      }
      foreach( $xmlOldContent as $entry) {
            echo $entry;
      } 
      echo "</ffmap>\n";
   }

	/**
	 *
	 */
	public function getNode( $nodelat, $nodelng) {
		$query = "SELECT * FROM nodes WHERE nodelat='$nodelat' AND nodelng='$nodelng';";
		$result = sqlite_query( $this->db, $query, SQLITE_ASSOC, $sqliteerror);
		if( $sqliteerror) exit( $sqliteerror);
      
		if( $entry = sqlite_fetch_array( $result, SQLITE_ASSOC)) {
			header('Content-type: text/xml');
			echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
			echo "<ffmap version=\"1.0\">";

			$nodeClass = ( $entry['updateiv'] == 99999) ? $nodeClass = "nodeclass=\"old\"" : "";
         $note = $this->prepareNodeInformation( $entry['note']);
			$nodeip = $entry['olsrip'].",".$entry['batmanip'];
			
			echo "<node coords=\"".$entry['nodelat'].", ".$entry['nodelng']."\" ip=\"".$nodeip."\" ".$nodeClass.">";
			
			$neighbors = explode( ",", $entry['olsrlinks']);
         $i = 0;
			if( count( $neighbors) > 2) {
            while( $i < count( $neighbors)) {
               $olsrlinks = ltrim($neighbors[$i++].",".$neighbors[$i++]);
				   echo "<neighbor coords=\"".$olsrlinks."\" lq=\"".$neighbors[$i++]."\" />";
			   }
         }

         echo "<description>".$note['description']."</description>";
         if( $note['antenna'] != "") echo "<antenna ".$note['antenna']." />";
            echo "</node></ffmap>";
			}         
   }
   
   /**
    * print a xml file to use with GoogleEarth
    */
   public function getGoogleEarthKMLFile( ) {
   	header('Content-type: text/xml');
		$xw = new xmlWriter();
    $xw->openMemory();
   
    $xw->startDocument('1.0','UTF-8');
    $xw->startElement ('kml'); 
    $xw->writeAttribute( 'xmlns', 'http://earth.google.com/kml/2.1');
  
    $xw->startElement('Document');   
    $xw->writeElement ('name', 'Freifunknetz');
   
    $xw->startElement('Style');
  	  $xw->writeAttribute( 'id', 'hna');
  	  $xw->startElement('IconStyle');
		    $xw->writeRaw('<color>bfffffff</color>');
  		  $xw->writeRaw('<Icon><href>http://maps.google.com/mapfiles/kml/pal4/icon25.png</href></Icon><ListStyle></ListStyle>');
  	  $xw->endElement();
  	$xw->endElement();
  	$xw->startElement('Style');
  	  $xw->writeAttribute( 'id', 'node');
  	  $xw->startElement('IconStyle');
		    $xw->writeRaw('<color>bfffffff</color>');
  		  $xw->writeRaw('<Icon><href>http://maps.google.com/mapfiles/kml/pal3/icon61.png</href></Icon>');
  	  $xw->endElement();
  	$xw->endElement();
  	$xw->writeRaw('<Style id="strong"><LineStyle><color>e0ff9999</color><width>3</width></LineStyle></Style>');
  	$xw->writeRaw('<Style id="medium"><LineStyle><color>e066cc66</color><width>2</width></LineStyle></Style>');
  	$xw->writeRaw('<Style id="weak"><LineStyle><color>e0333399</color><width>1</width></LineStyle></Style>');

		$xw->startElement('Folder');
			$xw->writeRaw('<name>Nodes</name><open>0</open>');
			foreach( $this->dump( ) as $entry) {
				if( $entry['updateiv'] == 99999) continue;

            $note = $this->prepareNodeInformation( $entry['note']);

				$xw->startElement('Placemark');
					$xw->writeRaw('<name>'.$note['tooltip'].'</name>');
					$xw->startElement('LookAt');
						$xw->writeRaw('<longitude>'.$entry['nodelng'].'</longitude>');
						$xw->writeRaw('<latitude>'.$entry['nodelat'].'</latitude>');
						$xw->writeRaw('<altitude>0</altitude><tilt>0</tilt><heading>0</heading>');
					$xw->endElement();
					$xw->writeRaw('<styleUrl>#node</styleUrl>');
					$xw->startElement('Point');
						$xw->writeRaw('<coordinates>'.$entry['nodelng'].','.$entry['nodelat'].',0</coordinates>');
					$xw->endElement();
	   	   $xw->endElement(); // Placemark
    		}			
  	      $xw->endElement(); // Folder
  	
  	      $xw->startElement('Folder');
  		$xw->writeRaw('<name>Links</name><open>0</open>');
  		foreach( $this->dump( ) as $entry) {
				if( $entry['updateiv'] == 99999) continue;
				$neighbors = explode( ",", $entry['olsrlinks']);
        $i = 0;
        if( count( $neighbors) > 2) {
        	while( $i < count( $neighbors)) {
        		$xw->startElement('Placemark');
        		$neighborLat = ltrim($neighbors[$i++]);
        		$neighborLng = $neighbors[$i++];
        		$neighborLQ  = $neighbors[$i++];
        		if( $neighborLQ <= 1.00 && $neighborLQ >= 0.80) {
	        		$xw->writeRaw('<name>'.$neighborLQ.'</name><styleUrl>#strong</styleUrl>');
	        	}
	        	if( $neighborLQ < 0.80 && $neighborLQ >= 0.40) {
	        		$xw->writeRaw('<name>'.$neighborLQ.'</name><styleUrl>#medium</styleUrl>');
	        	}
	        	if( $neighborLQ < 0.40 && $neighborLQ >= 0.00) {
	        		$xw->writeRaw('<name>'.$neighborLQ.'</name><styleUrl>#weak</styleUrl>');
	        	}
        		$xw->startElement('MultiGeometry');
        			$xw->startElement('LineString');
        				$xw->writeRaw('<coordinates>'.$entry['nodelng'].','.$entry['nodelat'].',0 '.$neighborLng.','.$neighborLat.',0</coordinates>');
        			$xw->endElement();
        		$xw->endElement();
	 	        $xw->endElement();
        	}
        }
      }
  	
    $xw->endElement();
    $xw->endDocument();
   
    print $xw->outputMemory(true);   }

   /**
    *
    */
   public function remove( $nodelat, $nodelng) {
      $query = "DELETE FROM nodes WHERE nodelat='$nodelat' AND nodelng='$nodelng';";
      // $query = "DELETE FROM nodes WHERE timestamp='1179330568';";
      // $query = "DELETE FROM nodes WHERE nodelat='52.595295555557' AND nodelng='13.368696111111';";
      $result = sqlite_query( $this->db, $query, SQLITE_ASSOC, $sqliteerror);

      // if( $sqliteerror) exit( $sqliteerror);
   }

   /**
    *
    */
   public function search( $searchString) {
      $query = "SELECT * FROM nodes WHERE note LIKE '%".$searchString."%' AND updateiv != 99999;";
      $result = sqlite_query( $this->db, $query, SQLITE_ASSOC, $sqliteerror);

      if( $sqliteerror) exit( $sqliteerror);

      if( sqlite_num_rows($result) == 0 || $searchString == "") return "";
      
      $entry = sqlite_fetch_array( $result, SQLITE_ASSOC);
      return $entry['nodelat'].",".$entry['nodelng'];
   }

   /**
    * @return : an array with ...
    */
   public function prepareNodeInformation( $string) {
      // $return = new array();
      // $$_HF-Info(A_type:4Quad_11;A_gain:11-12;A_angP:65;A_angO:35;A_Vpos:42;A_Hdir:292,5;A_Vdir:-2;A_PolE:H;)HF-Info_$$  
      $pattern = "/(.*)(.._HF-Info.*HF-Info_..$)/";
      preg_match( $pattern, $string, $matches);

      if( $matches[2] == "") $matches[1] = $string;

      // prepare note
      $note = str_replace( "&szlig;", "ß", $matches[1]);
      $note = str_replace( "&uuml;", "ü", $note);
      $note = str_replace( "&auml;", "ä", $note);
      $note = str_replace( "&ouml;", "ö", $note);
      $note = str_replace( "&Uuml;", "Ü", $note);
      $note = str_replace( "&Auml;", "Ä", $note);
      $note = str_replace( "&Ouml;", "Ö", $note);
      $note = str_replace( "&acute;", "'", $note);
      $note = str_replace( "&eacute;", "é", $note);
      $note = str_replace( "&iuml;", "ï", $note);
      $note = str_replace( "&iquest;", "¿", $note);
      $note = str_replace( "&frac12;", "½", $note);
		$note = str_replace( "&Acirc;", "Â", $note);
      $note = str_replace( "<", "&lt;", $note);
      $note = str_replace( ">", "&gt;", $note);

      // prepare tooltip
      $tooltip = html_entity_decode( $note);
      $tooltip = strip_tags( $tooltip);
      // $tooltip = str_replace( "&", "", $tooltip);
      if( 30 < strlen( $tooltip)) $tooltip = substr( $tooltip, 0, 30)."...";
      $tooltip = str_replace( "\\\"", "&quot;", $tooltip);
      $tooltip = str_replace( "\"", "&quot;", $tooltip);
      
      // prepare antenna
      $pattern = "/.._HF-Info\(A_type:(.*);A_gain:(.*);A_angP:(.*);A_angO:(.*);A_Vpos:(.*);A_Hdir:(.*);A_Vdir:(.*);A_PolE:(.*);\)HF-Info_../";
      preg_match( $pattern, $string, $matches);
      $antenna = " type=\"".$matches[1]."\" gain=\"".$matches[2]."\" angp=\"".$matches[3]."\" ango=\"".$matches[4]."\" vpos=\"".$matches[5]."\" hdir=\"".$matches[6]."\" vdir=\"".$matches[7]."\" pole=\"".$matches[8]."\"";

      $return['description'] = $note;
      $return['antenna'] = $antenna;
      $return['tooltip'] = $tooltip;

      return $return;
   }
	
	/**
	 * 
	 */
	static public function check( $updateString) {
		$tmpUpdateString = explode( ",", $updateString);
		$newUpdateString = "";
		$pattern="/([0-9]{1,3}\.?[0-9]{0,15})/";
		if( count( $tmpUpdateString) < 2) {
		   exit( "error with given coordinates: $updateString this is not on our earth ;)");
		}
		$i = 0;
		preg_match( $pattern, $tmpUpdateString[$i++], $matches1);
		preg_match( $pattern, $tmpUpdateString[$i++], $matches2);
      if( $matches1[1] == "" || $matches2[1] == "") {
         echo( "matches1[1] : ".$matches1[1]."\n");
         echo( "matches2[1] : ".$matches2[1]."\n");
         exit( "error with given coordinates: $updateString this is not on our earth ;)");
      }
		$newUpdateString = $matches1[1].", ".$matches2[1];
		while( $i < count( $tmpUpdateString)) {
			preg_match( $pattern, $tmpUpdateString[$i++], $matches1);
			preg_match( $pattern, $tmpUpdateString[$i++], $matches2);
         preg_match( "/([0-1]\.?[0-9]{1,2})/", $tmpUpdateString[$i], $matches3);
			if( $matches1[1] != "" && $matches2[1] != "" && $tmpUpdateString[$i] != "" && $matches3[1] != "") {
				$newUpdateString .= ", ".$matches1[1].", ".$matches2[1].", ".$matches3[1];
            $i++;
			}
		}  
		return $newUpdateString;
	}

   /**
    * returns the distance between two points in meters
    */
   static public function getDistance( $firstPointX, $firstPointY, $secondPointX, $secondPointY) {
      return 111189.57696 * rad2deg(acos(sin(deg2rad($firstPointX )) * sin(deg2rad( $secondPointX )) + cos(deg2rad( $firstPointX)) * cos(deg2rad($secondPointX)) * cos(deg2rad( $firstPointY - $secondPointY))));
   }
}
?>
