#/bin/bash
#########################
## lk_wifi_db_get_interesting_hotspots.sh :
##      This tool queries a database created with lk_k2db.py to
##      obtain the known hotspots where target clients connect
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

add_program_option "-d" "--database" "Name of the database to query." "YES" "YES"
add_program_option "-e" "--essid" "ESSID of interest." "NO" "YES"
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
#sqlite3 -header $database_name '\
else
	sql1="\
	SELECT CLIENT.MAC as client_mac
	from CLIENT\
		JOIN CLIENT_SSID_PROBE ON\
			CLIENT.MAC = CLIENT_SSID_PROBE.CLIENT_MAC\
		JOIN SSID ON\
			SSID.ESSID = CLIENT_SSID_PROBE.SSID_ESSID\
	WHERE SSID.is_target = 1"
	if is_option_present "-e"
	then
		sql1="$sql1 AND SSID.ESSID = \"${essid}\""
	fi

	sql2="
	SELECT CLIENT.MAC as client_mac
	FROM CLIENT
		JOIN CLIENT_AP_REL ON CLIENT.MAC = CLIENT_AP_REL.CLIENT_MAC
		JOIN ACCESS_POINT ON ACCESS_POINT.BSSID = CLIENT_AP_REL.AP_BSSID
		JOIN AP_SSID_REL ON AP_SSID_REL.AP_BSSID = ACCESS_POINT.BSSID
		JOIN SSID ON AP_SSID_REL.SSID_ESSID = SSID.ESSID
	WHERE	SSID.is_target = 1 and CLIENT_AP_REL.type <> 'fromds'
	"
	if is_option_present "-e"
	then
		sql2="$sql2 AND SSID.ESSID = \"${essid}\""
	fi

	sql_targetclients="( $sql1 UNION $sql2 )"
	sql="
	select C1PROBE.SSID_ESSID as '      ESSID       ', count(C1PROBE.SSID_ESSID) as '# Clients'
	from CLIENT as C1 
		JOIN CLIENT_SSID_PROBE as C1PROBE ON C1PROBE.CLIENT_MAC = C1.MAC 
		JOIN AP_SSID_REL as C1AP ON C1AP.SSID_ESSID = C1PROBE.SSID_ESSID 
	where 	C1PROBE.SSID_ESSID != 'any' and C1PROBE.SSID_ESSID != 'unknown' 
		and C1AP.encryption not like 'W%' 
		and C1.MAC in $sql_targetclients 
	group by C1PROBE.SSID_ESSID, C1AP.encryption 
	order by 2" 

	cmd_opts="-header"
        is_option_present "-b" && cmd_opts=${cmd_opts}" -column"
        if is_option_present "-a"
        then
		sqlite3 $cmd_opts $database_name "$sql" | awk '{gsub(":[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:",":**:**:**:**:"); print $0}'
		sqlite3 $cmd_opts $database_name "$sql" | sed '1,$s/\:[0123456789ABCDEFabcdef][0123456789ABCDEFabcdef]\:/:**:/g' | sed '1,$s/\:[0123456789ABCDEFabcdef][0123456789ABCDEFabcdef]\:/:**:/g'
	else
		sqlite3 $cmd_opts $database_name "$sql"
	fi
fi
