# NanoBlogger RSS 2.0 Feed Plugin

# Limit number of items to include in feed
: ${LIMIT_ITEMS:=10}

NB_RSSModDate=`date "+%Y-%m-%dT%H:%M:%S$BLOG_TZD"`
# Make links temporarily absolute
ARCHIVES_URL="$BLOG_URL/$ARCHIVES_DIR/"
[ "$ABSOLUTE_LINKS" = "1" ] && ARCHIVES_URL=""
OLD_BASE_URL="$BASE_URL"
BASE_URL="$BLOG_URL/"

# escape special characters to help create valid xml feeds
esc_chars(){
	sed -e '/[\&][ ]/ s//\&amp; /g; /[\"]/ s//\&quot;/g'
	}

# make rss feed
make_rssfeed(){
	feed_outfile="$1"
	MKPAGE_OUTFILE="$feed_outfile"
	BLOG_FEED_URL="$BLOG_URL/rss.$NB_SYND_FILETYPE"
	[ ! -z "$cat_archfeed" ] && BLOG_FEED_URL="$BLOG_URL/$ARCHIVES_DIR/$cat_archfeed"

	cat > "$MKPAGE_OUTFILE" <<-EOF
		<?xml version="1.0" encoding="$BLOG_CHARSET"?>
		<rss version="2.0"
		 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
		 xmlns:dc="http://purl.org/dc/elements/1.1/"
		 xmlns:admin="http://webns.net/mvcb/"
		>
		<channel>
			<title>$BLOG_TITLE</title>
			<link>$BLOG_URL</link>
			<description>$BLOG_DESCRIPTION</description>
			<dc:language>$BLOG_LANG</dc:language>
			<dc:creator>$NB_EntryAuthor</dc:creator>
			<dc:date>$NB_RSSModDate</dc:date>
			<admin:generatorAgent rdf:resource="http://nanoblogger.sourceforge.net" />
			$NB_RSSEntries
		</channel>
		</rss>
	EOF
	nb_msg "$MKPAGE_OUTFILE"
	}

# generate feed entries
build_rssfeed(){
	db_catquery="$1"
	query_db max "$db_catquery" "$LIMIT_ITEMS"
	ARCHIVE_LIST="$DB_RESULTS"
	> "$SCRATCH_FILE"
	for entry in $ARCHIVE_LIST; do
		RSS_EntryTime=`echo "$entry" |sed -e '/\_/ s//\:/g; s/[\.]'$NB_DATATYPE'//g'`
	        read_entry "$NB_DATA_DIR/$entry"
		# non-portable find command!
		#RSS_EntryModDate=`find "$NB_DATA_DIR/$entry" -printf "%TY-%Tm-%TdT%TH:%TM:%TS$BLOG_TZD"`
		RSS_EntryTitle=`echo "$NB_EntryTitle" |esc_chars`
		RSS_EntrySubject=; cat_title=; oldcat_title=
		for cat_db in $db_categories; do
			cat_var=`grep "$entry" "$NB_DATA_DIR/$cat_db"`
			if [ ! -z "$cat_var" ]; then
				cat_title=`sed 1q "$NB_DATA_DIR/$cat_db"`
				[ "$cat_title" != "$oldcat_title" ] && cat_title="$oldcat_title $cat_title"
				oldcat_title="$cat_title,"
			fi
		done
		if [ ! -z "$cat_title" ]; then
			cat_title=`echo $cat_title |sed -e '{$ s/\,[ ]$//g; }' |esc_chars`
			RSS_EntrySubject=`echo '<dc:subject>'$cat_title'</dc:subject>'`
		fi
		#RSS_EntryExcerpt=`echo "$NB_EntryBody" |sed -n '1,/^$/p' |esc_chars`
		RSS_EntryExcerpt="$NB_EntryBody"
		cat >> "$SCRATCH_FILE" <<-EOF
			<item>
				<link>${ARCHIVES_URL}$NB_EntryPermalink</link>
				<title>$RSS_EntryTitle</title>
				<dc:date>$RSS_EntryTime$BLOG_TZD</dc:date>
				<dc:creator>$NB_EntryAuthor</dc:creator>
				$RSS_EntrySubject
				<description><![CDATA[$RSS_EntryExcerpt]]></description>
			</item>
		EOF
	done
	NB_RSSEntries=$(< "$SCRATCH_FILE")
	}

# generate category feed entries
build_rss_catfeeds(){
	if [ "$CATEGORY_FEEDS" = 1 ]; then
		db_categories="$CAT_LIST"
		if [ ! -z "$db_categories" ]; then
			for cat_db in $db_categories; do
				if [ -f "$NB_DATA_DIR/$cat_db" ]; then
					cat_archfeed=`chg_suffix "$cat_db" "$NB_SYND_FILETYPE"`
					NB_ArchiveTitle=`sed 1q "$NB_DATA_DIR/$cat_db" |esc_chars`
					nb_msg "generating rss 2.0 feed for category ..."
					build_rssfeed "$cat_db"
					make_rssfeed "$BLOG_DIR/$ARCHIVES_DIR/$cat_archfeed"
				fi
			done
		fi
	fi
	}

nb_msg "generating rss 2.0 feed ..."
build_rssfeed nocat
make_rssfeed "$BLOG_DIR/rss.$NB_SYND_FILETYPE"
build_rss_catfeeds
BASE_URL="$OLD_BASE_URL"
