# Module for querying existing records

# create list of entries based on a month or interval
query_db(){
db_query="$1"
db_catquery="$2"
db_setlimit="$3"
db_limit="$4"
db_offset="$5"
# sanitize db_limit and db_offset
db_limit=`echo "$db_limit" |sed -e '/[A-Z,a-z,\-]/d'`
db_offset=`echo "$db_offset" |sed -e '/[A-Z,a-z,\-]/d'`
: ${db_limit:=$MAX_ENTRIES}
: ${db_limit:=0}; : ${db_offset:=1}
current_date=`date "+%Y.%m"`
cd "$NB_DATA_DIR"
# get list of categories or accept a user specified list
if [ -z "$db_catquery" ] || [ "$db_catquery" = nocat ]; then
	db_catquery=
	db_categories=`for cat_db in cat_*.$NB_DBTYPE; do echo "$cat_db"; done`
else
	db_categories="$db_catquery"
fi
if [ "$db_categories" = "cat_*.$NB_DBTYPE" ]; then db_categories=; fi
# list amount of entries based on db_limit
filter_limit(){
	[ "$db_limit" = 0 ] && grep "." # regex hack for non-GNU versions
	[ ! -z "$db_limit" ] && sed -n "$db_offset,$db_limit"p
	db_setlimit=; db_limit=; db_offset=
	}
filter_query(){ grep "$db_query." |sort $SORT_ARGS; } # allow for empty $db_query
# list all entries
list_db(){
	DB_YYYY=`echo "$db_query" |cut -c1-4`
	DB_MM=`echo "$db_query" |cut -c6-7`
	DB_DD=`echo "$db_query" |cut -c9-10`
	: ${DB_YYYY:=[0-9][0-9][0-9][0-9]}
	: ${DB_MM:=[0-9][0-9]}
	: ${DB_DD:=[0-9][0-9]}
	DB_DATE="${DB_YYYY}*${DB_MM}"
	for entry in ${DB_DATE}*${DB_DD}*.$NB_DATATYPE; do
		[ -f "$entry" ] && echo "$entry"
	done
	}
# include categorized entries
cat_db(){
	[ -z "$db_catquery" ] && list_db
	for cat_db in $db_categories; do
		[ ! -z "$cat_db" ] &&
			grep "[\.]$NB_DATATYPE" "$cat_db"
	done
	}
query_data(){
	if [ "$db_setlimit" = limit ]; then
		DB_RESULTS=`cat_db |filter_query |filter_limit`
	else
		DB_RESULTS=`cat_db |filter_query`
	fi
}
if [ "$db_query" = all ]; then
	db_query=; query_data
elif [ "$db_query" = master ]; then
	# create master variable for complete query results
	db_query=; MASTER_DB_RESULTS=`cat_db |filter_query`
elif [ "$db_query" = current ]; then
	db_query="$current_date"; query_data
elif [ "$db_query" = max ]; then
	db_setlimit=limit; db_query=; query_data
else
	query_data
fi
db_query=; cd "$CURR_PATH"
}

