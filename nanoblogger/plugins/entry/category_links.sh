# NanoBlogger Category Links Plugin
# Entry Plugin to find related categories and generate links for them

if [ "$CATEGORY_LINKS" = 1 ]; then
	# Command to help filter order of categories
	: ${CATLINKS_FILTERCMD:=sort}
	>"$SCRATCH_FILE".category_links
	entry_catids=(`sed -e '/'$entry'[\>]/!d; /[\>\,]/ s// /g' "$NB_DATA_DIR/master.$NB_DBTYPE" |cut -d" " -f 2-`)
	# following lines must include category data to work!
	#catlink_entryid=`lookup_entryid "$entry" "${MASTER_DB_RESULTS[*]}"`
	#entry_catids=(`echo "${MASTER_DB_RESULTS[$catlink_entryid]//*\>}" |sed -e '/'$entry'/d; /[\,]/ s// /g'`)
	for entry_catnum in ${entry_catids[@]}; do
		cat_title=`sed 1q "$NB_DATA_DIR"/cat_"$entry_catnum.$NB_DBTYPE"`
		set_catlink cat_"$entry_catnum.$NB_DBTYPE"
		cat_index="$category_link"
		# following must fit on single line
		$CATLINKS_FILTERCMD  >> "$SCRATCH_FILE".category_links <<-EOF
			<!-- $cat_title --><a href="${ARCHIVES_PATH}$cat_index">$cat_title</a>,
		EOF
	done
	NB_EntryCategories=$(< "$SCRATCH_FILE.category_links")
fi
