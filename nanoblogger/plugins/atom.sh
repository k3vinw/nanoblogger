# NanoBlogger Atom Feed Plugin

ATOMFEED_TEMPLATE="$BLOG_DIR/$TEMPLATE_DIR/atom.xml"
ATOMENTRY_TEMPLATE="atom_entry.xml"

[ -f "$ATOMFEED_TEMPLATE" ] && [ -f "$BLOG_DIR/$TEMPLATE_DIR/$ATOMENTRY_TEMPLATE" ] ||
	die "plugins/atom.sh: templates missing ('$ATOMFEED_TEMPLATE, $BLOG_DIR/$TEMPLATE_DIR/$ATOMENTRY_TEMPLATE')"

NB_AtomModDate=`date "+%Y-%m-%dT%H:%M:%S$BLOG_TZD"`

build_atomfeed(){
	query_type="$1"
	db_catquery="$2"
	template="$3"
	output_file="$4"
	query_db "$query_type" "$db_catquery" "$db_limit"
	ARCHIVE_LIST="$DB_RESULTS"
	for entry in $ARCHIVE_LIST; do
	        read_entry "$BLOG_DIR"/"$ARCHIVES"/"$entry"
		NB_AtomEntryDate=`echo "$NB_EntryID$BLOG_TZD"`
		NB_AtomEntryModDate=`find "$BLOG_DIR/$ARCHIVES/$entry" -printf "%TY-%Tm-%TdT%TH:%TM:%TS$BLOG_TZD"`
		load_template "$BLOG_DIR"/"$TEMPLATE_DIR"/"$template"
		        if [ ! -z "$BLOG_HTML" ]; then
			                echo "$BLOG_HTML" >> "$BLOG_DIR"/archives.tmp
			                BLOG_HTML=
			                PLACEHOLDER=
			                NB_EntryCategories=
			                NB_EntryCategoryTitle=
		        fi
	done
	touch "$BLOG_DIR"/archives.tmp
	cat "$BLOG_DIR"/archives.tmp > "$BLOG_DIR"/"$PARTS_DIR"/"$output_file"
	rm -f "$BLOG_DIR"/archives.tmp
	}


nb_msg "generating atom feed ..."
build_atomfeed current nocat "$ATOMENTRY_TEMPLATE" atom.xml
make_page "$BLOG_DIR/$PARTS_DIR/atom.xml" "$ATOMFEED_TEMPLATE" "$BLOG_DIR/atom.xml"
