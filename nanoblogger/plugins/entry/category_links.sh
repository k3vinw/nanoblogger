# NanoBlogger Category Links Plugin
# Entry Plugin to find related categories and generate links for them
query_db
>"$SCRATCH_FILE".category_links
get_cat_titles(){ for cat_db in $db_categories; do echo "`sed -n 1p $NB_DATA_DIR/$cat_db` | $cat_db"; done; }
CAT_TLIST=`get_cat_titles |sort -u |cut -d"|" -f 2`
for entry_catlinks in $CAT_TLIST; do
	cat_var=`grep "$entry" "$NB_DATA_DIR"/"$entry_catlinks"`
	if [ ! -z "$cat_var" ]; then
		cat_title=`sed -n 1p "$NB_DATA_DIR"/"$entry_catlinks"`
		cat_index=`chg_suffix "$entry_catlinks"`; cat_feed=`chg_suffix "$entry_catlinks" "$NB_SYND_FILETYPE"`
		cat >> "$SCRATCH_FILE".category_links <<-EOF
			<a href="${ARCHIVES_PATH}$cat_index">$cat_title</a>,
		EOF
	fi
done
NB_EntryCategories="$(<$SCRATCH_FILE.category_links)"
