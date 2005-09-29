# Module for utility functions

# filter custom date format for a new entry
filter_dateformat(){
FILTER_VAR="$1"
# use date's defaults, when no date format is specified
if [ ! -z "$FILTER_VAR" ]; then
	[ ! -z "$DATE_LOCALE" ] && LC_ALL="$DATE_LOCALE" date +"$FILTER_VAR"
	[ -z "$DATE_LOCALE" ] && date +"$FILTER_VAR"
else
	[ ! -z "$DATE_LOCALE" ] && LC_ALL="$DATE_LOCALE" date
	[ -z "$DATE_LOCALE" ] && date
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
		blogdir_sedvar=`echo "$BLOG_DIR" |sed -e 's/\//\\\\\//g'`
		BASE_URL=`echo "$base_dir" |sed -e 's/'$blogdir_sedvar'//g; s/[^ \/]*./..\//g; s/^[\.][\.]\///g'`
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
echo "$x_id$entryid_var" |sed -e '/[\/]/ s//-/g'; }

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

# helps update relative categories
find_categories(){
UPDATE_CATLIST="$1"
	build_catlist(){
	if [ ! -z "$cat_var" ]; then
		[ -z "$CAT_LIST" ] && CAT_LIST="$cat_db"
		[ "$CAT_LIST" != "$OLD_CATLIST" ] && CAT_LIST="$OLD_CATLIST $cat_db"
		OLD_CATLIST="$CAT_LIST"
	fi
	}
# find related categories for a given set of entries
if [ "$USR_QUERY" != all ]; then
	for relative_entry in $UPDATE_CATLIST; do
		query_db "$USR_QUERY"
		for cat_db in $db_categories; do
			cat_var=`grep "$relative_entry" "$NB_DATA_DIR/$cat_db"`
			build_catlist
		done
	done
else
	query_db; CAT_LIST="$db_categories"
fi
[ -z "$CAT_LIST" ] && CAT_LIST="$db_catquery"
CAT_LIST=`for cat_id in $CAT_LIST; do echo "$cat_id"; done |sort -u`
}

