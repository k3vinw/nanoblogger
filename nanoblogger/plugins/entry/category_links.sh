# NanoBlogger Category Links Plugin
# Entry Plugin to find related categories and generate links for them

# Command to help filter order of categories
: ${CATLINKS_FILTER_CMD:=sort}
query_db
>"$SCRATCH_FILE".category_links
for entry_catlinks in $db_categories; do
	cat_var=`grep "$entry" "$NB_DATA_DIR"/"$entry_catlinks"`
	if [ ! -z "$cat_var" ]; then
		cat_title=`sed 1q "$NB_DATA_DIR"/"$entry_catlinks"`
		#cat_index=`chg_suffix "$entry_catlinks" "$NB_FILETYPE"`
		# cat_feed=`chg_suffix "$entry_catlinks" "$NB_SYND_FILETYPE"`
		set_catlink "$entry_catlinks"
		cat_index="$category_link"
		$CATLINKS_FILTER_CMD  >> "$SCRATCH_FILE".category_links <<-EOF
			<!-- $cat_title --><a href="${ARCHIVES_PATH}$cat_index">$cat_title</a>,
		EOF
	fi
done
NB_EntryCategories=$(< "$SCRATCH_FILE.category_links")
