# NanoBlogger Atom Feed Plugin
# synopsis: nb -q feed -t 1 -u

# concatenate modification variables
FEEDMOD_VAR="$New_EntryFile$Edit_EntryFile$Delete_EntryFile$Cat_EntryFile$USR_TITLE"

# use entry excerpts from entry excerpts plugin
# (excerpts plugin must be enabled to work)
: ${ENTRY_EXCERPTS:=0}

# limit number of items to include in feed
: ${FEED_ITEMS:=10}
: ${ATOM_ITEMS:=$FEED_ITEMS}
# build atom feeds for categories (0/1 = off/on)
: ${ATOM_CATFEEDS:=0}

# filename of atom feed
NB_AtomFile="atom.$NB_SYND_FILETYPE"
# atom feed version
NB_AtomVer="1.0"
# atom feed unique id (should be IRI as defined by RFC3987)
NB_AtomID="$BLOG_URL/"

NB_AtomModDate=`date "+%Y-%m-%dT%H:%M:%S${BLOG_TZD}"`

# set link to the archives
NB_AtomArchivesPath="$BLOG_URL/$ARCHIVES_DIR/"

# backwards support for deprecated BLOG_LANG
: ${BLOG_FEED_LANG:=$BLOG_LANG}

# watch and reset chronological order
if [ "$CHRON_ORDER" != 1 ]; then
	RESTORE_SORTARGS="$SORT_ARGS"
	SORT_ARGS="-ru"
else
	RESTORE_SORTARGS=
fi

