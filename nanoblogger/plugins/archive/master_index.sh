# NanoBlogger Plugin that creates a master archive index

# centralize modification variables
MOD_VAR="$New_EntryFile$Edit_EntryFile$UPDATE_LIST$DEL_LIST"

# check for blog modifications
if [ ! -z "$MOD_VAR" ] || [ "$blog_update" = "all" ]; then
	nb_msg "generating master archive index ..."
	# make NB_Entry_Links placeholder
	> "$BLOG_DIR"/entry_links.tmp
	query_db all
	ENTRY_LIST="$DB_RESULTS"
	for entry in $ENTRY_LIST; do
		month=`echo "$entry" |cut -c1-7`
		read_entry "$NB_DATA_DIR/$entry"
		cat >> "$BLOG_DIR"/entry_links.tmp <<-EOF
			<a href="$BLOG_URL/$MONTHLY_DIR/$month.$NB_FILETYPE">$month</a> - <a href="$NB_EntryPermalink">$NB_EntryTitle</a>
			`[ ! -z "$NB_EntryCategories" ] && echo "- $NB_EntryCategories" |sed -e '{$ s/\,$//; }'`<br />
		EOF
	done; month=
	NB_Entry_Links=`cat "$BLOG_DIR"/entry_links.tmp`
	rm -f "$BLOG_DIR"/entry_links.tmp

	# make NB_Archive_Links placeholder
	cat > "$BLOG_DIR"/"$PARTS_DIR"/archive_links.htm <<-EOF
		<a name="category"></a>
		<b>Browse by category</b>
		<div>
		$NB_Category_Links
		</div>
		<br />
		<a name="date"></a>
		<b>Browse by date</b>
		<div>
		$NB_Month_Links
		</div>
		<br />
		<a name="entry"></a>
		<b>Browse by entry</b>
		<div>
		$NB_Entry_Links
		</div>
	EOF
	NB_Archive_Links=`cat "$BLOG_DIR/$PARTS_DIR"/archive_links.htm`

	# build master archive index
	MKPAGE_OUTFILE="$BLOG_DIR/archives.$NB_FILETYPE"
	# set title for makepage template
	NB_EntryTitle="Archives"
	NB_Entries="$NB_Archive_Links"
	nb_msg "$MKPAGE_OUTFILE"
	load_template "$NB_TEMPLATE_DIR/$MAKEPAGE_TEMPLATE"
	echo "$BLOG_HTML" > "$MKPAGE_OUTFILE"
        load_plugins plugins/postformat
fi
