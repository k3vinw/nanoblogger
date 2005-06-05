# NanoBlogger Weblog Status Plugin
# generate some misc. statistics about the weblog
#
# sample code for templates - based on default stylesheet
#
# <div class="sidetitle">
# Weblog Status
# </div>
# <div class="side">
# $NB_Blog_Status
# </div>

OUTPUT_FILE="$BLOG_DIR/$PARTS_DIR/weblog_status.$NB_FILETYPE"
TEMPLATE_FILE="$NB_TEMPLATE_DIR/weblog_status.htm"

nb_msg "generating weblog status ..."
if [ ! -f "$TEMPLATE_FILE" ] ; then
	# TEMPLATE_FILE doesn't exist, get it from default
	cp "${BASE_DIR}/default/templates/weblog_status.htm" "$TEMPLATE_FILE" || die "$nb_plugin: failed to copy '${BASE_DIR}/default/templates/weblog_status.htm!' repair nanoblogger! goodbye."
fi

[ -r "$TEMPLATE_FILE" ] || \
    die "`basename $0`: $TEMPLATE_FILE doens't exist! goodbye."

query_db all
TOTAL_CATEGORIES=`echo "$db_categories" |grep -c "."`
TOTAL_ENTRIES=`echo "$DB_RESULTS" |grep -c "."`
LAST_ENTRY=`echo "$DB_RESULTS" |sed 1q`
[ ! -z "$LAST_ENTRY" ] &&
	read_metadata DATE "$NB_DATA_DIR/$LAST_ENTRY"; NB_EntryDate="$META_DATA"
LAST_ENTRY_TIME="$NB_EntryDate"
LAST_UPDATED=`filter_dateformat "$DATE_FORMAT"`

NB_BlogStatus=$(< "$TEMPLATE_FILE")

cat > "$OUTPUT_FILE" <<-EOF
	cat <<-TMPL

		$NB_BlogStatus

	TMPL
EOF

NB_BlogStatus=$(. "$OUTPUT_FILE")

cat > "$OUTPUT_FILE" <<-EOF
	$NB_BlogStatus
EOF
