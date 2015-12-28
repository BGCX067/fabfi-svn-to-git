#!/usr/bin/php -q
<?php
/*
 +-------------------------------------------------------------------------+
 | Copyright (C) 2004-2009 The Cacti Group                                 |
 |                                                                         |
 | This program is free software; you can redistribute it and/or           |
 | modify it under the terms of the GNU General Public License             |
 | as published by the Free Software Foundation; either version 2          |
 | of the License, or (at your option) any later version.                  |
 |                                                                         |
 | This program is distributed in the hope that it will be useful,         |
 | but WITHOUT ANY WARRANTY; without even the implied warranty of          |
 | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           |
 | GNU General Public License for more details.                            |
 +-------------------------------------------------------------------------+
 | Cacti: The Complete RRDTool-based Graphing Solution                     |
 +-------------------------------------------------------------------------+
 | This code is designed, written, and maintained by the Cacti Group. See  |
 | about.php and/or the AUTHORS file for specific developer information.   |
 +-------------------------------------------------------------------------+
 | http://www.cacti.net/                                                   |
 +-------------------------------------------------------------------------+
*/

/* do NOT run this script through a web browser */
if (!isset($_SERVER["argv"][0]) || isset($_SERVER['REQUEST_METHOD'])  || isset($_SERVER['REMOTE_ADDR'])) {
	die("<br><strong>This script is only meant to run at the command line.</strong>");
}

/* We are not talking to the browser */
$no_http_headers = true;

$cacti_path="/usr/share/cacti";

#include(dirname(__FILE__)."$cacti_path/site/include/global.php");
include("$cacti_path/site/include/global.php");
include_once($config["base_path"]."/lib/api_automation_tools.php");
include_once($config["base_path"]."/lib/utility.php");
include_once($config["base_path"]."/lib/api_data_source.php");
include_once($config["base_path"]."/lib/api_graph.php");
include_once($config["base_path"]."/lib/snmp.php");
include_once($config["base_path"]."/lib/data_query.php");
include_once($config["base_path"]."/lib/api_device.php");

/* process calling arguments */
$parms = $_SERVER["argv"];
array_shift($parms);

