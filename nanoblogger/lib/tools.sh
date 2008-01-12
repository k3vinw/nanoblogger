# Module for utility functions
# Last modified: 2008-01-11T17:52:17-05:00

# create a semi ISO 8601 formatted timestamp for archives
# used explicitly, please don't edit unless you know what you're doing.
nb_timestamp(){ $DATE_CMD $DB_DATEARGS +"$DB_DATEFORMAT"; }

# convert to a more printable date format
filter_timestamp(){
#echo "$1" |sed -e '/[\_]/ s//:/g; /[A-Z]/ s// /g'
entry_date=${1%%.$NB_DATATYPE}; entry_date=${entry_date//\_/:}
echo ${entry_date//[A-Z]/ }
}

# reverse filter time stamp to original form
refilter_timestamp(){
#echo "$1" |sed -e '/[\:]/ s//_/g; /[ ]/ s//T/'
entry_date=${1//\:/_}
echo ${entry_date//[ ]/T}
}

# validate time stamp
validate_timestamp(){
echo "$1" |grep '^[0-9][0-9][0-9][0-9][\-][0-9][0-9][\-][0-9][0-9][A-Z][0-9][0-9][\_][0-9][0-9][\_][0-9][0-9]$'
}

# filter custom date format for a new entry
# synopsis: filter_dateformat [date] [date args]
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

# filter custom date string using GNU specific 'date -d'
# synopsis: filter_datestring [date] [date args] [date description]
filter_datestring(){
FILTER_DATE="$1"
FILTER_ARGS="$2"
FILTER_DESC="$3"
: ${FILTER_ARGS:=$DATE_ARGS}
if [ ! -z "$DATE_FORMAT" ]; then
	[ ! -z "$DATE_LOCALE" ] &&
		LC_ALL="$DATE_LOCALE" $DATE_CMD +"$DATE_FORMAT" $DATE_ARGS -d "$FILTER_DESC"
	[ -z "$DATE_LOCALE" ] &&
		$DATE_CMD +"$DATE_FORMAT" $DATE_ARGS -d "$FILTER_DESC"
else
	[ ! -z "$DATE_LOCALE" ] &&
		LC_ALL="$DATE_LOCALE" $DATE_CMD $DATE_ARGS -d "$FILTER_DESC"
	[ -z "$DATE_LOCALE" ] &&
		$DATE_CMD $DATE_ARGS -d "$FILTER_DESC"
fi
}

# change suffix of file
chg_suffix(){
filename="$1"
suffix="$2"
old_suffix="${filename##*.}"
[ ! -z "$suffix" ] && NB_FILETYPE="$suffix"
echo "${filename//[\.]$old_suffix/.$NB_FILETYPE}"
}

# tool to require confirmation
confirm_action(){
echo "$confirmaction_ask [y/N]"
read -p "$NB_PROMPT" confirm
case $confirm in
	[Yy]);;
	[Nn]|"") die;;
esac
}

# sensible-browser-like utility (parses $NB_BROWSER, $BROWSER, and %s)
# synopsis: nb_browser [url]
# NOTE: $BROWSE_URL must be full path or some browsers complain
nb_browser(){
BROWSER_CMD="$NB_BROWSER"
BROWSER_URL="$1"
if [ ! -z "$BROWSER_CMD" ]; then
	BROWSER_LIST=`echo "$BROWSER_CMD" |sed -e '/[ ]/ s//%REM%/g; /\:/ s// /g'`
	for browser in $BROWSER_LIST; do
		browserurl_sedvar="${BROWSER_URL//\//\\/}"
		browser_cmd=`echo "$browser" |sed -e 's/\%REM\%/ /g; s/\%\%/\%/g; s/\%s/'$browserurl_sedvar'/g'`
		$browser_cmd "$BROWSER_URL" && break
		# on failure, continue to next in list
	done
	[ $? != 0 ] && nb_msg "$nbbrowser_nobrowser"
fi
}

# wrapper to editor command
# synopsis: nb_edit [options] file
nb_edit(){
EDIT_OPTIONS="$1"
EDIT_FILE="$2"
[ -z "$EDIT_FILE" ] && EDIT_FILE="$1"
# set directory being written to
EDIT_DIR="${EDIT_FILE%%\/${EDIT_FILE##*\/}}"
# assume current directory when no directory is found
[ ! -d "$EDIT_DIR" ] && EDIT_DIR="./"
# test directory for write permissions
[ ! -w "$EDIT_DIR" ] && [ -d "$EDIT_DIR" ] &&
	die "'$EDIT_DIR' - $nowritedir"
case "$EDIT_OPTIONS" in
	-p) # prompt to continue (kludge for editors that detach from process)
		$NB_EDITOR "$EDIT_FILE"
		read -p "$nbedit_prompt" enter_key
	;;
	*) # default action
		$NB_EDITOR "$EDIT_FILE"
	;;
esac
if [ ! -f "$EDIT_FILE" ]; then
	nb_msg "'$EDIT_FILE' - $nbedit_nofile"
	die "'$EDIT_FILE' - $nbedit_failed"
fi
}

# print a file (line by line)
# synopsis: nb_print file [number of lines|blank for all]
nb_print(){
nbprint_file="$1"
maxnbprint_cnt=$2
nbprint_cnt=0
while read line; do
	let nbprint_cnt=${nbprint_cnt}+1
	[ ! -z $maxnbprint_cnt ] && [ $nbprint_cnt -gt $maxnbprint_cnt ] &&
		break
	echo $line
done < $nbprint_file
}

