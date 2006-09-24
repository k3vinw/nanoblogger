# Module for querying existing records
# Last modified: 2006-09-23T22:27:08-04:00

# search, filter, and create makeshift and master db arrays
query_db(){
db_query="$1"
db_catquery="$2"
db_setlimit="$3"
db_limit="$4"
db_offset="$5"
db_order="$6"
# sanitize db_limit and db_offset
db_limit=`echo "$db_limit" |sed -e '/[A-Z,a-z,\-]/d'`
db_offset=`echo "$db_offset" |sed -e '/[A-Z,a-z,\-]/d'`
: ${db_limit:=$MAX_ENTRIES}
: ${db_limit:=0}; : ${db_offset:=1}
: ${db_order:=$SORT_ARGS}
: ${db_filter:=query}
# adjust offset by 1 for bash arrays (1 = 0)
[ "$db_offset" -ge 1 ] && ((db_offset--))
# allow /'s in queries
db_query="${db_query//\//-}"
# get list of categories or accept a user specified list
if [ -z "$db_catquery" ] || [ "$db_catquery" = nocat ]; then
	db_catquery=
	db_categories=(`for cat_db in "$NB_DATA_DIR"/cat_*.$NB_DBTYPE; do echo "${cat_db//*\/}"; done`)
else
	db_categories=($db_catquery)
fi
[ "${db_categories[*]}" = "cat_*.$NB_DBTYPE" ] && db_categories=()
# filter_ filters
filter_query(){ grep "$db_query." |cut -d">" -f 1 |sort $db_order; } # allow for empty $db_query
filter_raw(){ grep "$db_query." |sort $db_order; }
# update master db
update_db(){
	DB_YYYY=`echo "$db_query" |cut -c1-4`
	DB_MM=`echo "$db_query" |cut -c6-7`
	DB_DD=`echo "$db_query" |cut -c9-10`
	: ${DB_YYYY:=[0-9][0-9][0-9][0-9]}
	: ${DB_MM:=[0-9][0-9]}
	: ${DB_DD:=[0-9][0-9]}
	DB_DATE="${DB_YYYY}*${DB_MM}"
	for db_item in "$NB_DATA_DIR"/${DB_DATE}*${DB_DD}*.$NB_DATATYPE; do
		entry=${db_item//*\/}
		# index related categories by id
		for cat_db in ${db_categories[@]}; do
			cat_var=`grep "$entry" "$NB_DATA_DIR/$cat_db"`
			if [ ! -z "$cat_var" ]; then
				cat_idnum=`echo "$cat_db" |sed -e '/cat[\_]/ s///g; /[\.]'$NB_DBTYPE'/ s///g'`
				[ "$cat_idnum" != "$oldcat_idnum" ] && cat_idnum="$oldcat_idnum$cat_idnum"
				oldcat_idnum="$cat_idnum,"
			fi
		done
		cat_idnum=`echo $cat_idnum |sed -e '/\,[ ]$/ s///g'`
		[ ! -z "$cat_idnum" ] && cat_ids=">$cat_idnum"
		[ -f "$NB_DATA_DIR/$entry" ] &&
			echo "$entry$cat_ids"
		oldcat_idnum=; cat_idnum=; cat_ids=
	done |sort $db_order > "$SCRATCH_FILE.master.$NB_DBTYPE"
	cp "$SCRATCH_FILE.master.$NB_DBTYPE" "$NB_DATA_DIR/master.$NB_DBTYPE"
}
# list all entries
list_db(){
# force update or gracefully recover master db reference file
if [ ! -f "$NB_DATA_DIR/master.$NB_DBTYPE" ] || [ "$db_query" = update ]; then
	db_query=; update_db
fi
# list entries from master.db
if [ -z "$db_catquery" ]; then
	grep "[\.]$NB_DATATYPE" "$NB_DATA_DIR/master.$NB_DBTYPE"
else
	# or list entries from cat_n.db
	for cat_db in ${db_categories[*]}; do
		[ -f "$NB_DATA_DIR/$cat_db" ] &&
			grep "[\.]$NB_DATATYPE" "$NB_DATA_DIR/$cat_db"
	done
fi
}
query_data(){
if [ "$db_setlimit" = limit ]; then
	DB_RESULTS=(`list_db |filter_$db_filter`)
	[ "$db_limit" = 0 ] || [ "$db_limit" = -1 ] &&
		db_limit=${#DB_RESULTS[*]}
	DB_RESULTS=(`for db_item in ${DB_RESULTS[@]:$db_offset:$db_limit}; do
			echo $db_item
		done`)
else
	DB_RESULTS=(`list_db |filter_$db_filter`)
fi
}
case "$db_query" in
	all) db_query=; query_data;;
	# create master reference db
	master) db_query=; update_db
		MASTER_DB_RESULTS=($(< "$NB_DATA_DIR/master.$NB_DBTYPE"));;
	years) db_query=; YEAR_DB_RESULTS=(`list_db |cut -c1-4 |filter_query`);;
	months) db_query=; MONTH_DB_RESULTS=(`list_db |cut -c1-7 |filter_query`);;
	days) db_query=; DAY_DB_RESULTS=(`list_db |cut -c1-10 |filter_query`);;
	max) db_setlimit=limit; db_query=; query_data;;
	*) query_data;;
esac
db_query=; db_filter=; db_order=;
}

# search, filter, and create raw db references
raw_db(){
db_filter=raw
query_db "$1" "$2" "$3" "$4" "$5" "$6"
}

