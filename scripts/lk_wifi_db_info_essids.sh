#/bin/bash
#########################
## lk_wifi_db_info_essids.sh :
##      This tool queries a database created with lk_k2db.py to
##      obtain general data about all networks in that database
##
## Copyright (C) 2015 LAYAKK - www.layakk.com @layakk
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.
##
## PRERREQUISITES
##      lk_option_parser.sh (http://www.layakk.com/lab)
## USAGE NOTES:
##	You can find command line usage description by invoking the script 
##	with -h/--help option.
##	Please note that sqlite3 truncates the results of a columns when
##	you invoke the script with -b option. We recommend to use -b to get
##	a general view and then to not use that option to get accurate 
##	values.
#########################

. lk_option_parser.sh || exit 1

add_program_option "-d" "--database" "Name of the database to query." "YES" "YES"
add_program_option "-e" "--essid" "If you use this option, then information is restricted to the ESSID specified." "NO" "YES"
add_program_option "-t" "--target-only" "If this option is present, the output is filtered considering only ESSIDs that have been markes as target." "NO" "NO"
add_program_option "-x" "--extended" "If this option is present, the query returns extended information" "NO" "NO"
add_program_option "-a" "--anonymize-results" "If this option is present, the MAC addresses contained in the output are anonymized."
add_program_option "-b" "--beautify" "If this option is present, the query results are returned in a readable form. If not, output is optimized to be imported into a spreadsheet." "NO" "NO"
add_program_option "-h" "--help" "Shows this help." "NO" "NO"
parse_program_options $@

show_program_usage "-h" && exit 0

database_name=`get_option_value "-d"`
essid=`get_option_value "-e"`
cmd_opts="-header"
is_option_present "-b" && cmd_opts=${cmd_opts}" -column"

show_program_usage "-h" && exit 0

if is_option_present "-x"
then
	printf "### EXTENDED ESSID INFO in this database ###\n"
	sql="SELECT 	query.essid as  '      ESSID       ', 
			client_probe as ' Probing Clients ', 
			client_assoc as 'Associated Clients', 
			query.bssid as  '  Access Points  ' 
     	FROM\
		( 	SELECT 	ESSID as essid, 
				CLIENT_SSID_PROBE.CLIENT_MAC as client_probe, 
				NULL as client_assoc, 
				NULL as bssid 
			FROM SSID LEFT JOIN CLIENT_SSID_PROBE 
					ON SSID.ESSID = CLIENT_SSID_PROBE.SSID_ESSID "
	if is_option_present "-t"
	then
		sql=$sql" WHERE SSID.is_target = 1"
	fi
	sql=$sql" 
			UNION 
			SELECT 	ESSID as essid, 
				NULL as client_probe, 
				CLIENT_AP_REL.CLIENT_MAC as client_assoc, 
				AP_SSID_REL.AP_BSSID as bssid 
			FROM SSID 
				LEFT JOIN AP_SSID_REL 
					ON AP_SSID_REL.SSID_ESSID = SSID.ESSID  
				LEFT JOIN ACCESS_POINT 
					ON AP_SSID_REL.AP_BSSID = ACCESS_POINT.BSSID 
				LEFT JOIN CLIENT_AP_REL 
					ON CLIENT_AP_REL.AP_BSSID = ACCESS_POINT.BSSID"
	if is_option_present "-t"
	then
		sql=$sql" WHERE SSID.is_target = 1"
	fi
	sql=$sql" ) AS query"
	if is_option_present "-e" 
	then
		sql=$sql" WHERE query.essid = '$essid'"
	fi

	if is_option_present "-a"
	then
		sqlite3 $cmd_opts $database_name "$sql" | sed '1,$s/\:[0123456789ABCDEFabcdef][0123456789ABCDEFabcdef]\:/:**:/g' | sed '1,$s/\:[0123456789ABCDEFabcdef][0123456789ABCDEFabcdef]\:/:**:/g'
	else
		sqlite3 $cmd_opts $database_name "$sql"
	fi
	printf "\n\n"
fi

printf "### ESSID INFO in this database ###\n"
sql="SELECT 	query.essid as '      ESSID       ', 
		COUNT(DISTINCT client_probe) as '# Probe Clients', 
		COUNT(DISTINCT client_assoc) as '# Assoc. Clients', 
		COUNT(DISTINCT query.bssid) as '# APs' 
     FROM
	( 	SELECT 	ESSID as essid, 
			CLIENT_SSID_PROBE.CLIENT_MAC as client_probe, 
			NULL as client_assoc, 
			NULL as bssid 
		FROM SSID LEFT JOIN CLIENT_SSID_PROBE 
				ON SSID.ESSID = CLIENT_SSID_PROBE.SSID_ESSID "
if is_option_present "-t"
then
	sql=$sql" WHERE SSID.is_target = 1"
fi
sql=$sql" 
		UNION 
		SELECT 	ESSID as essid, 
			NULL as client_probe, 
			CLIENT_AP_REL.CLIENT_MAC as client_assoc, 
			AP_SSID_REL.AP_BSSID as bssid 
		FROM SSID 
			LEFT JOIN AP_SSID_REL 
				ON AP_SSID_REL.SSID_ESSID = SSID.ESSID  
			LEFT JOIN ACCESS_POINT 
				ON AP_SSID_REL.AP_BSSID = ACCESS_POINT.BSSID 
			LEFT JOIN CLIENT_AP_REL 
				ON CLIENT_AP_REL.AP_BSSID = ACCESS_POINT.BSSID"
if is_option_present "-t"
then
	sql=$sql" WHERE SSID.is_target = 1"
fi
sql=$sql" ) AS query"
if is_option_present "-e" 
then
	sql=$sql" WHERE query.essid = '$essid'"
fi
sql=$sql" GROUP BY query.essid;"

sqlite3 $cmd_opts $database_name "$sql"

printf "\n\n"
