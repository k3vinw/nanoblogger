# Module for database functions
# Last modified: 2007-01-19T17:27:21-05:00

# rebuild main database from scratch
rebuild_maindb(){
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
			CATDB_RESULTS=($(< "$NB_DATA_DIR/$cat_db"))
			for catdb_item in ${CATDB_RESULTS[@]}; do
				db_match=nomatch
				[ "$catdb_item" = "$entry" ] &&
					db_match=match
				if [ "$db_match" = match ]; then
					cat_idnum="${cat_db/cat\_/}"; cat_idnum="${cat_idnum/\.$NB_DBTYPE/}"
					[ "$cat_idnum" != "$oldcat_idnum" ] && cat_idnum="$oldcat_idnum$cat_idnum"
					oldcat_idnum="$cat_idnum,"
				fi
			done
		done
		cat_idnum="${cat_idnum//\, }"
		[ ! -z "$cat_idnum" ] && cat_ids=">$cat_idnum"
		[ -f "$NB_DATA_DIR/$entry" ] &&
			echo "$entry$cat_ids"
		oldcat_idnum=; cat_idnum=; cat_ids=
	done |sort $db_order > "$SCRATCH_FILE.master.$NB_DBTYPE"
	cp "$SCRATCH_FILE.master.$NB_DBTYPE" "$NB_DATA_DIR/master.$NB_DBTYPE"
}

# search, filter, and create makeshift and main db arrays
query_db(){
db_query="$1"
db_catquery="$2"
db_setlimit="$3"
db_limit="$4"
db_offset="$5"
db_order="$6"
# sanitize db_limit and db_offset
db_limit=`echo "$db_limit" |sed -e '/[A-Z,a-z]/d'`
db_offset=`echo "$db_offset" |sed -e '/[A-Z,a-z]/d'`
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
# list all entries
list_db(){
# gracefully rebuild main database
if [ ! -f "$NB_DATA_DIR/master.$NB_DBTYPE" ]; then
	db_query=; rebuild_maindb
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
	master) db_query=; MASTER_DB_RESULTS=($(< "$NB_DATA_DIR/master.$NB_DBTYPE"));;
	years) db_query=; YEAR_DB_RESULTS=(`list_db |cut -c1-4 |filter_query`);;
	months) db_query=; MONTH_DB_RESULTS=(`list_db |cut -c1-7 |filter_query`);;
	days) db_query=; DAY_DB_RESULTS=(`list_db |cut -c1-10 |filter_query`);;
	max) db_setlimit=limit; db_query=; query_data;;
	rebuild) db_query=; rebuild_maindb;;
	*) query_data;;
esac
db_query=; db_filter=; db_order=;
}

# search, filter, and create raw db references
raw_db(){
db_filter=raw
query_db "$1" "$2" "$3" "$4" "$5" "$6"
}

# split and display entry and categories from database results
print_entry(){ echo "${1%%>[0-9]*}"; }
print_cat(){ echo "${1##*\>}"; }

# resort database
resort_db(){
db_file="$1"
db_order="$2"
: ${db_order:=$SORT_ARGS}
if [ -f "$db_file" ]; then
	sort $db_order "$db_file" > "$db_file".tmp
	mv "$db_file".tmp "$db_file"
fi
}

# resort category database 
resort_catdb(){
catdb_file="$1"
db_order="$2"
: ${db_order:=$SORT_ARGS}
if [ -f "$catdb_file" ]; then
	catdb_title=`sed 1q "$catdb_file"`
	echo "$catdb_title" > "$catdb_file".tmp
	sed 1d "$catdb_file" |sort "$db_order" >> "$catdb_file".tmp

	mv "$catdb_file".tmp "$catdb_file"
fi
}

# index related categories by id
index_catids(){
indexcat_item="$1"
indexcat_list=($2)
[ -z "${indexcat_list[*]}" ] &&
	indexcat_list=(`for ic_db in "$NB_DATA_DIR"/cat_*.$NB_DBTYPE; do echo ${ic_db//*\/}; done`)
cat_ids=; cat_idnum=
for indexcat_db in ${indexcat_list[@]}; do
	CATDB_RESULTS=($(< "$NB_DATA_DIR/$indexcat_db"))
	for catdb_item in ${CATDB_RESULTS[@]}; do
		db_match=nomatch
		[ "$catdb_item" = "$indexcat_item" ] &&
			db_match=match
		if [ "$db_match" = match ]; then
			cat_idnum="${indexcat_db/cat\_/}"; cat_idnum="${cat_idnum/\.$NB_DBTYPE/}"
			[ "$cat_idnum" != "$oldcat_idnum" ] && cat_idnum="$oldcat_idnum$cat_idnum"
			oldcat_idnum="$cat_idnum,"
		fi
	done
done
cat_ids=; cat_idnum="${cat_idnum//\, }"
[ ! -z "$cat_idnum" ] && cat_ids=">$cat_idnum"
oldcat_idnum=; cat_idnum=
}

# update entry and it's related categories for main database
update_maindb(){
db_item="$1"
db_file="$2"
if [ -f "$db_file" ] && [ ! -z "$db_item" ]; then
	sed -e '/'$db_item'/d' "$db_file" > "$db_file.tmp" &&
		mv "$db_file".tmp "$db_file"
	index_catids "$db_item"
	[ -f "$NB_DATA_DIR/$db_item" ] &&
		echo "$db_item$cat_ids" >> "$db_file"
fi
}

# update entry for a database
update_db(){
db_item="$1"
db_file="$2"
if [ -f "$db_file" ] && [ ! -z "$db_item" ]; then
	grep_db=`grep "$db_item" "$db_file"`
	[ -z "$grep_db" ] &&
		echo "$db_item" >> "$db_file"
fi
}

# delete an entry from a database
delete_db(){
db_item="$1"
db_file="$2"
if [ -f "$db_file" ] && [ ! -z "$db_item" ]; then
	grep_db=`grep "$db_item" "$db_file"`
	[ ! -z "$grep_db" ] &&
		sed -e '/'$db_item'/d' "$db_file" > "$db_file".tmp &&
			mv "$db_file".tmp "$db_file"
fi
}

