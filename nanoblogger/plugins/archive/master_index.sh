# NanoBlogger Plugin that creates a master archive index

ARCHIVE_TEMPLATE="$BLOG_DIR/$TEMPLATE_DIR/archive.htm"
ARCHIVELINKS_TEMPLATE="archive_links.htm"

# centralize modification variables
MOD_VAR="$New_EntryFile$Edit_EntryFile$UPDATE_LIST$DEL_LIST"

# check for blog modifications
if [ ! -z "$MOD_VAR" ] || [ "$blog_update" = "all" ]; then
	nb_msg "generating master archive index ..."
	# make NB_Entry_Links placeholder for all entry links
	> "$BLOG_DIR"/"$PARTS_DIR"/entry_links.htm; > "$BLOG_DIR"/entry_links.tmp
	query_db all
	ENTRY_LIST="$DB_RESULTS"
	for entry in $ENTRY_LIST; do
		month=`echo "$entry" |cut -c1-7`
		read_entry "$BLOG_DIR"/"$ARCHIVES"/"$entry"; load_template "$BLOG_DIR"/"$TEMPLATE_DIR"/"$ENTRYLINKS_TEMPLATE"
		make_placeholder "$ENTRYLINKS_TEMPLATE" entry_links.tmp entry_links.htm
	done; month=
	NB_Entry_Links="$PLACEHOLDER"
	rm -f "$BLOG_DIR"/entry_links.tmp
	# make NB_Month_Links placeholder for all date links
	[ -z "$NB_Month_Links" ] && cycle_months_for make_monthlylink; rm -f "$BLOG_DIR"/month_links.tmp; PLACEHOLDER=
	make_placeholder "$ARCHIVELINKS_TEMPLATE" archive_links.tmp archive_links.htm; NB_Archive_Links="$PLACEHOLDER"
	rm -f "$BLOG_DIR"/archive_links.tmp; PLACEHOLDER=
	# build master archive index
	MKPAGE_OUTFILE="$BLOG_DIR/archives.$NB_FILETYPE"
	NB_Entries=`cat "$BLOG_DIR"/"$PARTS_DIR"/archive_links.htm`
	load_template "$ARCHIVE_TEMPLATE"
	echo "$BLOG_HTML" > "$MKPAGE_OUTFILE"
	nb_msg "$MKPAGE_OUTFILE"
        load_plugins plugins/postformat
fi
