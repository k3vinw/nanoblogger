# NanoBlogger Atom Feed Plugin

ATOMFEED_TEMPLATE="$BLOG_DIR/$TEMPLATE_DIR/atom.xml"
ATOMENTRY_TEMPLATE="atom_entry.xml"

[ -f "$ATOMFEED_TEMPLATE" ] && [ -f "$BLOG_DIR/$TEMPLATE_DIR/$ATOMENTRY_TEMPLATE" ] ||
	die "plugins/atom.sh: templates missing ('$ATOMFEED_TEMPLATE, $BLOG_DIR/$TEMPLATE_DIR/$ATOMENTRY_TEMPLATE')"

NB_AtomModDate=`date "+%Y-%m-%dT%H:%M:%S$BLOG_TZD"`

# escape special characters to help create valid xml feeds
esc_chars(){
	sed -e '/[\&][ ]/ s//\&amp; /g; /[\"]/ s//\&quot;/g'
	}

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
		# non-portable find command!
		#NB_AtomEntryModDate=`find "$BLOG_DIR/$ARCHIVES/$entry" -printf "%TY-%Tm-%TdT%TH:%TM:%TS$BLOG_TZD"`
		NB_AtomEntryModDate="$NB_AtomEntryDate"
		NB_EntryTitle=`echo "$NB_EntryTitle" |esc_chars`
		#NB_EntryExcerpt=`echo "$NB_EntryBody" |sed -n '1,/^$/p' |esc_chars`
		NB_EntryExcerpt=`echo "$NB_EntryBody" |sed -n '1,/^$/p'`
		make_placeholder "$template" atom_entries.tmp "$output_file"
	done
	touch "$BLOG_DIR"/atom_entries.tmp
	cat "$BLOG_DIR"/atom_entries.tmp > "$BLOG_DIR"/"$PARTS_DIR"/"$output_file"
	rm -f "$BLOG_DIR"/atom_entries.tmp
	}


nb_msg "generating atom feed ..."
build_atomfeed current nocat "$ATOMENTRY_TEMPLATE" atom."$NB_SYND_FILETYPE"
rm -f "$BLOG_DIR/$PARTS_DIR/atom.$NB_SYND_FILETYPE"
NB_Entries="$PLACEHOLDER"

# make atom feed (alternate to calling make_page)
MKPAGE_OUTFILE="$BLOG_DIR/atom.$NB_SYND_FILETYPE"
load_template "$ATOMFEED_TEMPLATE"
echo "$BLOG_HTML" > "$MKPAGE_OUTFILE"
nb_msg "$MKPAGE_OUTFILE"
load_plugins plugins/postformat

