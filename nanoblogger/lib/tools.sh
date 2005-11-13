# Module for utility functions

# create a semi ISO 8601 formatted timestamp for archives
# used explicitly, please don't edit unless you know what you're doing.
nb_timestamp(){ $DATE_CMD "+%Y-%m-%dT%H_%M_%S"; }

# convert to a more printable date format
filter_timestamp(){
TIMESTAMP="$1"
echo "$TIMESTAMP" |sed -e '/[\_]/ s//:/g; /[A-Z]/ s// /g'
}

# reverse filter time stamp to original form
refilter_timestamp(){
TIMESTAMP="$1"
echo "$TIMESTAMP" |sed -e '/[\:]/ s//_/g; /[ ]/ s//T/'
}

# validate time stamp
validate_timestamp(){
TIMESTAMP="$1"
echo "$TIMESTAMP" |grep '^[0-9][0-9][0-9][0-9][\-][0-9][0-9][\-][0-9][0-9][A-Z][0-9][0-9][\_][0-9][0-9][\_][0-9][0-9]$'
}

# filter custom date format for a new entry
filter_dateformat(){
FILTER_DATE="$1"
FILTER_ARGS="$2"
: ${FILTER_ARGS:=$DATE_ARGS}
# use date's defaults, when no date format is specified
if [ ! -z "$FILTER_DATE" ]; then
	[ ! -z "$DATE_LOCALE" ] && LC_ALL="$DATE_LOCALE" $DATE_CMD $FILTER_ARGS +"$FILTER_DATE"
	[ -z "$DATE_LOCALE" ] && $DATE_CMD $FILTER_ARGS +"$FILTER_DATE"
else
	[ ! -z "$DATE_LOCALE" ] && LC_ALL="$DATE_LOCALE" $DATE_CMD $FILTER_ARGS
	[ -z "$DATE_LOCALE" ] && $DATE_CMD $FILTER_ARGS
fi
}

filter_datestring(){
FILTER_DATE="$1"
FILTER_ARGS="$2"
FILTER_STRING="$3"
: ${FILTER_ARGS:=$DATE_ARGS}
if [ ! -z "$DATE_FORMAT" ]; then
	[ ! -z "$DATE_LOCALE" ] &&
		LC_ALL="$DATE_LOCALE" $DATE_CMD +"$DATE_FORMAT" $DATE_ARGS -d "$FILTER_STRING"
	[ -z "$DATE_LOCALE" ] &&
		$DATE_CMD +"$DATE_FORMAT" $DATE_ARGS -d "$FILTER_STRING"
else
	[ ! -z "$DATE_LOCALE" ] &&
		LC_ALL="$DATE_LOCALE" $DATE_CMD $DATE_ARGS -d "$FILTER_STRING"
	[ -z "$DATE_LOCALE" ] &&
		$DATE_CMD $DATE_ARGS -d "$FILTER_STRING"
fi
}

# change suffix of file
chg_suffix(){
filename="$1"
suffix="$2"
old_suffix=`echo $filename |cut -d"." -f2`
[ ! -z "$suffix" ] && NB_FILETYPE="$suffix"
echo "$filename" |sed -e '{$ s/\.'$old_suffix'$/\.'$NB_FILETYPE'/g; }'
}

# wrapper to editor command
nb_edit(){
# TODO: test with external editor (outside of script's process)
EDIT_FILE="$1"
$EDITOR "$EDIT_FILE"
if [ ! -f "$EDIT_FILE" ]; then
	echo "File, '$EDIT_FILE' does not exist!"
	echo "press [enter] to continue."
	read -p "$NB_PROMPT" enter_key
fi
[ ! -f "$EDIT_FILE" ] && die "failed to write '$EDIT_FILE'! goodbye."
}

# convert category number to existing category database
cat_id(){
cat_query=`echo "$cat_num" |grep '[0-9]' |sed -e '/,/ s// /g; /[A-Z,a-z\)\.-]/d'`
query_db
if [ ! -z "$cat_query" ]; then
	for cat_id in $cat_query; do
		cat_valid=`echo "$db_categories" |grep cat_$cat_id.$NB_DBTYPE`
		echo "$cat_valid"
		[ -z "$cat_valid" ] &&
			echo "bad id(s)!"
	done
fi
}

# validate category's id number
check_catid(){
cat_list=`cat_id`
for cat_db in $cat_list; do
	[ ! -f "$NB_DATA_DIR/$cat_db" ] &&
		die "invalid category id(s): $cat_num"
done
[ ! -z "$cat_num" ] && [ -z "$cat_list" ] && die "must specify a valid category id!"
}