if [ ! -z "$FEEDMOD_VAR" ] || case "$NB_QUERY" in \
				all) ! [[ "$NB_UPDATE" == *arch ]];; \
				feed|feed[a-z]) :;; *) [ 1 = false ];; \
				esac; then
	set_baseurl "$BLOG_URL/"

	# escape special characters to help create valid xml feeds
	esc_chars(){
		sed -e '/[\&][ ]/ s//\&amp; /g; /[\"]/ s//\&quot;/g'
		}

	BLOG_FEED_TITLE=`echo "$BLOG_TITLE" |esc_chars`
	NB_AtomAuthor=`echo "$BLOG_AUTHOR" |esc_chars`

	# make atom feed
	make_atomfeed(){
	MKPAGE_OUTFILE="$1"
	mkdir -p `dirname "$MKPAGE_OUTFILE"`
	BLOG_FEED_URL="$BLOG_URL/$NB_AtomFile"
	NB_RSS2Title="$BLOG_FEED_TITLE"
	[ ! -z "$NB_AtomCatTitle" ] &&
		NB_AtomTitle="$template_catarchives $NB_AtomCatTitle | $BLOG_FEED_TITLE"
	[ ! -z "$NB_AtomCatLink" ] &&
		BLOG_FEED_URL="$BLOG_URL/$ARCHIVES_DIR/$NB_AtomCatFile"

	cat > "$MKPAGE_OUTFILE" <<-EOF
		<?xml version="1.0" encoding="$BLOG_CHARSET"?>
		<feed xmlns="http://www.w3.org/2005/Atom">
        <?xml-stylesheet type="text/css" href="${BASE_URL}styles/feed.css"?>
		<title type="html">$NB_AtomTitle</title>
		<link rel="alternate" type="text/html" href="$BLOG_URL"/>
		<link rel="self" type="application/atom+xml" href="$BLOG_FEED_URL"/>
		<updated>$NB_AtomModDate</updated>
		<author>
			<name>$NB_AtomAuthor</name>
			<uri>$BLOG_URL</uri>
		</author>
		<id>$NB_AtomID</id>
		<generator uri="http://nanoblogger.sourceforge.net" version="$VERSION">
			NanoBlogger
		</generator>

		$NB_AtomEntries

		</feed>
	EOF
	nb_msg "$MKPAGE_OUTFILE"
	# load makepage tidy plugin
	[ -f "$PLUGINS_DIR"/makepage/tidy.sh ] &&
		. "$PLUGINS_DIR"/makepage/tidy.sh
	NB_AtomTitle=
	}

	# generate feed entries
	build_atomfeed(){
	db_catquery="$1"
	query_db all "$db_catquery" limit "$ATOM_ITEMS"
	ARCHIVE_LIST=(${DB_RESULTS[@]})
	> "$SCRATCH_FILE".atomfeed
	for entry in ${ARCHIVE_LIST[@]}; do
		load_entry "$NB_DATA_DIR/$entry" ALL
		set_entrylink "$entry"
		Atom_EntryTime=`echo "$entry" |sed -e '/\_/ s//\:/g; s/[\.]'$NB_DATATYPE'//g'`
		Atom_EntryDate=`echo "$Atom_EntryTime${BLOG_TZD}"`
		# non-portable find command!
		#Atom_EntryModDate=`find "$NB_DATA_DIR/$entry" -printf "%TY-%Tm-%TdT%TH:%TM:%TS${BLOG_TZD}"`
		Atom_EntryModDate="$Atom_EntryDate"
		Atom_EntryTitle=`echo "$NB_EntryTitle" |esc_chars`
		Atom_EntryAuthor=`echo "$NB_EntryAuthor" |esc_chars`
		Atom_EntryCategory=; cat_title=
		> "$SCRATCH_FILE".atomfeed-cat
		atomentry_wcatids=`grep "$entry" "$NB_DATA_DIR/master.$NB_DBTYPE"`
		atomentry_catids="${atomentry_wcatids##*\>}"
		[ "$atomentry_wcatids" = "$atomentry_catids" ] &&
			atomentry_catids=
		for atomentry_catdb in ${atomentry_catids//\,/ }; do
			cat_title=`nb_print "$NB_DATA_DIR"/cat_"$atomentry_catdb.$NB_DBTYPE" 1`
			cat_title=`echo "${cat_title##\,}" |esc_chars`
			if [ ! -z "$cat_title" ]; then
				cat >> "$SCRATCH_FILE".atomfeed-cat <<-EOF
					<category term="$cat_title" />
				EOF
			fi
		done
		Atom_EntryCategory=$(< "$SCRATCH_FILE".atomfeed-cat)
		if [ "$ENTRY_EXCERPTS" = 1 ] && [ ! -z "$NB_EntryExcerpt" ]; then
			#Atom_EntryExcerpt=`echo "$NB_EntryExcerpt" |esc_chars`
			Atom_EntryExcerpt="$NB_EntryExcerpt"
		else
			#Atom_EntryExcerpt=`echo "$NB_EntryBody" |esc_chars`
			Atom_EntryExcerpt="$NB_EntryBody"
		fi
		cat >> "$SCRATCH_FILE".atomfeed <<-EOF
			<entry>
				<title type="html">$Atom_EntryTitle</title>
				<author>
					<name>$Atom_EntryAuthor</name>
				</author>
				<link rel="alternate" type="text/html" href="${NB_AtomArchivesPath}$NB_EntryPermalink"/>
				<id>${NB_AtomArchivesPath}$NB_EntryPermalink</id>
				<published>$Atom_EntryDate</published>
				<updated>$Atom_EntryModDate</updated>
				$Atom_EntryCategory
				<content type="xhtml">
					<div xmlns="http://www.w3.org/1999/xhtml">
						$Atom_EntryExcerpt
					</div>
				</content>

			</entry>
		EOF
	done
	NB_AtomEntries=$(< "$SCRATCH_FILE".atomfeed)
	}

	# generate cat feed entries
	build_atom_catfeeds(){
	if [ "$CATEGORY_FEEDS" = 1 ] || test -z "$CATEGORY_FEEDS" -a "$ATOM_CATFEEDS" = 1; then
		db_categories=(${CAT_LIST[@]})
		if [ ! -z "${db_categories[*]}" ]; then
			for cat_db in ${db_categories[@]}; do
				if [ -f "$NB_DATA_DIR/$cat_db" ]; then
					set_catlink "$cat_db"
					NB_AtomCatTitle=`nb_print "$NB_DATA_DIR/$cat_db" 1 |esc_chars`
					NB_AtomCatFile=`echo "$category_file" |sed -e 's/[\.]'$NB_FILETYPE'/-atom.'$NB_SYND_FILETYPE'/g'`
					NB_AtomCatLink="$category_link"
					nb_msg "$plugins_action $category_dir atom $NB_AtomVer feed ..."
					build_atomfeed "$cat_db"
					make_atomfeed "$BLOG_DIR/$ARCHIVES_DIR/$NB_AtomCatFile"
				fi
			done
		fi
	fi
	}

	nb_msg "$plugins_action atom $NB_AtomVer feed ..."
	build_atomfeed nocat
	make_atomfeed "$BLOG_DIR/$NB_AtomFile"
	build_atom_catfeeds
fi

# restore chronological order
[ ! -z "$RESTORE_SORTARGS" ] &&
	SORT_ARGS="$RESTORE_SORTARGS"

