# NanoBlogger RSS 2.0 Feed Plugin

# Limit number of items to include in feed
: ${LIMIT_ITEMS:=10}

# output filename of rss feed
NB_RSS2File="rss.$NB_SYND_FILETYPE"
# rss version
NB_RSS2Ver="2.0"

NB_RSS2ModDate=`date "+%Y-%m-%dT%H:%M:%S${BLOG_TZD}"`

# set link to archives
NB_RSS2ArchivesPath="$BLOG_URL/$ARCHIVES_DIR/"

set_baseurl "$BLOG_URL/"

# escape special characters to help create valid xml feeds
esc_chars(){
	sed -e '/[\&][ ]/ s//\&amp; /g; /[\"]/ s//\&quot;/g'
	}

NB_RSS2Title=`echo "$BLOG_TITLE" |esc_chars`
NB_RSS2Author=`echo "$BLOG_AUTHOR" |esc_chars`

# make rss feed
make_rssfeed(){
	feed_outfile="$1"
	MKPAGE_OUTFILE="$feed_outfile"
	mkdir -p `dirname "$MKPAGE_OUTFILE"`
	BLOG_FEED_URL="$BLOG_URL"
	[ ! -z "$NB_RSS2CatLink" ] && BLOG_FEED_URL="$BLOG_URL/$ARCHIVES_DIR/$NB_RSS2CatLink"

	cat > "$MKPAGE_OUTFILE" <<-EOF
		<?xml version="1.0" encoding="$BLOG_CHARSET"?>
		<rss version="2.0"
		 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
		 xmlns:dc="http://purl.org/dc/elements/1.1/"
		 xmlns:admin="http://webns.net/mvcb/"
		>
		<channel>
			<title>$NB_RSS2Title</title>
			<link>$BLOG_FEED_URL</link>
			<description>$BLOG_DESCRIPTION</description>
			<dc:language>$BLOG_LANG</dc:language>
			<dc:creator>$NB_RSS2Author</dc:creator>
			<dc:date>$NB_RSS2ModDate</dc:date>
			<admin:generatorAgent rdf:resource="http://nanoblogger.sourceforge.net" />
			$NB_RSS2Entries
		</channel>
		</rss>
	EOF
	nb_msg "$MKPAGE_OUTFILE"
	# load makepage tidy plugin
	[ -f "$PLUGINS_DIR"/makepage/tidy.sh ] &&
		. "$PLUGINS_DIR"/makepage/tidy.sh
	}

# generate feed entries
build_rssfeed(){
	db_catquery="$1"
	query_db max "$db_catquery" limit "$LIMIT_ITEMS"
	ARCHIVE_LIST="$DB_RESULTS"
	> "$SCRATCH_FILE"
	for entry in $ARCHIVE_LIST; do
		NB_RSS2EntryTime=`echo "$entry" |sed -e '/\_/ s//\:/g; s/[\.]'$NB_DATATYPE'//g'`
	        read_entry "$NB_DATA_DIR/$entry"
		set_entrylink "$entry"
		# non-portable find command! sets RFC822 date for pubDate
		#NB_RSS2EntryModDate=`find "$NB_DATA_DIR/$entry" -printf "%Ta, %Td %Tb %TY %TH:%TM:%TS %Tz\n"`
		NB_RSS2EntryTitle=`echo "$NB_EntryTitle" |esc_chars`
		NB_RSS2EntryAuthor=`echo "$NB_EntryAuthor" |esc_chars`
		NB_RSS2EntrySubject=; cat_title=; oldcat_title=
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
			NB_RSS2EntrySubject=`echo '<dc:subject>'$cat_title'</dc:subject>'`
		fi
		#NB_RSS2EntryExcerpt=`echo "$NB_EntryBody" |sed -n '1,/^$/p' |esc_chars`
		#<description><![CDATA[$NB_RSS2EntryExcerpt]]></description>
		NB_RSS2EntryExcerpt="$NB_EntryBody"
		cat >> "$SCRATCH_FILE" <<-EOF
			<item>
				<link>${NB_RSS2ArchivesPath}$NB_EntryPermalink</link>
				<title>$NB_RSS2EntryTitle</title>
				<dc:date>$NB_RSS2EntryTime${BLOG_TZD}</dc:date>
				<dc:creator>$NB_RSS2EntryAuthor</dc:creator>
				$NB_RSS2EntrySubject
				<description><![CDATA[$NB_RSS2EntryExcerpt]]></description>
			</item>
		EOF
	done
	NB_RSS2Entries=$(< "$SCRATCH_FILE")
	}

# generate category feed entries
build_rss_catfeeds(){
	if [ "$CATEGORY_FEEDS" = 1 ]; then
		db_categories="$CAT_LIST"
		if [ ! -z "$db_categories" ]; then
			for cat_db in $db_categories; do
				if [ -f "$NB_DATA_DIR/$cat_db" ]; then
					set_catlink "$cat_db"
					NB_RSS2CatFile=`echo "$category_file" |sed -e 's/[\.]'$NB_FILETYPE'/-rss.'$NB_SYND_FILETYPE'/g'`
					NB_RSS2CatLink="$category_link"
					NB_RSS2CatTitle=`sed 1q "$NB_DATA_DIR/$cat_db" |esc_chars`
					nb_msg "$plugins_action rss $NB_RSS2Ver feed for category ..."
					build_rssfeed "$cat_db"
					make_rssfeed "$BLOG_DIR/$ARCHIVES_DIR/$NB_RSS2CatFile"
				fi
			done
		fi
	fi
	}

nb_msg "$plugins_action rss $NB_RSS2Ver feed ..."
build_rssfeed nocat
make_rssfeed "$BLOG_DIR/$NB_RSS2File"
build_rss_catfeeds