# special conversion for titles to link form
set_title2link(){ title2link_var="$1"
echo "$title2link_var" |sed -e "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/; s/[\`]//g; s/[\~]//g; s/[\!]//g; s/[\@]//g; s/[\#]//g; s/[\$]//g; s/[\%]//g; s/[\^]//g; s/ [\&] / and /g; s/[\&]//g; s/[\*]//g; s/[\(]//g; s/[\)]//g; s/[\+]//g; s/[\=]//g; s/\[//g; s/\]//g; s/[\{]//g; s/[\}]//g; s/[\|]//g; s/[\\]//g; s/[\;]//g; s/[\:]//g; s/[\']//g; s/[\"]//g; s/[\,]//g; s/[\<]//g; s/[\.]//g; s/[\>]//g; s/[\/]//g; s/[\?]//g; s/^[ ]//g; s/[ ]$//g; s/ /_/g"
}

# set base url based on parameters
set_baseurl(){
node_var="$1"
base_dir=`dirname "$2"`
# check if we want absolute links
if [ "$ABSOLUTE_LINKS" = 1 ]; then
	BASE_URL="$BLOG_URL/"
else
	BASE_URL="$node_var"
	if [ "$base_dir" != . ]; then
		blogdir_sedvar=`echo "$BLOG_DIR" |sed -e 's/\//\\\\\//g; /$/ s//\\\\\//'`
		base_dir="$base_dir/./"
		BASE_URL=`echo "$base_dir" |sed -e 's/'$blogdir_sedvar'//g; /^[\.]\// s///; s/[^ \/]*./..\//g; s/^[\.][\.]\///g'`
	fi
	[ -z "$BASE_URL" ] && BASE_URL="./"
fi
# set link path to archives
ARCHIVES_PATH="${BASE_URL}$ARCHIVES_DIR/"
}

# set link/file for given category
set_catlink(){
catlink_var="$1"
# default
category_dir=`echo $catlink_var |cut -d"." -f 1`
category_file="$category_dir/$NB_INDEXFILE"
category_link="$category_dir/$NB_INDEX"

# experimental title-based links
#category_title=`sed 1q "$NB_DATA_DIR/$catlink_var"`
#category_dir=`set_title2link "$category_title"`
#category_file="$category_dir/$NB_INDEXFILE"
#category_link="$category_dir/$NB_INDEX"

# old way
#category_file=`chg_suffix "$catlink_var"`
#category_link="$category_file"
}

# set link/file for given month
set_monthlink(){
monthlink_var="$1"
# default
month_dir=`echo $monthlink_var |sed -e '/[-]/ s//\//g'`
month_file="$month_dir/$NB_INDEXFILE"
NB_ArchiveMonthLink="$month_dir/$NB_INDEX"

# old way
#month_file="$monthlink_var.$NB_FILETYPE"
#month_link="$month_file"
#NB_ArchiveMonthLink="$month_file"
}

# generate entry's anchor/id
set_entryid(){ entryid_var="$1"
echo "$x_id$entryid_var" |sed -e '/[\/]/ s//-/g'
}

# set link/file for given entry
set_entrylink(){
entrylink_var="$1"
link_type="$2"
if [ "$ENTRY_ARCHIVES" = 1 ] && [ "$link_type" != altlink ]; then
	# default
	entrylink_var=`echo $entrylink_var |sed -e '/[-]/ s//\//g'`
	entry_dir=`echo "$entrylink_var" |cut -d "." -f 1 |sed -e '/\T/ s//\/T/g'`
	permalink_file="$entry_dir/$NB_INDEXFILE"
	NB_EntryPermalink="$entry_dir/$NB_INDEX"

	# experimental title-based links
	#entrylink_var=`echo $entrylink_var |sed -e '/[-]/ s//\//g'`
	#entry_dir=`echo "$entrylink_var" |cut -d"." -f 1 |cut -c1-10`
	#entry_linkname=`set_title2link "$NB_EntryTitle"`
	#permalink_file="$entry_dir/$entry_linkname/$NB_INDEXFILE"
	#NB_EntryPermalink="$entry_dir/$entry_linkname/$NB_INDEX"

	# old way
	#permalink_file=`chg_suffix $entrylink_var`
	#NB_EntryPermalink="$permalink_file"

	month=`echo "$entrylink_var" |cut -c1-7`
	set_monthlink "$month"
else
	month=`echo "$entrylink_var" |cut -c1-7`
	set_monthlink "$month"
	entry_id=`set_entryid $entrylink_var`
	NB_EntryPermalink="$NB_ArchiveMonthLink#$entry_id"
fi
}

