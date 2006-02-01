# NanoBlogger Recent Entries Plugin
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
: ${LIST_N:=10}
: ${LIST_OFFSET:=1}

PLUGIN_OUTFILE1="$BLOG_DIR/$PARTS_DIR/recent_entries.$NB_FILETYPE"
PLUGIN_OUTFILE2="$BLOG_DIR/$PARTS_DIR/older_entries.$NB_FILETYPE"

# flip order for recent and old list for logical reasons
[ "$CHRON_ORDER" != 1 ] && re_order="-ru"

nb_msg "$plugins_action recent entries links ..."
set_baseurl "./"

get_entries(){
LIST_MODE="$1"
[ "$LIST_MODE" = "new" ] && query_db max nocat limit "$LIST_N" "" "$re_order"
if [ "$LIST_MODE" = "old" ]; then
	XLIST_OFFSET="$LIST_N"
	XLIST_N=`expr $LIST_N + $LIST_N`
	query_db max nocat limit "$XLIST_N" "$XLIST_OFFSET" "$re_order"
fi
for entry in ${DB_RESULTS[*]}; do
	read_metadata TITLE "$NB_DATA_DIR/$entry"
	link_title="$METADATA"
	NB_EntryID=`set_entryid $entry`
	[ -z "$link_title" ] && link_title="$notitle"
	set_entrylink "$entry"
	echo '<a href="'${ARCHIVES_PATH}$NB_EntryPermalink'">'$link_title'</a><br />'
done
}

get_entries new > "$PLUGIN_OUTFILE1"
NB_RecentEntries=$(< "$PLUGIN_OUTFILE1")

get_entries old > "$PLUGIN_OUTFILE2"
NB_OlderEntries=$(< "$PLUGIN_OUTFILE2")