if (sizeof($parms)) {
	/* setup defaults, there are lots of "magic numbers" in this code
	   please read carefully and replace them according to your needs */
	$description   = "";
	$ip            = "";
	$template_id   = 0;
	$community     = "public";
	$snmp_ver      = 3;
	$disable       = 0;

	$notes         = "";

	$snmp_username        = "fabfi-user";
	$snmp_password        = "cisco123";
	$snmp_auth_protocol   = "SHA";
	$snmp_priv_passphrase = "cisco123";
	$snmp_priv_protocol   = "AES";
	$snmp_context         = "";
	$snmp_port            = 161;
	$snmp_timeout         = 5000;

	$avail        = "snmp";
	$ping_method  = 3;
	$ping_port    = 23;
	$ping_timeout = 500;
	$ping_retries = 2;
	$max_oids     = 50;


	foreach($parms as $parameter) {
		@list($arg, $value) = @explode("=", $parameter);

		switch ($arg) {
		case "-d":
			$debug = TRUE;

			break;
		case "--host":
			$host = trim($value);

			break;
		case "--desc":
			$desc = trim($value);

			break;
		case "--template":
			$host_template = trim($value);

			break;
		case "--version":
		case "-V":
		case "-H":
		case "--help":
			display_help();
			exit(0);
		default:
			echo "ERROR: Invalid Argument: ($arg)\n\n";
			display_help();
			exit(1);
		}
	}

	if (empty($host) || empty($desc) || empty($host_template)) {
		print "Parameter error\n";
		exit(1);
	}

	# create the host using some defaults
//	print("creating Host: " . $host . " description: " . $desc . " host template: " . $host_template . "\n");
	$_result=array();
	exec("php -q $cacti_path/cli/add_device.php --ip=$host --description=\"" . $desc . "\" --template=$host_template --username=$snmp_username --version=$snmp_ver --avail=$avail --max_oids=$max_oids --quiet --password=$snmp_password --authproto=$snmp_auth_protocol --privproto=$snmp_priv_protocol --privpass=$snmp_priv_passphrase ", $_result);
	# get the host_id out of the response
	foreach ($_result as $_line) {
		print $_line . "\n";
		if (preg_match('/^Success - new device-id: \((\d+)\)$/', $_line, $matches)) {
			$host_id = $matches[1];
		}
	}

	if (empty($host_id)) {
		print "Error: host not created\n";
		exit(1);
	}
      
	# all simple graphs go here
	$simple_graphs = getHostTemplateGraphs($host_id);
	foreach ($simple_graphs as $graph_template) {
		$_result=array();
		exec("php -q $cacti_path/cli/add_graphs.php --graph-type=cg --host-id=$host_id --graph-template-id=" . $graph_template['id'] . " --quiet", $_result);
		foreach ($_result as $_line) print $_line . "\n";
	}

	# Interface Graphs
	$indices = getHostIf($host_id);
	foreach ($indices as $if) {
		$_result=array();
		# 64 bit traffic graph for all interfaces with given HwAddr
		exec("php -q $cacti_path/cli/add_graphs.php --graph-type=ds --host-id=$host_id --graph-template-id=2 --snmp-query-id=1 --snmp-query-type-id=14 --snmp-field=ifIndex --snmp-value=\"$if\" --quiet", $_result);
		foreach ($_result as $_line) print $_line . "\n";

		$_result=array();
		# Errors/Discards
		exec("php -q $cacti_path/cli/add_graphs.php --graph-type=ds --host-id=$host_id --graph-template-id=2 --snmp-query-id=1 --snmp-query-type-id=2 --snmp-field=ifIndex --snmp-value=\"$if\" --quiet", $_result);
		foreach ($_result as $_line) print $_line . "\n";
	}


	# hook host into tree
	print("hooking into tree\n");
	$_result=array();
	exec("php -q $cacti_path/cli/lvm_device_tree.php --host-id=$host_id", $_result);
	foreach ($_result as $_line) print $_line . "\n";

}else{
	display_help();
	exit(0);
}

function display_help() {
	echo "Add Device Script 1.0, Copyright 2007 - The Cacti Group\n\n";
}

function getHostTemplateGraphs($host_id) {
        $graph_templates = db_fetch_assoc("select graph_templates.id, graph_templates.name from (graph_templates,host_graph) where graph_templates.id=host_graph.graph_template_id and host_graph.host_id=" . $host_id . " order by graph_templates.name");
	# drop unwanted elements
	if (sizeof($graph_templates) > 0) {
		foreach ($graph_templates as $key => $item) {
			/* get status information for this graph template */
			if (sizeof(db_fetch_assoc("select id from graph_local where graph_template_id=" . $item["id"] . " and host_id=" . $host_id)) > 0) {
#				print("Graph " . $item["name"] . " is being graphed already\n");
				unset($graph_templates[$key]);
			}
		}
	}
        return $graph_templates;
}

function getHostIf($host_id) {
	$mac = array_rekey(db_fetch_assoc("select snmp_index from host_snmp_cache where host_id = $host_id and field_name ='ifHwAddr' and LENGTH(field_value) > 0 order by CAST(snmp_index AS UNSIGNED)"),"snmp_index","snmp_index");
	$status = array_rekey(db_fetch_assoc("select snmp_index from host_snmp_cache where host_id = $host_id and field_name ='ifOperStatus' and field_value='Up' order by CAST(snmp_index AS UNSIGNED)"),"snmp_index","snmp_index");
	$ip = array_rekey(db_fetch_assoc("select snmp_index from host_snmp_cache where host_id = $host_id and field_name ='ifIP' and LENGTH(field_value) > 0 order by CAST(snmp_index AS UNSIGNED)"),"snmp_index","snmp_index");

	return array_intersect($mac, $status, $ip);
}
?>
