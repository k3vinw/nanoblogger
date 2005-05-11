# NanoBlogger Plugin that creates a master archive index

# concatenate modification variables
MOD_VAR="$New_EntryFile$Edit_EntryFile$UPDATE_LIST$DEL_LIST"

# check for weblog modifications
if [ ! -z "$MOD_VAR" ] || [ "$USR_QUERY" = all ]; then
	nb_msg "generating archive index page ..."
	# make NB_Entry_Links placeholder
	query_db all
	set_baseurl "../"
	ENTRY_LIST="$DB_RESULTS"
	NB_ArchiveEntry_Links=$(
	for entry in $ENTRY_LIST; do
		read_metadata TITLE "$NB_DATA_DIR/$entry"; NB_EntryTitle="$NB_Metadata"
		[ -z "$NB_EntryTitle" ] && NB_EntryTitle=Untitled
		NB_EntryID=`set_entryid $entry`
		set_entrylink "$entry"
		set_monthlink "$month"
		# load category links plugin
		[ -f "$PLUGINS_DIR"/entry/category_links.sh ] &&
			. "$PLUGINS_DIR"/entry/category_links.sh
		cat <<-EOF
			<a href="\${ARCHIVES_PATH}$NB_ArchiveMonthLink">$month</a> - <a href="\${ARCHIVES_PATH}$NB_EntryPermalink">$NB_EntryTitle</a>
			$([ ! -z "$NB_EntryCategories" ] && echo "- $NB_EntryCategories" |sed -e '{$ s/\,$//; }')<br />
		EOF
	done; month=)

	# create links for categories
	build_catlinks(){
	for cat_link in $db_categories; do
		if [ -f "$NB_DATA_DIR/$cat_link" ]; then
			cat_index=`chg_suffix "$cat_link"`; cat_feed=`chg_suffix "$cat_link" "$NB_SYND_FILETYPE"`
			cat_total=`query_db "$db_query" "$cat_link"; echo "$DB_RESULTS" |grep -c "[\.]$NB_DATATYPE"`
			NB_CategoryTitle=`sed 1q "$NB_DATA_DIR/$cat_link"`
			cat <<-EOF
				<!-- $NB_CategoryTitle --><a href="\${ARCHIVES_PATH}$cat_index">$NB_CategoryTitle</a> ($cat_total) <br />
			EOF
		fi
	done
	}

	build_catlinks |$CATLINKS_FILTER_CMD |sed -e 's/<!-- .* -->//' > "$SCRATCH_FILE.category_links.$NB_FILETYPE"
	load_template "$SCRATCH_FILE.category_links.$NB_FILETYPE"
	NB_ArchiveCategory_Links="$BLOG_HTML"

	# create links for monthly archives
	[ -z "$CAL_CMD" ] && CAL_CMD="cal"
	$CAL_CMD > "$SCRATCH_FILE".cal_test 2>&1 && CAL_VAR="1"
		
	make_monthlylink(){
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
		<a href="\${ARCHIVES_PATH}$NB_ArchiveMonthLink">$Month_Title</a> ($month_total)<br />
	EOF
	}

	cycle_months_for make_monthlylink |sort $SORT_ARGS > "$SCRATCH_FILE.month_links.$NB_FILETYPE"
	load_template "$SCRATCH_FILE.month_links.$NB_FILETYPE"
	NB_ArchiveMonth_Links="$BLOG_HTML"

	cat_total=`echo "$db_categories" |grep -c "[\.]$NB_DBTYPE"`
	if [ "$cat_total" -gt 0 ]; then
		# make NB_Category_Links placeholder
		NB_Browse_CatLinks=$(
		cat <<-EOF
			<a id="category"></a>
			<b>Browse by category</b>
			<div>
			$NB_ArchiveCategory_Links
			</div>
			<br />
		EOF)
	fi

	# make NB_Archive_Links placeholder
	cat > "$BLOG_DIR"/"$PARTS_DIR"/archive_links.$NB_FILETYPE <<-EOF
		$NB_Browse_CatLinks
		<a id="date"></a>
		<b>Browse by date</b>
		<div>
		$NB_ArchiveMonth_Links
		</div>
		<br />
		<a id="entry"></a>
		<b>Browse by entry</b>
		<div>
		$NB_ArchiveEntry_Links
		</div>
	EOF

	load_template "$BLOG_DIR/$PARTS_DIR/archive_links.$NB_FILETYPE"
	NB_Archive_Links="$BLOG_HTML"
	echo "$NB_Archive_Links" > "$BLOG_DIR/$PARTS_DIR/archive_links.$NB_FILETYPE"
	# build master archive index
	MKPAGE_OUTFILE="$BLOG_DIR/$ARCHIVES_DIR/index.$NB_FILETYPE"
	# set title for makepage template
	NB_EntryTitle=Archives
	MKPAGE_CONTENT="$NB_Archive_Links"
	make_page "$BLOG_DIR/$PARTS_DIR"/archive_links.$NB_FILETYPE "$NB_TEMPLATE_DIR/$MAKEPAGE_TEMPLATE" "$MKPAGE_OUTFILE"
fi