# convert category number to existing cateogory database
cat_id(){
cat_query=(`echo "$1" |grep '[0-9]' |sed -e '/,/ s// /g; /[A-Z,a-z\)\.-]/d'`)
query_db
if [ ! -z "${cat_query[*]}" ]; then
	for cat_id in ${cat_query[@]}; do
		cat_valid=`for cat_db in ${db_categories[@]}; do echo $cat_db; done |grep cat_$cat_id.$NB_DBTYPE`
		echo "$cat_valid"
		[ -z "$cat_valid" ] &&
			nb_msg "$catid_bad"
	done
fi
}

# validate category's id number
check_catid(){
cat_list=(`cat_id "$1"`)
for cat_db in ${cat_list[@]}; do
	[ ! -f "$NB_DATA_DIR/$cat_db" ] &&
		die "$checkcatid_invalid $1"
done
[ ! -z "$1" ] && [ -z "${cat_list[*]}" ] && die "$checkcatid_novalid"
}

# check file for required metadata vars
check_metavars(){
VALIDATE_VARS="$1"
VALIDATE_METAFILE="$2"
for mvar in $VALIDATE_VARS; do
	MVAR_NUM=`grep -c "^$mvar" "$VALIDATE_METAFILE"`
	[ "$MVAR_NUM" = 0 ] &&
		die "'$VALIDATE_METAFILE' - $checkmetavars_novar '$mvar'"
done
}

# import metafile
import_file(){
IMPORT_FILE="$1"
if [ -f "$IMPORT_FILE" ]; then
	# validate metafile
	check_metavars "TITLE: AUTHOR: DATE: BODY: $METADATA_CLOSEVAR" \
		"$IMPORT_FILE"
	load_metadata ALL "$IMPORT_FILE"
else
	nb_msg "'$IMPORT_FILE' $importfile_nofile"
fi
}

# transliterate text into a suitable form for web links
translit_text(){ translittext_var="$1"; ttchar_limit="$MAX_TITLEWIDTH"
nonascii="${translittext_var//[a-zA-Z0-9_-]/}" # isolate all non-printable/non-ascii characters
echo "$translittext_var" |sed -e "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/; s/[\`\~\!\@\#\$\%\^\*\(\)\+\=\{\}\|\\\;\:\'\"\,\<\>\/\?]//g; s/ [\&] / and /g; s/^[ ]//g; s/[ ]$//g; s/[\.]/_/g; s/\[//g; s/\]//g; s/ /_/g; s/[$nonascii ]/_/g" |cut -c1-$ttchar_limit |sed -e '/[\_\-]*$/ s///g; /[\_\-]$/ s///g'
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
		blogdir_sedvar=`echo "${BLOG_DIR//\//\\\\/}\\\\/"`
		base_dir="$base_dir/./"
		BASE_URL=`echo "$base_dir" |sed -e 's/'$blogdir_sedvar'//g; /^[\.]\// s///; s/[^ \/]*./..\//g; s/^[\.][\.]\///g'`
	fi
	[ -z "$BASE_URL" ] && BASE_URL="./"
fi
# set link path to archives
ARCHIVES_PATH="${BASE_URL}$ARCHIVES_DIR/"
}

# tool to lookup ID from master database
lookup_id(){
INPUT_IDLIST=($2)
for db_item in ${INPUT_IDLIST[@]}; do
	echo $db_item
done |grep -n "$1" |cut -d":" -f 1 |grep '^[0-9].*$'
}

# tool to find entry before and after from entry's id
findba_entries(){
BAENTRY_IDLIST=($2)
entryid_var=`lookup_id "$1" "${BAENTRY_IDLIST[*]}"`
# adjust offset by 1 for bash arrays (1 = 0)
((entryid_var--))
# determine direction based on chronological date order
if [ "$CHRON_ORDER" = 1 ]; then
	let before_entryid=${entryid_var}+1
	let after_entryid=${entryid_var}-1
else
	let before_entryid=${entryid_var}-1
	let after_entryid=${entryid_var}+1
fi
if [ "$before_entryid" -ge 0 ]; then
	before_entry=${BAENTRY_IDLIST[$before_entryid]%%\>[0-9]*}
else
	before_entry=
fi
if [ "$after_entryid" -ge 0 ]; then
	after_entry=${BAENTRY_IDLIST[$after_entryid]%%\>[0-9]*}
else
	after_entry=
fi
}

# set link/file for given category
set_catlink(){
catlink_var="$1"
# title-based links
category_title=`nb_print "$NB_DATA_DIR/$catlink_var" 1`
category_dir=`set_smartlinktitle "$catlink_var" cat`
# failsafe for setting cat directories
: ${category_dir:=${catlink_var%%\.*}}
category_file="$category_dir/$NB_INDEXFILE"
category_link="$category_dir/$NB_INDEX"
}

# set link/file for given month
set_monthlink(){
month_dir="${1//\-//}"
month_file="$month_dir/$NB_INDEXFILE"
NB_ArchiveMonthLink="$month_dir/$NB_INDEX"
}

set_daylink(){
day_dir="${1//\-//}"
day_file="$day_dir/$NB_INDEXFILE"
NB_ArchiveDayLink="$day_dir/$NB_INDEX"
}

