#/bin/bash
#########################
## lk_wifi_db_get_essid_aps.sh :
##      This tool queries a database created with lk_k2db.py to
##      obtain the network clients (of any type) for a network
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
##      You can find command line usage description by invoking the script
##      with -h/--help option.
##      Please note that sqlite3 truncates the results of a columns when
##      you invoke the script with -b option. We recommend to use -b to get
##      a general view and then to not use that option to get accurate
##      values.
#########################

. lk_option_parser.sh || exit 1

add_program_option "-e" "--essid" "ESSID of the WiFi network we are querying for." "NO" "YES"
add_program_option "-t" "--target-only" "If this option is present, the output is filtered considering only ESSIDs that have been markes as target." "NO" "NO"
add_program_option "-d" "--database" "Name of the database to query." "YES" "YES"
add_program_option "-x" "--extended" "If this option is present, the query returns extended information" "NO" "NO"
add_program_option "-b" "--beautify" "If this option is present, the query results are returned in a readable form. If not, output is optimized to be imported in a spreadsheet." "NO" "NO"
add_program_option "-a" "--anonymize-results" "If this option is present, the MAC addresses contained in the output are anonymized."
add_program_option "-h" "--help" "Shows this help." "NO" "NO"
parse_program_options $@

show_program_usage "-h" && exit 0

database_name=`get_option_value "-d"`
essid=`get_option_value "-e"`


if [[ ! -f $database_name ]]
then
	printf "Database file '$database_name' does not exist! Exiting.\n\n"
	show_program_usage
	exit 1
fi

if is_option_present "-x"
then
	printf "Not yet implemented... \n\n"
else
	sql="
	SELECT SSID.ESSID as '    ESSID     ', ACCESS_POINT.BSSID AS '    AP BSSID     ', ACCESS_POINT.manufacturer as 'Manufact.', AP_SSID_REL.encryption AS '     Encryption      ', ACCESS_POINT.channel as Channel
	FROM ACCESS_POINT 
		JOIN AP_SSID_REL ON AP_SSID_REL.AP_BSSID = ACCESS_POINT.BSSID
		JOIN SSID ON AP_SSID_REL.SSID_ESSID = SSID.ESSID"
	if is_option_present "-e"
	then
		sql="$sql WHERE AP_SSID_REL.SSID_ESSID = '$essid'"
		if is_option_present "-t"
		then
			sql="$sql AND SSID.is_target = 1"
		fi
	else
		if is_option_present "-t"
		then
			sql="$sql WHERE SSID.is_target = 1"
		fi
	fi
	sql="$sql ORDER BY SSID.ESSID"

	cmd_opts="-header"
        is_option_present "-b" && cmd_opts=${cmd_opts}" -column"
        if is_option_present "-a"
        then
		sqlite3 $cmd_opts $database_name "$sql" | sed '1,$s/\:[0123456789ABCDEFabcdef][0123456789ABCDEFabcdef]\:/:**:/g' | sed '1,$s/\:[0123456789ABCDEFabcdef][0123456789ABCDEFabcdef]\:/:**:/g'
	else
		sqlite3 $cmd_opts $database_name "$sql"
	fi
		
fi
