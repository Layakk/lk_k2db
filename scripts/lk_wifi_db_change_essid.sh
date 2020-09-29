#/bin/bash
. lk_option_parser.sh || exit 1

add_program_option "-d" "--database" "Name of the database to query." "YES" "YES"
add_program_option "-o" "--old-essid" "ESSID to be changed." "YES" "YES"
add_program_option "-n" "--new-essid" "New ESSID." "YES" "YES"
add_program_option "-h" "--help" "Shows this help." "NO" "NO"
parse_program_options $@

show_usage "-h" && exit 0

database_name=`get_option_value "-d"`
old_essid=`get_option_value "-o"`
new_essid=`get_option_value "-n"`
client_mac=`get_option_value "-c"`

if [[ ! -f $database_name ]]
then
	printf "Database file '$database_name' does not exist! Exiting.\n\n"
	show_program_usage
	exit 1
fi

# Change the SSID table
sql="UPDATE OR REPLACE SSID SET
	ESSID = '${new_essid}',
	first_seen = (select min(first_seen) from ssid where essid='${new_essid}' or essid='${old_essid}'),
	last_seen = (select max(last_seen) from ssid where essid='${new_essid}' or essid='${old_essid}')
	WHERE essid='${old_essid}'"
sqlite3 -header $database_name "$sql"

# Change the AP_SSID_REL table
sql="UPDATE OR REPLACE AP_SSID_REL SET
	SSID_ESSID='${new_essid}',
	first_seen = (select min(first_seen) from AP_SSID_REL as R where R.AP_BSSID=AP_BSSID and (R.SSID_ESSID='${new_essid}' or R.SSID_ESSID='${old_essid}')),
	last_seen = (select max(last_seen) from AP_SSID_REL as R where R.AP_BSSID=AP_BSSID and (R.SSID_ESSID='${old_essid}' or R.SSID_ESSID='${new_essid}')),
	type = (select type from AP_SSID_REL as R where R.AP_BSSID=AP_BSSID and (R.SSID_ESSID='${new_essid}' or R.SSID_ESSID='${old_essid}') and R.last_seen=(select max(last_seen) from AP_SSID_REL as RR where RR.AP_BSSID=AP_BSSID and (RR.SSID_ESSID='${new_essid}' or RR.SSID_ESSID='${old_essid}'))),
	encryption = (select encryption from AP_SSID_REL as R where R.AP_BSSID=AP_BSSID and (R.SSID_ESSID='${new_essid}' or R.SSID_ESSID='${old_essid}') and R.last_seen=(select max(last_seen) from AP_SSID_REL as RR where RR.AP_BSSID=AP_BSSID and (RR.SSID_ESSID='${new_essid}' or RR.SSID_ESSID='${old_essid}')))
	WHERE SSID_ESSID='${old_essid}'"
sqlite3 -header $database_name "$sql"
	
# Change the CLIENT_SSID_PROBE table
sql="UPDATE OR REPLACE CLIENT_SSID_PROBE SET
	SSID_ESSID='${new_essid}',
	first_seen = (select min(first_seen) from CLIENT_SSID_PROBE as P where P.CLIENT_MAC=CLIENT_MAC and (P.SSID_ESSID='${new_essid}' or P.SSID_ESSID='${old_essid}')),
	last_seen = (select max(last_seen) from CLIENT_SSID_PROBE as P where P.CLIENT_MAC=CLIENT_MAC and (P.SSID_ESSID='${new_essid}' or P.SSID_ESSID='${old_essid}')),
	type = (select type from CLIENT_SSID_PROBE as P where P.CLIENT_MAC=CLIENT_MAC and (P.SSID_ESSID='${new_essid}' or P.SSID_ESSID='${old_essid}') and P.last_seen=(select max(last_seen) from CLIENT_SSID_PROBE as P where P.CLIENT_MAC=CLIENT_MAC and (P.SSID_ESSID='${new_essid}' or P.SSID_ESSID='${old_essid}')))
	WHERE SSID_ESSID='${old_essid}'"
sqlite3 -header $database_name "$sql"