set_daynavlinks(){
daynavlinks_var="${1//\//-}"
day_id=
[ ! -z "$daynavlinks_var" ] &&
	day_id=`lookup_id "$daynavlinks_var" "${DAY_DB_RESULTS[*]}"`
if [ ! -z "$day_id" ] && [ $day_id -gt 0 ]; then
	# adjust for bash array - 1 = 0
	((day_id--))
	# determine direction based on chronological date order
	if [ "$CHRON_ORDER" = 1 ]; then
		let prev_dayid=${day_id}+1
		let next_dayid=${day_id}-1
	else
		let prev_dayid=${day_id}-1
		let next_dayid=${day_id}+1
	fi
	prev_day=; NB_PrevArchiveDayLink=
	[ $prev_dayid -ge 0 ] &&
		prev_day=${DAY_DB_RESULTS[$prev_dayid]}
	if [ ! -z "$prev_day" ]; then
		prev_day_dir="${prev_day//\-//}"
		prev_day_file="$prev_day_dir/$NB_INDEXFILE"
		NB_PrevArchiveDayLink="$prev_day_dir/$NB_INDEX"
	fi
	next_day=; NB_NextArchiveDayLink=
	[ $next_dayid -ge 0 ] &&
		next_day=${DAY_DB_RESULTS[$next_dayid]}
	if [ ! -z "$next_day" ]; then
		next_day_dir="${next_day//\-//}"
		next_day_file="$next_day_dir/$NB_INDEXFILE"
		NB_NextArchiveDayLink="$next_day_dir/$NB_INDEX"
	fi
fi
}

# set previous and next links for given month
set_monthnavlinks(){
monthnavlinks_var="${1//\//-}"
month_id=
[ ! -z "$monthnavlinks_var" ] &&
	month_id=`lookup_id "$monthnavlinks_var" "${MONTH_DB_RESULTS[*]}"`
if [ ! -z "$month_id" ] && [ $month_id -gt 0 ]; then
	# adjust for bash array - 1 = 0
	((month_id--))
	# determine direction based on chronological date order
	if [ "$CHRON_ORDER" = 1 ]; then
		let prev_monthid=${month_id}+1
		let next_monthid=${month_id}-1
	else
		let prev_monthid=${month_id}-1
		let next_monthid=${month_id}+1
	fi
	prev_month=; NB_PrevArchiveMonthLink=
	[ $prev_monthid -ge 0 ] &&
		prev_month=${MONTH_DB_RESULTS[$prev_monthid]}
	if [ ! -z "$prev_month" ]; then
		prev_month_dir="${prev_month//\-//}"
		prev_month_file="$prev_month_dir/$NB_INDEXFILE"
		NB_PrevArchiveMonthLink="$prev_month_dir/$NB_INDEX"
	fi
	next_month=; NB_NextArchiveMonthLink=
	[ $next_monthid -ge 0 ] &&
		next_month=${MONTH_DB_RESULTS[$next_monthid]}
	if [ ! -z "$next_month" ]; then
		next_month_dir="${next_month//\-//}"
		next_month_file="$next_month_dir/$NB_INDEXFILE"
		NB_NextArchiveMonthLink="$next_month_dir/$NB_INDEX"
	fi
fi
}

# generate entry's anchor/id
set_entryid(){
echo "$x_id$1" |sed -e '/[\/]/ s//-/g'
}

# use instead of translit_text to avoid file/URL collissions
set_smartlinktitle(){
altlink_var="$1"
altlink_type="$2"
case "$altlink_type" in
	entry)
		[ -f "$NB_DATA_DIR/$altlink_var" ] &&
			read_metadata TITLE "$NB_DATA_DIR/$altlink_var"
		altentry_linktitle=`translit_text "$METADATA"`
		alte_day=`echo "$altlink_var" |cut -c1-10`
		query_db "$alte_day"
		ALTLINK_LIST=(${DB_RESULTS[*]})
		for alte in ${ALTLINK_LIST[*]}; do
			[ -f "$NB_DATA_DIR/$alte" ] &&
				read_metadata TITLE "$NB_DATA_DIR/$alte"
			alte_linktitle=`translit_text "$METADATA"`
			# entry title failsafe
			[ -z "$alte_linktitle" ] &&
				alte_linktitle=`translit_text "$notitle"`
			echo "$alte:$alte_linktitle"
		done |sort $SORT_ARGS > "$SCRATCH_FILE".altlinks
		link_match="$altentry_linktitle"
		alte_backup=${altlink_var//-//}; alte_backup=${alte_backup//T//T}
		alte_backup=${alte_backup%%.*}; altlink_backup="${alte_backup//*\/}"
		;;
	cat)
		[ -f "$NB_DATA_DIR/$altlink_var" ] &&
			altcat_title=`nb_print "$NB_DATA_DIR/$altlink_var" 1`
		altcat_linktitle=`translit_text "$altcat_title"`
		query_db # get categories list
		ALTLINK_LIST=(${db_categories[*]})
		for altt in ${ALTLINK_LIST[*]}; do
			[ -f "$NB_DATA_DIR/$altt" ] &&
				altt_title=`nb_print "$NB_DATA_DIR/$altt" 1`
			altt_linktitle=`translit_text "$altt_title"`
			# cat title failsafe
			[ -z "$altt_linktitle" ] &&
				altt_linktitle=`translit_text "$notitle"`
			echo "$altt:$altt_linktitle"
		done |sort -ru > "$SCRATCH_FILE".altlinks
		link_match="$altcat_linktitle"
		altlink_backup=${altlink_var%%\.*}
		;;
esac
# link match failsafe
[ -z "$link_match" ] &&
	link_match=`translit_text "$notitle"`
