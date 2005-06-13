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
: ${CATLINKS_FILTER_CMD:=sort}

nb_msg "generating weblog links ..."
# create main set of links
load_template "$NB_TEMPLATE_DIR/$MAINLINKS_TEMPLATE"
NB_MainLinks="$TEMPLATE_DATA"

query_db
set_baseurl "./"

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

build_catlinks |$CATLINKS_FILTER_CMD |sed -e 's/<!-- .* -->//' > "$BLOG_DIR/$PARTS_DIR/category_links.$NB_FILETYPE"
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

query_db "$QUERY_MODE"
loop_archive "$DB_RESULTS" months make_monthlink |sort $SORT_ARGS > "$BLOG_DIR/$PARTS_DIR/month_links.$NB_FILETYPE"
NB_MonthLinks=$(< "$BLOG_DIR/$PARTS_DIR/month_links.$NB_FILETYPE")

