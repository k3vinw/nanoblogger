# Nanoblogger Plugin: Weblog Links

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

# maximum number of years to show for $NB_YearLinks
: ${MAX_YEARLINKS:=12}

# validate MAX_MONTHLINKS (must be greater than 0)
MONTHLINKS_NUMVAR=`echo "$MAX_MONTHLINKS" |grep -c [0-9]`
[ "$MONTHLINKS_NUMVAR" = 0 ] &&
	die "MAX_MONTHLINKS != > 0"

# validate MAX_YEARLINKS (must be greater than 0)
YEARLINKS_NUMVAR=`echo "$MAX_YEARLINKS" |grep -c [0-9]`
[ "$YEARLINKS_NUMVAR" = 0 ] &&
	die "MAX_YEARLINKS != > 0"

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

# get total number of years and tally total months from MAX_YEARLINKS
[ -z "$YEAR_DB_RESULTS" ] && query_db years
total_qyears="$YEAR_DB_RESULTS"
total_nyears=`echo "$total_qyears" |grep -c ""`
NYEARS_RESULTS=`echo "$total_qyears" |sed "$MAX_YEARLINKS"q`

month_tally=0
for query_nyear in $NYEARS_RESULTS; do
	query_db "$query_nyear"
	months_nyear=`echo "$DB_RESULTS" |grep -c "[\.]$NB_DATATYPE"`
	[ "$months_nyear" -gt 0 ] &&
		month_tally=`expr $month_tally + $months_nyear`
done

# get total number of months and tally total entries from MAX_MONTHLINKS
[ -z "$MONTH_DB_RESULTS" ] && query_db months
total_qmonths="$MONTH_DB_RESULTS"
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

# tool to create yearly archive links
make_yearlink(){
NB_YearTitle="$webloglinksyearn"
year_total=`echo "$DB_RESULTS" |grep -c "^$webloglinksyearn-[0-9]*.*[\.]$NB_DATATYPE"`
# following needs to fit on single line
cat <<-EOF
	<a href="${ARCHIVES_PATH}$webloglinksyearn/$NB_INDEXFILE">$NB_YearTitle</a> ($year_total)<br />
EOF
}

# cal command test to retrieve locale month titles
[ -z "$CAL_CMD" ] && CAL_CMD="cal"
$CAL_CMD > "$SCRATCH_FILE".cal_test 2>&1 && CAL_VAR="1"

# tool to create monthly archive links
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

# create yearly archive links
query_db all nocat limit $month_tally 1
WEBLOGLINKSYEAR_LIST=`echo "$DB_RESULTS" |cut -c1-4 |sort -u`
for webloglinksyearn in $WEBLOGLINKSYEAR_LIST; do
	make_yearlink
done |sort $SORT_ARGS > "$BLOG_DIR/$PARTS_DIR/year_links.$NB_FILETYPE"
# yearly archives continued
if [ "$MAX_YEARLINKS" -lt "$total_nyears" ]; then
	cat >> "$BLOG_DIR/$PARTS_DIR/year_links.$NB_FILETYPE" <<-EOF
		<a href="${ARCHIVES_PATH}$NB_INDEX">$NB_NextPage</a>
	EOF
fi
NB_YearLinks=$(< "$BLOG_DIR/$PARTS_DIR/year_links.$NB_FILETYPE")

# create monthly archive links
query_db all nocat limit $entry_tally 1
loop_archive "$DB_RESULTS" months make_monthlink |sort $SORT_ARGS > "$BLOG_DIR/$PARTS_DIR/month_links.$NB_FILETYPE"
# monthly archives continued
if [ "$MAX_MONTHLINKS" -lt "$total_nmonths" ]; then
	cat >> "$BLOG_DIR/$PARTS_DIR/month_links.$NB_FILETYPE" <<-EOF
		<a href="${ARCHIVES_PATH}$NB_INDEX">$NB_NextPage</a>
	EOF
fi
NB_MonthLinks=$(< "$BLOG_DIR/$PARTS_DIR/month_links.$NB_FILETYPE")