get_linkconflicts(){
	linkmatch_var="$1"
	if [ ! -z "$linkmatch_var" ]; then
		grep -c ":${linkmatch_var}$" "$SCRATCH_FILE".altlinks
	else
		echo 0
	fi
	}
TOTAL_LINKCFLICTS=`get_linkconflicts "$link_match"`
ALTLINK_LIST=(`cut -d":" -f 1 "$SCRATCH_FILE".altlinks`)
altli=0
while [ "$TOTAL_LINKCFLICTS" -gt 1 ]; do
	for altl in ${ALTLINK_LIST[*]}; do
		altl_match=`grep -c ":${link_match}$" "$SCRATCH_FILE".altlinks`
		if [ "$altl_match" -gt 1 ]; then
			let altli=${altl_match}-1
			sed -e '/'$altl':*.*/ s//'$altl':'$link_match'_'${altli}'/' "$SCRATCH_FILE".altlinks > "$SCRATCH_FILE".altlinks.new
			mv "$SCRATCH_FILE".altlinks.new "$SCRATCH_FILE".altlinks
		else
			altli=0 # reset counter
		fi
	done
	TOTAL_LINKCFLICTS=`get_linkconflicts "$link_match"`
done
smart_linktitle=`sed -e '/'$altlink_var':/!d; /'$altlink_var':/ s///' "$SCRATCH_FILE".altlinks`
# smart linktitle failsafe and backwards compatibility
[ -z "$smart_linktitle" ] || [ "$FRIENDLY_LINKS" != 1 ] &&
	smart_linktitle="$altlink_backup"
echo "$smart_linktitle"
}

# set link/file for given entry
set_entrylink(){
entrylink_var="$1"
link_type="$2"
if [ "$ENTRY_ARCHIVES" = 1 ] && [ "$link_type" != altlink ]; then
	entrylink_var="${entrylink_var//-//}"
	#entry_dir=`echo "$entrylink_var" |cut -d"." -f 1 |cut -c1-10`
	entry_dir=`echo "${entrylink_var%%\.*}" |cut -c1-10`
	entry_linktitle=`set_smartlinktitle "${entrylink_var//\//-}" entry`
	permalink_file="$entry_dir/$entry_linktitle/$NB_INDEXFILE"
	NB_EntryPermalink="$entry_dir/$entry_linktitle/$NB_INDEX"

	month=`echo "$entrylink_var" |cut -c1-7`
	set_monthlink "$month"
	day=`echo "$entrylink_var" |cut -c1-10`
	set_daylink "$day"
else
	month=`echo "$entrylink_var" |cut -c1-7`
	set_monthlink "$month"
	entrylink_id=`set_entryid $entrylink_var`
	NB_EntryPermalink="$NB_ArchiveMonthLink#$entrylink_id"
	if [ "$DAY_ARCHIVES" = 1 ]; then
		day=`echo "$entrylink_var" |cut -c1-10`
		set_daylink "$day"
		NB_EntryPermalink="$NB_ArchiveDayLink#$entrylink_id"
	fi
fi
}

# set previous and next links for given entry
set_entrynavlinks(){
entrynavlinks_type="$1"
entrynavlinks_entry=`echo "$2" |grep '^[0-9].*'`
if [ "$entrynavlinks_type" = prev ]; then
	prev_entry=; NB_PrevEntryPermalink=
	prev_entry="$entrynavlinks_entry"
fi
if [ "$entrynavlinks_type" = next ]; then
	next_entry=; NB_NextEntryPermalink=
	next_entry="$entrynavlinks_entry"
fi
if [ ! -z "$prev_entry" ]; then
	# Nijel: support for named permalinks
	prev_entrylink_var=`echo $prev_entry |sed -e '/[-]/ s//\//g'`
	prev_entry_dir=`echo "$prev_entrylink_var" |cut -d"." -f 1 |cut -c1-10`
	prev_entry_linktitle=`set_smartlinktitle "$prev_entry" entry`
	prev_permalink_file="$prev_entry_dir/$prev_entry_linktitle/$NB_INDEXFILE"
	NB_PrevEntryPermalink="$prev_entry_dir/$prev_entry_linktitle/$NB_INDEX"
fi
if [ ! -z "$next_entry" ]; then
	# Nijel: support for named permalinks
	next_entrylink_var=`echo $next_entry |sed -e '/[-]/ s//\//g'`
	next_entry_dir=`echo "$next_entrylink_var" |cut -d"." -f 1 |cut -c1-10`
	next_entry_linktitle=`set_smartlinktitle "$next_entry" entry`
	next_permalink_file="$next_entry_dir/$next_entry_linktitle/$NB_INDEXFILE"
	NB_NextEntryPermalink="$next_entry_dir/$next_entry_linktitle/$NB_INDEX"
fi
}

# tool to build list of related categories from list of entries
find_categories(){
FIND_CATLIST=($1)
cat_list=()
build_catlist(){
[ ! -z "$cat_var" ] &&
	cat_list=( ${cat_list[@]} $cat_db )
}
# acquire all the categories
for relative_entry in ${FIND_CATLIST[@]}; do
	raw_db "$relative_entry"
	cat_ids=`print_cat "${DB_RESULTS[*]}"`
	cat_ids="${cat_ids//\,/ }"
	for cat_id in $cat_ids; do
		cat_var="$cat_id"
		cat_db="cat_$cat_id.$NB_DBTYPE"
		build_catlist
	done
	cat_id=; cat_ids=; cat_var=; cat_db=;
done
CAT_LIST=( ${cat_list[@]} )
[ -z "${CAT_LIST[*]}" ] && [ ! -z "$cat_num" ] &&
	CAT_LIST=( `cat_id "$cat_num"` )
[ "$UPDATE_WEBLOG" = 1 ] && [ "$NB_QUERY" = all ] && [ -z "$cat_num" ] && 
	CAT_LIST=${db_categories[@]}
CAT_LIST=(`for cat_id in ${CAT_LIST[@]}; do echo "$cat_id"; done |sort -u`)
}

