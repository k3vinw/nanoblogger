# NanoBlogger Plugin that creates yearly archive indexes

# concatenate modification variables
YEARIMOD_VAR="$New_EntryFile$Edit_EntryFile$Delete_EntryFile$Move_EntryFile$USR_TITLE"
YEARIMOD_QUERY=`echo "$USR_QUERY" |grep "^$yearn"`

# check for weblog modifications
if [ ! -z "$YEARIMOD_VAR" ] || [ ! -z "$YEARIMOD_QUERY" ] || [ "$USR_QUERY" = all ]; then
	# tool to lookup year's id from "all" query type
	lookup_yearid(){
	echo "$2" |cut -c1-4 |sort $SORT_ARGS |grep -n "$1" |cut -d":" -f 1 |grep '^[0-9].*$'
	}
	# set previous and next links for given year
	set_yearnavlinks(){
	yearnavlinks_var=`echo "$1" |sed -e '/\// s//\-/g'`
	year_id=
	[ ! -z "$yearnavlinks_var" ] &&
		year_id=`lookup_yearid "$yearnavlinks_var" "$MASTER_DB_RESULTS"`
	if [ ! -z "$year_id" ] && [ $year_id -gt 0 ]; then
		prev_yearid=`expr $year_id + 1`
		next_yearid=`expr $year_id - 1`
		prev_year=; NB_PrevArchiveYearLink=
		[ $prev_yearid -gt 0 ] &&
			prev_year=`echo "$MASTER_DB_RESULTS" |cut -c1-4 |sort $SORT_ARGS |sed ''$prev_yearid'!d'`
		if [ ! -z "$prev_year" ]; then
			prev_year_dir=`echo $prev_year |sed -e '/[-]/ s//\//g'`
			prev_year_file="$prev_year_dir/$NB_INDEXFILE"
			NB_PrevArchiveYearLink="$prev_year_dir/$NB_INDEX"
		fi
		next_year=; NB_NextArchiveYearLink=
		[ $next_yearid -gt 0 ] &&
			next_year=`echo "$MASTER_DB_RESULTS" |cut -c1-4 |sort $SORT_ARGS |sed ''$next_yearid'!d'`
		if [ ! -z "$next_year" ]; then
			next_year_dir=`echo $next_year |sed -e '/[-]/ s//\//g'`
			next_year_file="$next_year_dir/$NB_INDEXFILE"
			NB_NextArchiveYearLink="$next_year_dir/$NB_INDEX"
		fi
	fi
	}

	nb_msg "$plugins_action yearly archive index page for $yearn ..."
	# make NB_ArchiveEntryLinks placeholder
	set_baseurl "../../"

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

	loop_archive "$DB_RESULTS" months make_monthlink |sort $SORT_ARGS > "$SCRATCH_FILE.$yearn-month_links.$NB_FILETYPE"
	NB_ArchiveMonthLinks=$(< "$SCRATCH_FILE.$yearn-month_links.$NB_FILETYPE")
	set_yearnavlinks "$yearn"

	# make NB_ArchiveLinks placeholder
	mkdir -p `dirname "$BLOG_DIR/$PARTS_DIR/$yearn/archive_links.$NB_FILETYPE"`
	cat > "$BLOG_DIR"/"$PARTS_DIR"/"$yearn"/archive_links.$NB_FILETYPE <<-EOF
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

	NB_ArchiveLinks=$(< "$BLOG_DIR/$PARTS_DIR/$yearn/archive_links.$NB_FILETYPE")
	# build master archive index
	MKPAGE_OUTFILE="$BLOG_DIR/$ARCHIVES_DIR/$yearn/$NB_INDEXFILE"
	# set title for makepage template
	MKPAGE_TITLE="$yearn Archives"
	MKPAGE_CONTENT="$NB_ArchiveLinks"
	make_page "$BLOG_DIR/$PARTS_DIR/$yearn/archive_links.$NB_FILETYPE" "$NB_TEMPLATE_DIR/$YEAR_TEMPLATE" "$MKPAGE_OUTFILE"
fi
