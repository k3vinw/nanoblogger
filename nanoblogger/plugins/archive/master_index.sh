# NanoBlogger Plugin that creates a master archive index
# in conjunction with the yearly archive indexes created
# by archive/year/year_index.sh plugin

# concatenate modification variables
MASTERIMOD_VAR="$New_EntryFile$Edit_EntryFile$Delete_EntryFile$Move_EntryFile$USR_TITLE"
MASTERIMOD_QUERY=`echo "$USR_QUERY" |grep "^[0-9].*"`

# check for weblog modifications
if [ ! -z "$MASTERIMOD_VAR" ] || [ ! -z "$MASTERIMOD_QUERY" ] || [ "$USR_QUERY" = all ]; then
	nb_msg "$plugins_action archive index page ..."
	# help ease transition from 3.2.x or earlier
	YEAR_TEMPLATECOPY="$NB_BASE_DIR/default/templates/$YEAR_TEMPLATE"
	if [ ! -f "$NB_TEMPLATE_DIR/$YEAR_TEMPLATE" ] ; then
		# YEAR_TEMPLATE doesn't exist, get it from default
		cp "$YEAR_TEMPLATECOPY" "$NB_TEMPLATE_DIR/$YEAR_TEMPLATE" ||
			die "$nb_plugin: failed to copy '$YEAR_TEMPLATECOPY!' repair nanoblogger! goodbye."
	fi
	# make NB_ArchiveEntryLinks placeholder
	query_db
	set_baseurl "../"

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

	make_yearlink(){
	NB_ArchiveYearTitle="$masterindex_yearn"
	year_total=`echo "$DB_RESULTS" |grep -c "^$masterindex_yearn-[0-9]*.*[\.]$NB_DATATYPE"`
	# following needs to fit on single line
	cat <<-EOF
		<a href="${ARCHIVES_PATH}$masterindex_yearn/$NB_INDEX">$NB_ArchiveYearTitle</a> ($year_total)<br />
	EOF
	}

	query_db all
	MASTERINDEXYEAR_LIST=`echo "$DB_RESULTS" |cut -c1-4 |sort -u`
	for masterindex_yearn in $MASTERINDEXYEAR_LIST; do
		make_yearlink
	done |sort $SORT_ARGS > "$SCRATCH_FILE.year_links.$NB_FILETYPE"
	NB_ArchiveYearLinks=$(< "$SCRATCH_FILE.year_links.$NB_FILETYPE")

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
			$NB_ArchiveYearLinks
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