# resort category databases from list
resort_categories(){
RESORT_CATDBLIST=($1)
[ -z "${RESORT_CATDBLIST[*]}" ] && RESORT_CATDBLIST=(${CAT_LIST[*]})
for mod_catdb in ${CAT_LIST[@]}; do
	resort_catdb "$NB_DATA_DIR/$mod_catdb"
done
}

# update categories with cateogory id's from main db with list of entries
update_categories(){
UPDATE_CATLIST=($1)
[ -z "${UPDATE_CATLIST[*]}" ] && UPDATE_CATLIST=(${UPDATE_LIST[*]})
for ucat_entry in ${UPDATE_CATLIST[@]}; do
	cat_ids=`get_catids "$ucat_entry" "$NB_DATA_DIR/master.$NB_DBTYPE"`
	cat_ids="${cat_ids//\,/ }"
	for cat_id in $cat_ids; do
		cat_var="$cat_id"
		cat_db="cat_$cat_id.$NB_DBTYPE"
		update_catdb "$ucat_entry" "$NB_DATA_DIR/$cat_db"
	done
	cat_id=; cat_ids=; cat_var=; cat_db=;
done
}

# generate timestamp as metadata variables
meta_timestamp(){
NB_MetaDate=`filter_dateformat "$DATE_FORMAT"`
NB_MetaTimeStamp=`nb_timestamp`
# fallback to printable timestamp
if [ -z "$NB_MetaDate" ]; then
	nb_msg "$filter_datefailed"
	NB_MetaDate=`filter_timestamp "$NB_MetaTimeStamp"`
fi
}

# read file's metadata
read_metadata(){
META_FILE="$2"
MVAR_CLOSE=`echo "$1" |sed -e '/[^ ].*[\,]/ s///'`
if [ "$1" != "$MVAR_CLOSE" ] && [ ! -z "$MVAR_CLOSE" ]; then
	MVAR=`echo "$1" |sed -e '/[\,].*[^ ]$/ s///'`
	METADATA=`sed -e '/^'$MVAR'[\:]/,/^'$MVAR_CLOSE'/!d; /^'$MVAR'[\:]/d; /^'$MVAR_CLOSE'/d' "$META_FILE"`
else
	METADATA=`sed -e '/^'$1'[\:]/!d; /^'$1'[\:] */ s///' "$META_FILE"`
fi
}

# write metadata out to file
write_metadata(){
METADATA="$2"
META_FILE="$3"
MVAR_CLOSE=`echo "$1" |sed -e '/[^ ].*[\,]/ s///'`
if [ ! -z "$1" ] && [ ! -z "$METADATA" ]; then
	if [ "$1" != "$MVAR_CLOSE" ] && [ ! -z "$MVAR_CLOSE" ]; then
		MVAR=`echo "$1" |sed -e '/[\,].*[^ ]$/ s///'`
		if [ -f "$META_FILE" ]; then
			META_OTHER=`sed -e '/^'$MVAR'[\:]/,/^'$MVAR_CLOSE'/d; /^'$MVAR'[\:]/d; /^'$MVAR_CLOSE'/d' "$META_FILE"`
		fi
		cat > "$META_FILE" <<-EOF
			$META_OTHER
			$MVAR:
			$METADATA
			$MVAR_CLOSE
		EOF
	else
		if [ -f "$META_FILE" ]; then
			META_OTHER=`sed -e '/^'$1'[\:]/d' "$META_FILE"`
		fi
		# prepend modified or new single line vars
		cat > "$META_FILE" <<-EOF
			$1: $METADATA
			$META_OTHER
		EOF
	fi
fi
}

# create/modify user metadata field
write_var(){
WRITE_MVAR="$1"
WRITE_MVARVALUE="$2"
WRITEMETAVAR_FILE="$3"
[ ! -z "$USR_METAVAR" ] && WRITE_MVAR="$USR_METAVAR"
[ ! -z "$USR_VARVALUE" ] && WRITE_MVARVALUE="$USR_VARVALUE"
if [ ! -z "$WRITE_MVAR" ]; then
	write_metadata "$WRITE_MVAR" "$WRITE_MVARVALUE" \
		"$WRITEMETAVAR_FILE"
fi
}

