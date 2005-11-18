# Module for utility functions

# create a semi ISO 8601 formatted timestamp for archives
# used explicitly, please don't edit unless you know what you're doing.
nb_timestamp(){ $DATE_CMD "+%Y-%m-%dT%H_%M_%S"; }

# convert to a more printable date format
filter_timestamp(){
echo "$1" |sed -e '/[\_]/ s//:/g; /[A-Z]/ s// /g'
}

# reverse filter time stamp to original form
refilter_timestamp(){
echo "$1" |sed -e '/[\:]/ s//_/g; /[ ]/ s//T/'
}

# validate time stamp
validate_timestamp(){
echo "$1" |grep '^[0-9][0-9][0-9][0-9][\-][0-9][0-9][\-][0-9][0-9][A-Z][0-9][0-9][\_][0-9][0-9][\_][0-9][0-9]$'
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

# filter custom date string using GNU specific 'date -d'
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
a
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

# function to require confirmation
confirm_action(){
nb_msg "$confirmaction_ask [y/N]"
read -p "$NB_PROMPT" confirm
case $confirm in
	[Yy]);;
	[Nn]|"") die;;
esac
}

# wrapper to editor command
nb_edit(){
# TODO: test with external editor (outside of script's process)
EDIT_FILE="$1"
$EDITOR "$EDIT_FILE"
if [ ! -f "$EDIT_FILE" ]; then
	nb_msg "'$EDIT_FILE' - $nbedit_nofile"
	echo "$nbedit_prompt"
	read -p "$NB_PROMPT" enter_key
fi
[ ! -f "$EDIT_FILE" ] && die "'$EDIT_FILE' - $nbedit_failed"
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
			nb_msg "$catid_bad"
	done
fi
}

# validate category's id number
check_catid(){
cat_list=`cat_id`
for cat_db in $cat_list; do
	[ ! -f "$NB_DATA_DIR/$cat_db" ] &&
		die "$checkcatid_invalid $cat_num"
done
[ ! -z "$cat_num" ] && [ -z "$cat_list" ] && die "$checkcatid_novalid"
}

# check file for required metadata tags
check_metatags(){
VALIDATE_TAGS="$1"
VALIDATE_METAFILE="$2"
for mtag in $VALIDATE_TAGS; do
	MTAG_NUM=`grep -c "^$mtag" "$VALIDATE_METAFILE"`
	[ "$MTAG_NUM" = 0 ] &&
		die "'$VALIDATE_METAFILE' - $checkmetatags_notag '$mtag'"
done
}

