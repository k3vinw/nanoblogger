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

nb_msg "generating recent entries links ..."

get_entries(){
LIST_MODE="$1"
[ "$LIST_MODE" = "new" ] && query_db max nocat "$LIST_N"
if [ "$LIST_MODE" = "old" ]; then
	LIST_OFFSET="$LIST_N"
	LIST_N=`expr $LIST_N + $LIST_N`
	query_db max nocat "$LIST_N" "$LIST_OFFSET"
fi
for entry in $DB_RESULTS ; do
	read_metadata TITLE "$NB_DATA_DIR/$entry"; NB_EntryTitle="$NB_Metadata"
	NB_EntryID="$x_id$entry"
	title_link="$NB_EntryTitle"
	[ -z "$title_link" ] && title_link="Untitled"
	if [ "$ENTRY_ARCHIVES" = "1" ] ; then
		permalink_entry=`chg_suffix $entry`
		permalink="\${ARCHIVES_PATH}$permalink_entry"
	else
		month_link=`echo "$entry" |cut -c1-7`
		permalink="\${ARCHIVES_PATH}$month_link.$NB_FILETYPE#$NB_EntryID"
	fi
	echo '<a href="'$permalink'">'$title_link'</a><br />'
done
}

get_entries new > "$PLUGIN_OUTFILE1"
NB_Recent_Entries=$(< "$PLUGIN_OUTFILE1")
load_template "$PLUGIN_OUTFILE1"
echo "$BLOG_HTML" > "$PLUGIN_OUTFILE1"

get_entries old > "$PLUGIN_OUTFILE2"
NB_Older_Entries=$(< "$PLUGIN_OUTFILE2")
load_template "$PLUGIN_OUTFILE2"
echo "$BLOG_HTML" > "$PLUGIN_OUTFILE2"

