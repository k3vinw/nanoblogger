# Nanoblogger Plugin: Weblog Links
# Last modified: 2005-11-01T00:54:19-05:00

# <div class="sidetitle">
# Links
# </div>
#
# <div class="side">
# $NB_Main_Links
# </div>

# <div class="sidetitle">
# Categories
# </div>
#
# <div class="side">
# $NB_Category_Links
# </div>

# <div class="sidetitle">
# Archives
# </div>
#
# <div class="side">
# $NB_Month_Links
# </div>

# command used to filter order of category links
: ${CATLINKS_FILTERCMD:=sort}

# maximum number of months to show for $NB_MonthLinks
: ${MAX_MONTHLINKS:=12}

# validate MAX_MONTHLINKS (must be greater than 0)
MONTHLINKS_NUMVAR=`echo "$MAX_MONTHLINKS" |grep -c [0-9]`
[ "$MONTHLINKS_NUMVAR" = 0 ] &&
	die "MAX_MONTHLINKS must be set to a valid number!"

set_baseurl "./"
nb_msg "$plugins_action weblog links ..."
# create main set of links
load_template "$NB_TEMPLATE_DIR/$MAINLINKS_TEMPLATE"
NB_MainLinks="$TEMPLATE_DATA"

# create links for categories
build_catlinks(){
for cat_link in $db_categories; do
	if [ -f "$NB_DATA_DIR/$cat_link" ]; then
		#cat_index=`chg_suffix "$cat_link"`
		#cat_feed=`chg_suffix "$cat_link" "$NB_SYND_FILETYPE"`
		set_catlink "$cat_link"
		cat_index="$category_link"
		cat_total=`query_db "$db_query" "$cat_link"; echo "$DB_RESULTS" |grep -c "[\.]$NB_DATATYPE"`
		NB_CategoryTitle=`sed 1q "$NB_DATA_DIR/$cat_link"`
		cat <<-EOF
			<!-- $NB_CategoryTitle --><a href="${ARCHIVES_PATH}$cat_index">$NB_CategoryTitle</a> ($cat_total) <br />
		EOF
	fi
done
}

query_db
# get total number of months and tally total entries from MAX_MONTHLINKS
total_qmonths=`echo "$DB_RESULTS" |grep "[\.]$NB_DATATYPE" |cut -c1-7 |sort -ru`
total_nmonths=`echo "$total_qmonths" |grep -c ""`
NMONTHS_RESULTS=`echo "$total_qmonths" |sed "$MAX_MONTHLINKS"q`

entry_tally=0
for query_nmonth in $NMONTHS_RESULTS; do
	query_db "$query_nmonth"
	entries_nmonth=`echo "$DB_RESULTS" |grep -c "[\.]$NB_DATATYPE"`
	[ "$entries_nmonth" -gt 0 ] &&
		entry_tally=`expr $entry_tally + $entries_nmonth`
done

build_catlinks |$CATLINKS_FILTERCMD |sed -e 's/<!-- .* -->//' > "$BLOG_DIR/$PARTS_DIR/category_links.$NB_FILETYPE"
NB_CategoryLinks=$(< "$BLOG_DIR/$PARTS_DIR/category_links.$NB_FILETYPE")

# create links for monthly archives
[ -z "$CAL_CMD" ] && CAL_CMD="cal"
$CAL_CMD > "$SCRATCH_FILE".cal_test 2>&1 && CAL_VAR="1"
	
make_monthlink(){
if [ "$CAL_VAR" = "1" ]; then
	[ ! -z "$DATE_LOCALE" ] && CALENDAR=`LC_ALL="$DATE_LOCALE" $CAL_CMD $CAL_ARGS $monthn $yearn`
	[ -z "$DATE_LOCALE" ] && CALENDAR=`$CAL_CMD $CAL_ARGS $monthn $yearn`
	Month_Title=`echo "$CALENDAR" |sed -e '/^[ ]*/ s///g; 1q'`
else
	Month_Title="$month"
fi
month_total=`echo "$DB_RESULTS" |grep -c "[\.]$NB_DATATYPE"`
set_monthlink "$month"
cat <<-EOF
	<a href="${ARCHIVES_PATH}$NB_ArchiveMonthLink">$Month_Title</a> ($month_total)<br />
EOF
}

query_db all nocat limit $entry_tally 1
loop_archive "$DB_RESULTS" months make_monthlink |sort $SORT_ARGS > "$BLOG_DIR/$PARTS_DIR/month_links.$NB_FILETYPE"
# monthly archives continued
if [ "$MAX_MONTHLINKS" -lt "$total_nmonths" ]; then
	cat >> "$BLOG_DIR/$PARTS_DIR/month_links.$NB_FILETYPE" <<-EOF
		<a href="${ARCHIVES_PATH}$NB_INDEX">$NB_NextPage</a>
	EOF
fi
NB_MonthLinks=$(< "$BLOG_DIR/$PARTS_DIR/month_links.$NB_FILETYPE")

