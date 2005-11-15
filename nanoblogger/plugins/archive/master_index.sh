# NanoBlogger Plugin that creates a master archive index

# concatenate modification variables
MOD_VAR="$New_EntryFile$Edit_EntryFile$Delete_EntryFile$Move_EntryFile$USR_TITLE"

# check for weblog modifications
if [ ! -z "$MOD_VAR" ] || [ "$USR_QUERY" = all ]; then
	nb_msg "$plugins_action archive index page ..."
	# make NB_ArchiveEntryLinks placeholder
	query_db all
	set_baseurl "../"
	ARCHENTRY_LIST="$DB_RESULTS"
	NB_ArchiveEntryLinks=$(
	for entry in $ARCHENTRY_LIST; do
		read_metadata TITLE "$NB_DATA_DIR/$entry"
		NB_ArchiveEntryTitle="$METADATA"
		[ -z "$NB_ArchiveEntryTitle" ] && NB_ArchiveEntryTitle=Untitled
		NB_EntryID=`set_entryid $entry`
		set_entrylink "$entry"
		set_monthlink "$month"
		# load category links plugin
		[ -f "$PLUGINS_DIR"/entry/category_links.sh ] &&
			. "$PLUGINS_DIR"/entry/category_links.sh
		cat <<-EOF
			<a href="${ARCHIVES_PATH}$NB_ArchiveMonthLink">$month</a>
			- <a href="${ARCHIVES_PATH}$NB_EntryPermalink">$NB_ArchiveEntryTitle</a>
			$([ ! -z "$NB_EntryCategories" ] && echo "- $NB_EntryCategories" |sed -e '{$ s/\,$//; }')<br />
		EOF
	done; month=)

	# create links for categories
	build_catlinks(){
	for cat_link in $db_categories; do
		if [ -f "$NB_DATA_DIR/$cat_link" ]; then
			set_catlink "$cat_link"
			cat_index="$category_link"
			cat_total=`query_db "$db_query" "$cat_link"; echo "$DB_RESULTS" |grep -c "[\.]$NB_DATATYPE"`
			NB_ArchiveCategoryTitle=`sed 1q "$NB_DATA_DIR/$cat_link"`
			# following needs to fit on single line
			cat <<-EOF
<!-- $NB_ArchiveCategoryTitle --><a href="${ARCHIVES_PATH}$cat_index">$NB_ArchiveCategoryTitle</a> ($cat_total) <br />
			EOF
		fi
	done
	}

	build_catlinks |$CATLINKS_FILTERCMD |sed -e 's/<!-- .* -->//' > "$SCRATCH_FILE.category_links.$NB_FILETYPE"
	NB_ArchiveCategoryLinks=$(< "$SCRATCH_FILE.category_links.$NB_FILETYPE")

	# create links for monthly archives
	[ -z "$CAL_CMD" ] && CAL_CMD="cal"
	$CAL_CMD > "$SCRATCH_FILE".cal_test 2>&1 && CAL_VAR="1"
		
	make_monthlink(){
	if [ "$CAL_VAR" = "1" ]; then
		[ ! -z "$DATE_LOCALE" ] && CALENDAR=`LC_ALL="$DATE_LOCALE" $CAL_CMD $CAL_ARGS $monthn $yearn`
		[ -z "$DATE_LOCALE" ] && CALENDAR=`$CAL_CMD $CAL_ARGS $monthn $yearn`
		NB_ArchiveMonthTitle=`echo "$CALENDAR" |sed -e '/^[ ]*/ s///g; 1q'`
	else
		NB_ArchiveMonthTitle="$month"
	fi
	month_total=`echo "$DB_RESULTS" |grep -c "[\.]$NB_DATATYPE"`
	set_monthlink "$month"
	# following needs to fit on single line
	cat <<-EOF
		<a href="${ARCHIVES_PATH}$NB_ArchiveMonthLink">$NB_ArchiveMonthTitle</a> ($month_total)<br />
	EOF
	}

	query_db all
	loop_archive "$DB_RESULTS" months make_monthlink |sort $SORT_ARGS > "$SCRATCH_FILE.month_links.$NB_FILETYPE"
	NB_ArchiveMonthLinks=$(< "$SCRATCH_FILE.month_links.$NB_FILETYPE")

	cat_total=`echo "$db_categories" |grep -c "[\.]$NB_DBTYPE"`
	if [ "$cat_total" -gt 0 ]; then
		# make NB_CategoryLinks placeholder
		NB_BrowseCatLinks=$(
		cat <<-EOF
			<a id="category"></a>
			<b>Browse by category</b>
			<div>
				$NB_ArchiveCategoryLinks
			</div>
			<br />
		EOF)
	fi

	# make NB_ArchiveLinks placeholder
	cat > "$BLOG_DIR"/"$PARTS_DIR"/archive_links.$NB_FILETYPE <<-EOF
		$NB_BrowseCatLinks
		<a id="date"></a>
		<b>Browse by date</b>
		<div>
			$NB_ArchiveMonthLinks
		</div>
		<br />
		<a id="entry"></a>
		<b>Browse by entry</b>
		<div>
			$NB_ArchiveEntryLinks
		</div>
	EOF

	NB_ArchiveLinks=$(< "$BLOG_DIR/$PARTS_DIR/archive_links.$NB_FILETYPE")
	# build master archive index
	MKPAGE_OUTFILE="$BLOG_DIR/$ARCHIVES_DIR/$NB_INDEXFILE"
	# set title for makepage template
	MKPAGE_TITLE=Archives
	MKPAGE_CONTENT="$NB_ArchiveLinks"
	make_page "$BLOG_DIR/$PARTS_DIR"/archive_links.$NB_FILETYPE "$NB_TEMPLATE_DIR/$MAKEPAGE_TEMPLATE" "$MKPAGE_OUTFILE"
fi