# tool to build list of related categories from list of entries
find_categories(){
UPDATE_CATLIST="$1"
category_list=()
build_catlist(){
if [ ! -z "$cat_var" ]; then
	category_list=( ${category_list[@]} "$cat_db" )
fi
}
if [ "$USR_QUERY" != all ]; then
	query_db "$USR_QUERY"
	for relative_entry in $UPDATE_CATLIST; do
		for cat_db in $db_categories; do
			cat_var=`grep "$relative_entry" "$NB_DATA_DIR/$cat_db"`
			build_catlist
		done
	done
else
	query_db; CAT_LIST="$db_categories"
fi
if [ ! -z "$category_list" ]; then
	CAT_LIST="${category_list[@]}"
elif [ -z "$CAT_LIST" ]; then
	CAT_LIST=`cat_id`
fi
CAT_LIST=`for cat_id in $CAT_LIST; do echo "$cat_id"; done |sort -u`
}

# tool to help change an entry's date/timestamp
# (e.g. TIMESTAMP: YYYY-MM-DD HH:MM:SS)
chg_entrydate(){
EntryDate_File="$1"
EntryDate_TimeStamp="$2"
# read timestamp from command line
[ "$USR_METATAG" = TIMESTAMP ] &&
	EntryDate_TimeStamp="$USR_TAGTEXT"
# validate timestamp format
Edit_EntryTimeStamp=`refilter_timestamp "$EntryDate_TimeStamp"`
New_EntryTimeStamp=`validate_timestamp "$Edit_EntryTimeStamp"`
# abort if we don't have a valid timestamp
[ ! -z "$EntryDate_TimeStamp" ] && [ -z "$New_EntryTimeStamp" ] &&
	die "TIMESTAMP != 'YYYY-MM-DD HH:MM:SS'"
if [ ! -z "$New_EntryTimeStamp" ]; then
	New_EntryDateFile="$New_EntryTimeStamp.$NB_DATATYPE"
	if [ -f "$NB_DATA_DIR/$EntryDate_File" ] && [ "$EntryDate_File" != "$New_EntryDateFile" ]; then
		Old_EntryFile="$EntryDate_File"
		# update relative categories
		if [ ! -z "$cat_list" ]; then
			for cat_db in $cat_list; do
				cat_mod=`grep "$Old_EntryFile" "$NB_DATA_DIR/$cat_db"`
				if [ ! -z "$cat_mod" ] && [ ! -z "$Old_EntryFile" ]; then
					sed -e '/'$Old_EntryFile'/ s//'$New_EntryDateFile'/' "$NB_DATA_DIR/$cat_db" \
					> "$NB_DATA_DIR/$cat_db".tmp
					mv "$NB_DATA_DIR/$cat_db".tmp "$NB_DATA_DIR/$cat_db"
				fi
			done
		else
			for cat_db in $db_categories; do
				cat_mod=`grep "$Old_EntryFile" "$NB_DATA_DIR/$cat_db"`
				if [ ! -z "$cat_mod" ] && [ ! -z "$Old_EntryFile" ]; then
					sed -e '/'$Old_EntryFile'/ s//'$New_EntryDateFile'/' "$NB_DATA_DIR/$cat_db" \
					> "$NB_DATA_DIR/$cat_db".tmp
					mv "$NB_DATA_DIR/$cat_db".tmp "$NB_DATA_DIR/$cat_db"
				fi
			done
		fi
		mv "$NB_DATA_DIR/$Old_EntryFile" "$NB_DATA_DIR/$New_EntryDateFile"
		set_entrylink "$Old_EntryFile"
		Delete_PermalinkFile="$BLOG_DIR/$ARCHIVES_DIR/$permalink_file"
		Delete_PermalinkDir="$BLOG_DIR/$ARCHIVES_DIR/$entry_dir"
		# delete old permalink file
		[ -f "$Delete_PermalinkFile" ] && rm -fr "$Delete_PermalinkFile"
		# delete old permalink directory
		[ ! -z "$entry_dir" ] && [ -d "$Delete_PermalinkDir" ] &&
			rm -fr "$Delete_PermalinkDir"
		# delete old entry's cache file
		rm -f "$BLOG_DIR/$CACHE_DIR/$Old_EntryFile".*
	fi
	NEWDATE_STRING=`echo "$New_EntryTimeStamp" |sed -e 's/[A-Z,a-z]/ /g; s/[\_]/:/g'`
	NB_NewEntryDate=$(filter_datestring "$DATE_FORMAT" "" "$NEWDATE_STRING")
	if [ ! -z "$NB_NewEntryDate" ]; then
		write_metadata DATE "$NB_NewEntryDate" "$NB_DATA_DIR/$New_EntryDateFile"
	else
		# fallback to timestamp
		nb_msg "$filterdate_failed"
		NB_NewEntryDate="$EntryDate_TimeStamp"
		write_metadata DATE "$NB_NewEntryDate" "$NB_DATA_DIR/$New_EntryDateFile"
	fi
fi
}

