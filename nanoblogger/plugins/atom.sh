# NanoBlogger Atom Feed Plugin

# Limit number of items to include in feed
LIMIT_ITEMS="10"
[ -z "$LIMIT_ITEMS" ] && LIMIT_ITEMS="$MAX_ENTRIES"

NB_AtomModDate=`date "+%Y-%m-%dT%H:%M:%S$BLOG_TZD"`

# escape special characters to help create valid xml feeds
esc_chars(){
	sed -e '/[\&][ ]/ s//\&amp; /g; /[\"]/ s//\&quot;/g'
	}

# make atom feed
make_atomfeed(){
MKPAGE_OUTFILE="$BLOG_DIR/atom.$NB_SYND_FILETYPE"
nb_msg "$MKPAGE_OUTFILE"
cat > "$MKPAGE_OUTFILE" <<-EOF
	<?xml version="1.0" encoding="$BLOG_CHARSET"?>
	<feed version="0.3"
		xmlns="http://purl.org/atom/ns#"
		xmlns:dc="http://purl.org/dc/elements/1.1/"
	>
	<title mode="escaped">$BLOG_TITLE</title>
	<link rel="alternate" type="text/html" href="$BLOG_URL"/>
	<modified>$NB_AtomModDate</modified>
	<author>
		<name>$NB_EntryAuthor</name>
		<url>$BLOG_URL</url>
	</author>

	$NB_AtomEntries

	</feed>
EOF
}

# generate feed entries
build_atomfeed(){
	db_catquery="$1"
	query_db limit "$db_catquery" "$LIMIT_ITEMS"
	ARCHIVE_LIST="$DB_RESULTS"
	> "$SCRATCH_FILE"
	for entry in $ARCHIVE_LIST; do
	        read_entry "$NB_DATA_DIR/$entry"
		Atom_EntryTime=$(echo "$entry" |sed -e '/\_/ s//\:/g; s/[\.]htm//g')
		Atom_EntryDate=$(echo "$NB_EntryTime$BLOG_TZD")
		# non-portable find command!
		#Atom_EntryModDate=$(find "$NB_DATA_DIR/$entry" -printf "%TY-%Tm-%TdT%TH:%TM:%TS$BLOG_TZD")
		Atom_EntryModDate="$Atom_EntryDate"
		Atom_EntryTitle=$(echo "$NB_EntryTitle" |esc_chars)
		Atom_EntrySubject=; cat_title=; oldcat_title=
		for cat_db in $db_categories; do
			cat_var=$(grep "$entry" "$NB_DATA_DIR/$cat_db")
			if [ ! -z "$cat_var" ]; then
				cat_title=$(sed -n 1p "$NB_DATA_DIR/$cat_db")
				[ "$cat_title" != "$oldcat_title" ] && cat_title="$oldcat_title $cat_title"
				oldcat_title="$cat_title,"
			fi
		done
		if [ ! -z "$cat_title" ]; then
			cat_title=$(echo $cat_title |sed -e '{$ s/\,[ ]$//g; }' |esc_chars)
			Atom_EntrySubject=$(echo '<dc:subject>'$cat_title'</dc:subject>')
		fi
		#Atom_EntryExcerpt=$(echo "$NB_EntryBody" |sed -n '1,/^$/p' |esc_chars)
		Atom_EntryExcerpt=$(echo "$NB_EntryBody" |sed -n '1,/^$/p')
		cat >> "$SCRATCH_FILE" <<-EOF
			<entry>
				<title mode="escaped">$Atom_EntryTitle</title>
				<author>
					<name>$NB_EntryAuthor</name>
				</author>
				<link rel="alternate" type="text/html" href="$BLOG_URL/$ARCHIVES_DIR/$NB_EntryPermalink"/>
				<id>$BLOG_URL/$ARCHIVES_DIR/$NB_EntryPermalink</id>
				<issued>$Atom_EntryDate</issued>
				<modified>$Atom_EntryModDate</modified>
				<created>$NB_AtomEntryDate</created>
				$Atom_EntrySubject
				<content type="application/xhtml+xml" xml:lang="en" xml:space="preserve" mode="escaped">
					<![CDATA[
					$Atom_EntryExcerpt
					]]>
				</content>

			</entry>
		EOF
	done
	NB_AtomEntries=$(<"$SCRATCH_FILE")
	}


nb_msg "generating atom feed ..."
build_atomfeed nocat
make_atomfeed