# load standard metadata from file into tangible shell variables
load_metadata(){
METADATA_TYPE="$1" # ALL, NOBODY, or valid metadata key
METADATA_FILE="$2"
[ ! -f "$METADATA_FILE" ] &&
	die "'$METADATA_FILE' $importfile_nofile"
case $METADATA_TYPE in
	AUTHOR)
		read_metadata AUTHOR "$METADATA_FILE"; NB_MetaAuthor="$METADATA"
		NB_EntryAuthor="$NB_MetaAuthor";;
	BODY)
		read_metadata "BODY,$METADATA_CLOSEVAR" "$METADATA_FILE"; NB_MetaBody="$METADATA"
		NB_EntryBody="$NB_MetaBody";;
	DATE)
		read_metadata DATE "$METADATA_FILE"; NB_MetaDate="$METADATA"
		NB_EntryDate="$NB_MetaDate";;
	DESC)
		NB_EntryDescription="$NB_MetaDescription"
		read_metadata FORMAT "$METADATA_FILE"; NB_MetaFormat="$METADATA";;
	FORMAT)
		read_metadata FORMAT "$METADATA_FILE"; NB_MetaFormat="$METADATA"
		NB_EntryFormat="$NB_MetaFormat";;
	TITLE)
		read_metadata TITLE "$METADATA_FILE"; NB_MetaTitle="$METADATA"
		NB_EntryTitle="$NB_MetaTitle";;
	ALL)
		load_metadata AUTHOR "$METADATA_FILE"; load_metadata TITLE "$METADATA_FILE"
		load_metadata DATE "$METADATA_FILE"; load_metadata DESC "$METADATA_FILE"
		load_metadata FORMAT "$METADATA_FILE"; load_metadata BODY "$METADATA_FILE";;
	NOBODY)
		load_metadata AUTHOR "$METADATA_FILE"; load_metadata TITLE "$METADATA_FILE"
		load_metadata DATE "$METADATA_FILE"; load_metadata DESC "$METADATA_FILE"
		load_metadata FORMAT "$METADATA_FILE";;
	*)
		load_metadata ALL "$METADATA_FILE";;
esac
}

# write entry's metadata to file
write_entry(){
WRITE_ENTRY_FILE="$1"
# help ease transition from 3.2.x or earlier
[ ! -f "$NB_TEMPLATE_DIR/$METADATAENTRY_TEMPLATE" ] &&
	cp "$NB_BASE_DIR/default/templates/$METADATAENTRY_TEMPLATE" "$NB_TEMPLATE_DIR"
load_template "$NB_TEMPLATE_DIR/$METADATAENTRY_TEMPLATE"
write_template > "$WRITE_ENTRY_FILE"
write_var "$USR_METAVAR" "$USR_VARVALUE" "$WRITE_ENTRY_FILE"
}

# load entry from it's metadata file
load_entry(){
ENTRY_FILE="$1"
ENTRY_DATATYPE="$2"
ENTRY_CACHETYPE="$3"
: ${ENTRY_PLUGINSLIST:=entry entry/mod entry/format}
: ${ENTRY_DATATYPE:=ALL}
if [ -f "$ENTRY_FILE" ]; then
	entry_day=`echo "$entry" |cut -c9-10`
	entry_time=`filter_timestamp "$entry" |cut -c12-19`
	if [ -z "$ENTRY_CACHETYPE" ]; then
		if [ ! -z "$CACHE_TYPE" ]; then
			ENTRY_CACHETYPE="$CACHE_TYPE"
		else
			ENTRY_CACHETYPE=metadata
		fi
	fi
	if [ "$ENTRY_DATATYPE" != ALL ] || [ "$ENTRY_DATATYPE" = NOBODY ]; then
		NB_EntryID=`set_entryid $entry`
		load_metadata "$ENTRY_DATATYPE" "$ENTRY_FILE"
		load_plugins entry
	else
		NB_EntryID=`set_entryid $entry`
		load_metadata NOBODY "$ENTRY_FILE"
		# use cache when entry data unchanged
		if [ "$ENTRY_FILE" -nt "$BLOG_DIR/$CACHE_DIR/$entry.$ENTRY_CACHETYPE" ]; then
			#nb_msg "UPDATING CACHE - $entry.$ENTRY_CACHETYPE"
			read_metadata "BODY,$METADATA_CLOSEVAR" "$ENTRY_FILE"
			NB_EntryBody="$METADATA"
			for entry_pluginsdir in $ENTRY_PLUGINSLIST; do
				if [ "$entry_pluginsdir" = "entry/format" ]; then
					[ -z "$NB_EntryFormat" ] && NB_EntryFormat="$ENTRY_FORMAT"
					load_plugins $entry_pluginsdir "$NB_EntryFormat"
				else
					load_plugins $entry_pluginsdir
				fi
			done
			write_entry "$BLOG_DIR/$CACHE_DIR/$entry.$ENTRY_CACHETYPE"
			# update cache list for some post-cache management
			#update_cache build $ENTRY_CACHETYPE "$entry"
		else
			#nb_msg "LOADING CACHE - $entry.$ENTRY_CACHETYPE"
			load_metadata ALL "$BLOG_DIR/$CACHE_DIR/$entry.$ENTRY_CACHETYPE"
			load_plugins entry
		fi
	fi
fi
}

# create file with metadata fields
make_file(){
WRITE_META_FILE="$1"
WRITE_META_TEMPLATE="$2"
# defaults to metafile template
[ -z "$WRITE_META_TEMPLATE" ] &&
	WRITE_META_TEMPLATE="$NB_TEMPLATE_DIR/$METADATAFILE_TEMPLATE"
# help ease transition from 3.2.x or earlier
[ ! -f "$NB_TEMPLATE_DIR/$METADATAFILE_TEMPLATE" ] &&
	cp "$NB_BASE_DIR/default/templates/$METADATAFILE_TEMPLATE" "$NB_TEMPLATE_DIR"
# accept user metadata
[ ! -z "$USR_AUTHOR" ] && NB_MetaAuthor="$USR_AUTHOR"
[ -z "$NB_MetaAuthor" ] && NB_MetaAuthor="$BLOG_AUTHOR"
[ ! -z "$USR_DESC" ] && NB_MetaDescription="$USR_DESC"
if [ ! -z "$USR_TITLE" ]; then
	NB_MetaTitle="$USR_TITLE"; USR_TITLE=
fi
[ ! -z "$USR_TEXT" ] && NB_MetaBody="$USR_TEXT"
meta_timestamp
load_template "$WRITE_META_TEMPLATE"
write_template > "$WRITE_META_FILE"
write_var "$USR_METAVAR" "$USR_VARVALUE" "$WRITE_META_FILE"
}

