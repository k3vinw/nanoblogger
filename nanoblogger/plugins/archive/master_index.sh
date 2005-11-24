# NanoBlogger Plugin that creates a master archive index that
# compliments the archive/year/year_index.sh plugin

# concatenate modification variables
MASTERIMOD_VAR="$New_EntryFile$Edit_EntryFile$Delete_EntryFile$Move_EntryFile$USR_TITLE"
MASTERIMOD_QUERY=`echo "$USR_QUERY" |grep "^[0-9].*"`

# check for weblog modifications
if [ ! -z "$MASTERIMOD_VAR" ] || [ ! -z "$MASTERIMOD_QUERY" ] || [ "$USR_QUERY" = all ]; then
	nb_msg "$plugins_action archive index page ..."
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
	NB_ArchiveYearTitle="$masteriyearn"
	year_total=`echo "$DB_RESULTS" |grep -c "^$masteriyearn-[0-9]*.*[\.]$NB_DATATYPE"`
	# following needs to fit on single line
	cat <<-EOF
		<a href="${ARCHIVES_PATH}$masteriyearn/$NB_INDEXFILE">$NB_ArchiveYearTitle</a> ($year_total)<br />
	EOF
	}

	query_db all
	MASTERIYEAR_LIST=`echo "$DB_RESULTS" |cut -c1-4 |sort -u`
	for masteriyearn in $MASTERIYEAR_LIST; do
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

