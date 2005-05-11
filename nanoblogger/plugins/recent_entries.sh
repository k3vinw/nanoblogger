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
set_baseurl "./"
for entry in $DB_RESULTS ; do
	read_metadata TITLE "$NB_DATA_DIR/$entry"; NB_EntryTitle="$NB_Metadata"
	NB_EntryID=`set_entryid $entry`
	title_link="$NB_EntryTitle"
	[ -z "$title_link" ] && title_link="Untitled"
	set_entrylink "$entry"
	echo '<a href="'\${ARCHIVES_PATH}$NB_EntryPermalink'">'$title_link'</a><br />'
done
}

get_entries new > "$PLUGIN_OUTFILE1"
load_template "$PLUGIN_OUTFILE1"
NB_Recent_Entries="$BLOG_HTML"

get_entries old > "$PLUGIN_OUTFILE2"
load_template "$PLUGIN_OUTFILE2"
NB_Older_Entries="$BLOG_HTML"