# create weblog page from text (parts) files
make_page(){
MKPAGE_SRCFILE="$1"
MKPAGE_TEMPLATE="$2"
MKPAGE_OUTFILE="$3"
if [ -z "$MKPAGE_TITLE" ] && [ ! -z "$USR_TITLE" ]; then
	MKPAGE_TITLE="$USR_TITLE"; USR_TITLE=
fi
if [ ! -z "$MKPAGE_TITLE" ]; then
	NB_MetaTitle="$MKPAGE_TITLE"
	# Set NB_EntryTitle for backwards compatibility
	NB_EntryTitle="$MKPAGE_TITLE"
fi
[ ! -z "$USR_TEMPLATE" ] && MKPAGE_TEMPLATE="$USR_TEMPLATE"
[ -z "$MKPAGE_TEMPLATE" ] &&
	MKPAGE_TEMPLATE="$NB_TEMPLATE_DIR/$MAKEPAGE_TEMPLATE"
[ ! -f "$MKPAGE_SRCFILE" ] && die "'$MKPAGE_SRCFILE' - $makepage_nosource"
[ -z "$MKPAGE_OUTFILE" ] && die "'$MKPAGE_OUTFILE' - $makepage_nooutput"
[ ! -f "$MKPAGE_TEMPLATE" ] && die "'$MKPAGE_TEMPLATE' - $makepage_notemplate"
# make sure the output directory is present before writing to it
mkdir -p `dirname "$MKPAGE_OUTFILE"`
set_baseurl "" "$MKPAGE_OUTFILE"
# load file as content
: ${MKPAGE_CONTENT:=$(< "$MKPAGE_SRCFILE")}
# let plugins modify the content
load_plugins page
: ${MKPAGE_FORMAT:=$PAGE_FORMAT}
load_plugins page/format "$MKPAGE_FORMAT"
# Set NB_Entries for backwards compatibility
NB_MetaBody="$MKPAGE_CONTENT"; NB_Entries="$MKPAGE_CONTENT"
load_template "$MKPAGE_TEMPLATE"
write_template > "$MKPAGE_OUTFILE"
nb_msg "$MKPAGE_OUTFILE"
load_plugins makepage
MKPAGE_CONTENT=; MKPAGE_FORMAT=; MKPAGE_TITLE=; NB_MetaTitle=; NB_EntryTitle=
}

# creates weblog page from metafile
weblog_page(){
BLOGPAGE_SRCFILE="$1"
BLOGPAGE_TEMPLATE="$2"
BLOGPAGE_OUTFILE="$3"
[ ! -z "$USR_TEMPLATE" ] && BLOGPAGE_TEMPLATE="$USR_TEMPLATE"
if [ -f "$BLOGPAGE_SRCFILE" ]; then
	write_var "$USR_METAVAR" "$USR_VARVALUE" "$BLOGPAGE_SRCFILE"
	load_metadata ALL "$BLOGPAGE_SRCFILE"
	[ ! -z "$USR_AUTHOR" ] && NB_MetaAuthor="$USR_AUTHOR"
	[ -z "$NB_MetaAuthor" ] && NB_MetaAuthor="$BLOG_AUTHOR"
	[ ! -z "$USR_DESC" ] && NB_MetaDescription="$USR_DESC"
	[ ! -z "$USR_TITLE" ] && NB_MetaTitle="$USR_TITLE"
	[ ! -z "$USR_TEXT" ] && NB_MetaBody="$USR_TEXT"
	MKPAGE_CONTENT="$NB_MetaBody"
	MKPAGE_FORMAT="$NB_MetaFormat"
	: ${MKPAGE_FORMAT:=$BLOGPAGE_FORMAT}
	make_page "$BLOGPAGE_SRCFILE" "$BLOGPAGE_TEMPLATE" "$BLOGPAGE_OUTFILE"
fi
}

# edit draft file
nb_draft(){
EDITDRAFT_FILE="$1"
[ ! -z "$USR_DRAFTFILE" ] && EDITDRAFT_FILE="$USR_DRAFTFILE"
if [ ! -z "$EDITDRAFT_FILE" ] && [ ! -f "$EDITDRAFT_FILE" ]; then
	echo "'$EDITDRAFT_FILE' - $nbdraft_asknew [Y/n]"
	read -p "$NB_PROMPT" choice
	case $choice in
		[Yy]|"")
			make_file "$EDITDRAFT_FILE" "$USR_TEMPLATE";;
		[Nn])
		;;
	esac
fi
if [ -f "$EDITDRAFT_FILE" ]; then
	nb_edit "$EDITDRAFT_FILE"
	# validate metafile
	check_metavars "TITLE: BODY: $METADATA_CLOSEVAR" "$EDITDRAFT_FILE"
	# modify date (DATE metadata)
	meta_timestamp && write_metadata DATE "$NB_MetaDate" "$EDITDRAFT_FILE"
fi
}