# import metafile
import_file(){
IMPORT_FILE="$1"
if [ -f "$IMPORT_FILE" ]; then
	# validate metafile
	check_metatags "TITLE: AUTHOR: DATE: BODY: $METADATA_CLOSETAG" \
		"$IMPORT_FILE"
	load_metadata ALL "$IMPORT_FILE"
else
	nb_msg "'$IMPORT_FILE' $importfile_nofile"
fi
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

# tool to lookup entry's id from "master" query type
lookup_entryid(){
echo "$2" |grep -n "$1" |cut -d":" -f 1 |grep '^[0-9].*$'
}

# tool to lookup month's id from "all" query type
lookup_monthid(){
echo "$2" |cut -c1-7 |sort $SORT_ARGS |grep -n "$1" |cut -d":" -f 1 |grep '^[0-9].*$'
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
}

# set link/file for given month
set_monthlink(){
month_dir=`echo $1 |sed -e '/[-]/ s//\//g'`
month_file="$month_dir/$NB_INDEXFILE"
NB_ArchiveMonthLink="$month_dir/$NB_INDEX"
}

# set previous and next links for given month
set_monthnavlinks(){
monthnavlinks_var=`echo "$1" |sed -e '/\// s//\-/g'`
month_id=
[ ! -z "$monthnavlinks_var" ] &&
	month_id=`lookup_monthid "$monthnavlinks_var" "$MASTER_DB_RESULTS"`
if [ ! -z "$month_id" ] && [ $month_id -gt 0 ]; then
	prev_monthid=`expr $month_id + 1`
	next_monthid=`expr $month_id - 1`
	prev_month=; NB_PrevArchiveMonthLink=
	[ $prev_monthid -gt 0 ] &&
		prev_month=`echo "$MASTER_DB_RESULTS" |cut -c1-7 |sort $SORT_ARGS |sed ''$prev_monthid'!d'`
	if [ ! -z "$prev_month" ]; then
		prev_month_dir=`echo $prev_month |sed -e '/[-]/ s//\//g'`
		prev_month_file="$prev_month_dir/$NB_INDEXFILE"
		NB_PrevArchiveMonthLink="$prev_month_dir/$NB_INDEX"
	fi
	next_month=; NB_NextArchiveMonthLink=
	[ $next_monthid -gt 0 ] &&
		next_month=`echo "$MASTER_DB_RESULTS" |cut -c1-7 |sort $SORT_ARGS |sed ''$next_monthid'!d'`
	if [ ! -z "$next_month" ]; then
		next_month_dir=`echo $next_month |sed -e '/[-]/ s//\//g'`
		next_month_file="$next_month_dir/$NB_INDEXFILE"
		NB_NextArchiveMonthLink="$next_month_dir/$NB_INDEX"
	fi
fi
}

# generate entry's anchor/id
set_entryid(){
echo "$x_id$1" |sed -e '/[\/]/ s//-/g'
}

# set link/file for given entry
set_entrylink(){
entrylink_var="$1"
link_type="$2"
if [ "$ENTRY_ARCHIVES" = 1 ] && [ "$link_type" != altlink ]; then
	# default
	entrylink_mod=`echo $entrylink_var |sed -e '/[-]/ s//\//g'`
	entry_dir=`echo "$entrylink_mod" |cut -d "." -f 1 |sed -e '/\T/ s//\/T/g'`
	permalink_file="$entry_dir/$NB_INDEXFILE"
	NB_EntryPermalink="$entry_dir/$NB_INDEX"

	# experimental title-based links
	#entrylink_var=`echo $entrylink_var |sed -e '/[-]/ s//\//g'`
	#entry_dir=`echo "$entrylink_var" |cut -d"." -f 1 |cut -c1-10`
	#entry_linkname=`set_title2link "$NB_EntryTitle"`
	#permalink_file="$entry_dir/$entry_linkname/$NB_INDEXFILE"
	#NB_EntryPermalink="$entry_dir/$entry_linkname/$NB_INDEX"

	month=`echo "$entrylink_mod" |cut -c1-7`
	set_monthlink "$month"

else
	month=`echo "$entrylink_var" |cut -c1-7`
	set_monthlink "$month"
	entrylink_id=`set_entryid $entrylink_var`
	NB_EntryPermalink="$NB_ArchiveMonthLink#$entrylink_id"
fi
}

# set previous and next links for given entry
set_entrynavlinks(){
entrynavlinks_var=`echo "$1" |grep '^[0-9].*'`
entry_id=
[ ! -z "$entrynavlinks_var" ] &&
	entry_id=`lookup_entryid "$entrynavlinks_var" "$MASTER_DB_RESULTS"`
if [ ! -z "$entry_id" ] && [ $entry_id -gt 0 ]; then
	prev_entryid=`expr $entry_id + 1`
	next_entryid=`expr $entry_id - 1`
	prev_entry=; NB_PrevEntryPermalink=
	[ $prev_entryid -gt 0 ] &&
		prev_entry=`echo "$MASTER_DB_RESULTS" |sed ''$prev_entryid'!d'`
	if [ ! -z "$prev_entry" ]; then
		prev_entry_dir=`echo "$prev_entry" |cut -d "." -f 1 |sed -e '/[\-]/ s//\//g; /\T/ s//\/T/g'`
		prev_permalink_file="$prev_entry_dir/$NB_INDEXFILE"
		NB_PrevEntryPermalink="$prev_entry_dir/$NB_INDEX"
	fi
	next_entry=; NB_NextEntryPermalink=
	[ $next_entryid -gt 0 ] &&
		next_entry=`echo "$MASTER_DB_RESULTS" |sed ''$next_entryid'!d'`
	if [ ! -z "$next_entry" ]; then
		next_entry_dir=`echo "$next_entry" |cut -d "." -f 1 |sed -e '/[\-]/ s//\//g; /\T/ s//\/T/g'`
		next_permalink_file="$next_entry_dir/$NB_INDEXFILE"
		NB_NextEntryPermalink="$next_entry_dir/$NB_INDEX"
	fi
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
MTAG="$1"
META_FILE="$2"
MTAG_CLOSE=`echo "$MTAG" |sed -e '/[^ ].*[\,]/ s///'`
if [ "$MTAG" != "$MTAG_CLOSE" ] && [ ! -z "$MTAG_CLOSE" ]; then
	MTAG=`echo "$MTAG" |sed -e '/[\,].*[^ ]$/ s///'`
	METADATA=`sed -e '/^'$MTAG'[\:]/,/^'$MTAG_CLOSE'/!d; //d; /^'$MTAG'[\:]/d' "$META_FILE"`
else
	METADATA=`sed -e '/^'$MTAG'[\:]/!d; /^'$MTAG'[\:] */ s///' "$META_FILE"`
fi
}

# write metadata out to file
write_metadata(){
MTAG="$1"
METADATA="$2"
META_FILE="$3"
MTAG_CLOSE=`echo "$MTAG" |sed -e '/[^ ].*[\,]/ s///'`
if [ ! -z "$MTAG" ] && [ ! -z "$METADATA" ]; then
	if [ "$MTAG" != "$MTAG_CLOSE" ] && [ ! -z "$MTAG_CLOSE" ]; then
		MTAG=`echo "$MTAG" |sed -e '/[\,].*[^ ]$/ s///'`
		if [ -f "$META_FILE" ]; then
			META_OTHER=`sed -e '/^'$MTAG'[\:]/,/^'$MTAG_CLOSE'/d; //d; /^'$MTAG'[\:]/d' "$META_FILE"`
		fi
		cat > "$META_FILE" <<-EOF
			$META_OTHER
			$MTAG:
			$METADATA
			$MTAG_CLOSE
		EOF
	else
		if [ -f "$META_FILE" ]; then
			META_OTHER=`sed -e '/^'$MTAG'[\:]/d' "$META_FILE"`
		fi
		# prepend modified or new single line tags
		cat > "$META_FILE" <<-EOF
			$MTAG: $METADATA
			$META_OTHER
		EOF
	fi
fi
}

# create/modify user metadata field
write_tag(){
WRITE_MTAG="$1"
WRITE_MTAGTEXT="$2"
WRITEMETATAG_FILE="$3"
[ ! -z "$USR_METATAG" ] && WRITE_MTAG="$USR_METATAG"
[ ! -z "$USR_TAGTEXT" ] && WRITE_MTAGTEXT="$USR_TAGTEXT"
if [ ! -z "$WRITE_MTAG" ]; then
	write_metadata "$WRITE_MTAG" "$WRITE_MTAGTEXT" \
		"$WRITEMETATAG_FILE"
fi
}

# load standard metadata from file into tangible shell variables
load_metadata(){
METADATA_TYPE="$1" # ALL or NOBODY :)
METADATA_FILE="$2"
if [ -f "$METADATA_FILE" ]; then
	read_metadata TITLE "$METADATA_FILE"; NB_MetaTitle="$METADATA"
	NB_EntryTitle="$NB_MetaTitle"
	read_metadata AUTHOR "$METADATA_FILE"; NB_MetaAuthor="$METADATA"
	NB_EntryAuthor="$NB_MetaAuthor"
	read_metadata DATE "$METADATA_FILE"; NB_MetaDate="$METADATA"
	NB_EntryDate="$NB_MetaDate"
	read_metadata DESC "$METADATA_FILE"; NB_MetaDescription="$METADATA"
	NB_EntryDescription="$NB_MetaDescription"
	read_metadata FORMAT "$METADATA_FILE"; NB_MetaFormat="$METADATA"
	NB_EntryFormat="$NB_MetaFormat"
	if [ "$METADATA_TYPE" = ALL ]; then
		read_metadata "BODY,$METADATA_CLOSETAG" "$METADATA_FILE"; NB_MetaBody="$METADATA"
		NB_EntryBody="$NB_MetaBody"
	fi
fi
}

# write entry's metadata to file
write_entry(){
WRITE_ENTRY_FILE="$1"
# give upgraders a break :)
[ ! -f "$NB_TEMPLATE_DIR/$METADATAENTRY_TEMPLATE" ] &&
	cp "$NB_BASE_DIR/default/templates/$METADATAENTRY_TEMPLATE" "$NB_TEMPLATE_DIR"
load_template "$NB_TEMPLATE_DIR/$METADATAENTRY_TEMPLATE"
echo "$TEMPLATE_DATA" > "$WRITE_ENTRY_FILE"
write_tag "$USR_METATAG" "$USR_TAGTEXT" "$WRITE_ENTRY_FILE"
}

# read an entry
read_entry(){
ENTRY_FILE="$1"
if [ -f "$ENTRY_FILE" ]; then
	NB_EntryID=`set_entryid $entry`
	load_metadata NOBODY "$ENTRY_FILE"
	load_plugins entry
	if [ "$ENTRY_FILE" -nt "$BLOG_DIR/$CACHE_DIR/$entry.entry_metadata" ]; then
		read_metadata "BODY,$METADATA_CLOSETAG" "$ENTRY_FILE"
		NB_EntryBody="$METADATA"
		load_plugins entry/mod
		[ -z "$NB_EntryFormat" ] && NB_EntryFormat="$ENTRY_FORMAT"
		load_plugins entry/format "$NB_EntryFormat"
		write_entry "$BLOG_DIR/$CACHE_DIR/$entry.entry_metadata"
		update_cache build entry_metadata "$entry"
	else
		load_metadata ALL "$BLOG_DIR/$CACHE_DIR/$entry.entry_metadata"
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
# give upgraders a break :)
[ ! -f "$NB_TEMPLATE_DI/$METADATAFILE_TEMPLATE" ] &&
	cp "$NB_BASE_DIR/default/templates/$METADATAFILE_TEMPLATE" "$NB_TEMPLATE_DIR"
# accept user metadata
[ ! -z "$USR_AUTHOR" ] && NB_MetaAuthor="$USR_AUTHOR"
[ -z "$NB_MetaAuthor" ] && NB_MetaAuthor="$BLOG_AUTHOR"
[ ! -z "$USR_DESC" ] && NB_MetaDescription="$USR_DESC"
[ ! -z "$USR_TITLE" ] && NB_MetaTitle="$USR_TITLE"
[ ! -z "$USR_TEXT" ] && NB_MetaBody="$USR_TEXT"
meta_timestamp
load_template "$WRITE_META_TEMPLATE"
echo "$TEMPLATE_DATA" > "$WRITE_META_FILE"
write_tag "$USR_METATAG" "$USR_TAGTEXT" "$WRITE_META_FILE"
}

# create weblog page from text (parts) files
make_page(){
MKPAGE_SRCFILE="$1"
MKPAGE_TEMPLATE="$2"
MKPAGE_OUTFILE="$3"
[ ! -z "$USR_TITLE" ] && MKPAGE_TITLE="$USR_TITLE"
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
echo "$TEMPLATE_DATA" > "$MKPAGE_OUTFILE"
nb_msg "$MKPAGE_OUTFILE"
# load makepage plugins, but with reusable functionality
for mkpage_plugin in "$PLUGINS_DIR"/makepage/*.sh; do
	[ -f "$mkpage_plugin" ] && . "$mkpage_plugin"
done
MKPAGE_CONTENT=; MKPAGE_FORMAT=; MKPAGE_TITLE=; NB_MetaTitle=; NB_EntryTitle=
}

# create weblog page from metafiles
weblog_page(){
BLOGPAGE_SRCFILE="$1"
BLOGPAGE_TEMPLATE="$2"
BLOGPAGE_OUTFILE="$3"
[ ! -z "$USR_TEMPLATE" ] && BLOGPAGE_TEMPLATE="$USR_TEMPLATE"
if [ -f "$BLOGPAGE_SRCFILE" ]; then
	write_tag "$USR_METATAG" "$USR_TAGTEXT" "$BLOGPAGE_SRCFILE"
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
	nb_msg "'$EDITDRAFT_FILE' - $nbdraft_asknew [Y/n]"
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
	check_metatags "TITLE: BODY: $METADATA_CLOSETAG" "$EDITDRAFT_FILE"
	# modify date (DATE metadata)
	meta_timestamp && write_metadata DATE "$NB_MetaDate" "$EDITDRAFT_FILE"
fi
}

preview_weblog(){
[ -z "$BLOG_PREVIEW_CMD" ] && die "$preview_nocmd"
if [ "$BLOG_INTERACTIVE" = 1 ]; then
	nb_msg "$preview_asknow [y/N]"
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
	nb_msg "$publish_asknow [y/N]"
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

