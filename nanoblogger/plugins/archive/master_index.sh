# NanoBlogger Plugin that creates a master archive index

# centralize modification variables
MOD_VAR="$New_EntryFile$Edit_EntryFile$UPDATE_LIST$DEL_LIST"
OLD_BLOG_CSS="$BLOG_CSS"
BLOG_CSS="../$BLOG_CSS"
OLD_BLOG_URL_MAIN="$BLOG_URL_MAIN"
BLOG_URL_MAIN="../$BLOG_URL_MAIN"

# check for weblog modifications
if [ ! -z "$MOD_VAR" ] || [ "$weblog_update" = "all" ]; then
	nb_msg "generating master archive index ..."
	# make NB_Entry_Links placeholder
	query_db all
	ENTRY_LIST="$DB_RESULTS"
	NB_Entry_Links=$(
	for entry in $ENTRY_LIST; do
		month=`echo "$entry" |cut -c1-7`
		read_entry "$NB_DATA_DIR/$entry"
		[ -z "$NB_EntryTitle" ] && NB_EntryTitle="Untitled"
		cat <<-EOF
			<a href="$month.$NB_FILETYPE">$month</a> - <a href="$NB_EntryPermalink">$NB_EntryTitle</a>
			`[ ! -z "$NB_EntryCategories" ] && echo "- $NB_EntryCategories" |sed -e '{$ s/\,$//; }'`<br />
		EOF
	done; month=)

	cat_total=`echo "$db_categories" |grep -c "[\.]db"`
	if [ "$cat_total" -gt "0" ]; then
		# make NB_Category_Links placeholder
		NB_Browse_CatLinks=$(
		cat <<-EOF
			<a id="category" name="category"></a>
			<b>Browse by category</b>
			<div>
			$NB_Category_Links
			</div>
			<br />
		EOF)
	fi

	# make NB_Archive_Links placeholder
	cat > "$BLOG_DIR"/"$PARTS_DIR"/archive_links.$NB_FILETYPE <<-EOF
		$NB_Browse_CatLinks
		<a id="date" name="date"></a>
		<b>Browse by date</b>
		<div>
		$NB_Month_Links
		</div>
		<br />
		<a id="entry" name="entry"></a>
		<b>Browse by entry</b>
		<div>
		$NB_Entry_Links
		</div>
	EOF
	NB_Archive_Links=`cat "$BLOG_DIR/$PARTS_DIR"/archive_links.$NB_FILETYPE`

	# build master archive index
	MKPAGE_OUTFILE="$BLOG_DIR/$ARCHIVES_DIR/index.$NB_FILETYPE"
	# set title for makepage template
	NB_EntryTitle="Archives"
	NB_Entries="$NB_Archive_Links"
	nb_msg "$MKPAGE_OUTFILE"
	load_template "$NB_TEMPLATE_DIR/$MAKEPAGE_TEMPLATE"
	echo "$BLOG_HTML" > "$MKPAGE_OUTFILE"
        load_plugins plugins/postformat
fi

BLOG_CSS="$OLD_BLOG_CSS"
BLOG_URL_MAIN="$OLD_BLOG_URL_MAIN"