preview_weblog(){
[ -z "$BLOG_PREVIEW_CMD" ] && die "$preview_nocmd"
if [ "$BLOG_INTERACTIVE" = 1 ]; then
	echo "$preview_asknow [y/N]"
	read -p "$NB_PROMPT" choice
	case $choice in
		[Yy])
			nb_msg "$preview_action"
			$BLOG_PREVIEW_CMD;;
		[Nn]|"")
		;;
	esac
else
	nb_msg "$preview_action"
	$BLOG_PREVIEW_CMD
fi
}

publish_weblog(){
[ -z "$BLOG_PUBLISH_CMD" ] && die "$publish_nocmd"
if [ "$BLOG_INTERACTIVE" = 1 ]; then
	echo "$publish_asknow [y/N]"
	read -p "$NB_PROMPT" choice
	case $choice in
		[Yy])
			nb_msg "$publish_action"
			$BLOG_PUBLISH_CMD;;
		[Nn]|"")
			;;
	esac
else
	nb_msg "$publish_action"
	$BLOG_PUBLISH_CMD
fi
}

# tool to help manage the cache
update_cache(){
cache_update="$1"
cache_def="$2"
CACHEUPDATE_LIST=($3)
case "$cache_update" in
	build)
	[ -z "$cache_def" ] && cache_def=entry_metadata
	for cache_item in ${CACHEUPDATE_LIST[@]}; do
		echo "$cache_item" >> "$SCRATCH_FILE".$cache_def-cache_list
	done
	CACHEUPDATE_LIST=($(< "$SCRATCH_FILE".$cache_def-cache_list));;
	rebuild)
	> "$SCRATCH_FILE".$cache_def-cache_list
	[ -z "$cache_def" ] && cache_def=entry_metadata
	for cache_item in ${CACHEUPDATE_LIST[@]}; do
		echo "$cache_item" >> "$SCRATCH_FILE".$cache_def-cache_list
		rm -f "$BLOG_DIR/$CACHE_DIR/$cache_item".$cache_def
	done
	CACHEUPDATE_LIST=($(< "$SCRATCH_FILE".$cache_def-cache_list));;
	expired)
	[ -z "$cache_def" ] && cache_def="*"
	# always cache more recent entries
	[ "$CHRON_ORDER" != 1 ] && db_order="-ru"
	query_db all "$db_catquery" limit "$MAX_CACHE_ENTRIES" "" "$db_order"
	for cache_item in "$BLOG_DIR/$CACHE_DIR"/*.$cache_def; do
		cache_item=${cache_item##*\/}
		cache_regex="${cache_item%%\.$cache_def*}"
		cache_match=`echo "${DB_RESULTS[*]}" |grep -c "$cache_regex"`
		[ "$cache_match" = 0 ] &&
			rm -f "$BLOG_DIR/$CACHE_DIR/$cache_item"
	done;;
	*)
	[ -z "$cache_def" ] &&
		cache_def="*"
	[ ! -z "$cache_update" ] && query_db "$cache_update" "$db_catquery"
	for cache_item in ${DB_RESULTS[@]}; do
		rm -f "$BLOG_DIR/$CACHE_DIR/$cache_item".$cache_def
	done;;
esac
[ ! -z "${CACHEUPDATE_LIST[*]}" ] &&
	CACHE_LIST=(`for cache_item in ${CACHEUPDATE_LIST[@]}; do echo $cache_item; done |sort -u`)
}

# tool to help change an entry's date/timestamp
# (e.g. TIMESTAMP: YYYY-MM-DD HH:MM:SS)
chg_entrydate(){
EntryDate_File="$1"
EntryDate_TimeStamp="$2"
# read timestamp from command line
[ "$USR_METAVAR" = TIMESTAMP ] &&
	EntryDate_TimeStamp="$USR_VARVALUE"
# validate timestamp format
Edit_EntryTimeStamp=`refilter_timestamp "$EntryDate_TimeStamp"`
New_EntryTimeStamp=`validate_timestamp "$Edit_EntryTimeStamp"`
# abort if we don't have a valid timestamp
[ ! -z "$EntryDate_TimeStamp" ] && [ -z "$New_EntryTimeStamp" ] &&
	die "TIMESTAMP != 'YYYY-MM-DD HH:MM:SS'"
if [ ! -z "$New_EntryTimeStamp" ]; then
	[ ! -f "$SCRATCH_FILE.mod-catdbs" ] &&
		> "$SCRATCH_FILE.mod-catdbs"
	New_EntryDateFile="$New_EntryTimeStamp.$NB_DATATYPE"
	if [ -f "$NB_DATA_DIR/$EntryDate_File" ] && [ "$EntryDate_File" != "$New_EntryDateFile" ]; then
		Old_EntryFile="$EntryDate_File"
		mv "$NB_DATA_DIR/$Old_EntryFile" "$NB_DATA_DIR/$New_EntryDateFile"
		set_entrylink "$Old_EntryFile"
		Delete_PermalinkFile="$BLOG_DIR/$ARCHIVES_DIR/$permalink_file"
		Delete_PermalinkDir="$BLOG_DIR/$ARCHIVES_DIR/$entry_dir"
		# delete old permalink file
		[ -f "$Delete_PermalinkFile" ] && rm -fr "$Delete_PermalinkFile"
		# delete old permalink directory
		[ ! -z "$entry_dir" ] && [ -d "$Delete_PermalinkDir" ] &&
			rm -fr "$Delete_PermalinkDir"
		# delete the old cache data
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

