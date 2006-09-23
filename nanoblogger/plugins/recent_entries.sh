# NanoBlogger Recent Entries List Plugin
# List Recent entries
#
# sample code for templates, based off the default stylesheet
#
# <div class="sidetitle">
# Recent Entries/Older Entries
# </div>
# <div class="side">
# $NB_Recent_Entries/$NB_Older_Entries
# </div>

# set how many entries to list
: ${RECENTLIST_ENTRIES:=10}
: ${RECENTLIST_OFFSET:=1}

PLUGIN_OUTFILE1="$BLOG_DIR/$PARTS_DIR/recent_entries.$NB_FILETYPE"
PLUGIN_OUTFILE2="$BLOG_DIR/$PARTS_DIR/older_entries.$NB_FILETYPE"

# always sort in reverse chronological order so recent entries
# stay near the top of the list
if [ "$CHRON_ORDER" != 1 ]; then
	RECENTLIST_SORTARGS="-ru"
else
	RECENTLIST_SORTARGS=
fi

nb_msg "$plugins_action recent entries links ..."
set_baseurl "./"

get_entries(){
RECENTLIST_MODE="$1"
[ "$RECENTLIST_MODE" = "new" ] && query_db max nocat limit "$RECENTLIST_ENTRIES" "" "$RECENTLIST_SORTARGS"
if [ "$RECENTLIST_MODE" = "old" ]; then
	XRECENTLIST_OFFSET="$RECENTLIST_ENTRIES"
	XRECENTLIST_ENTRIES=`expr $RECENTLIST_ENTRIES + $RECENTLIST_ENTRIES`
	query_db max nocat limit "$XRECENTLIST_ENTRIES" "$XRECENTLIST_OFFSET" "$RECENTLIST_SORTARGS"
fi
for entry in ${DB_RESULTS[*]}; do
	read_metadata TITLE "$NB_DATA_DIR/$entry"
	link_title="$METADATA"
	NB_EntryID=`set_entryid $entry`
	[ -z "$link_title" ] && link_title="$notitle"
	set_entrylink "$entry"
	# Nijel: support for named permalinks
	permalink_file="$entry_dir/$entry_linkname/$NB_INDEXFILE"
	NB_EntryPermalink="$entry_dir/$entry_linkname/$NB_INDEX"
	echo '<a href="'${ARCHIVES_PATH}$NB_EntryPermalink'">'$link_title'</a><br />'
done
}

get_entries new > "$PLUGIN_OUTFILE1"
NB_RecentEntries=$(< "$PLUGIN_OUTFILE1")

get_entries old > "$PLUGIN_OUTFILE2"
NB_OlderEntries=$(< "$PLUGIN_OUTFILE2")

