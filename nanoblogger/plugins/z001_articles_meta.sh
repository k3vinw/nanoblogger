# NanoBlogger Metadata Based Article Manager plugin

# How it works:
# Looks for .txt files in multiple directories.
# Loads metafile (use --draft <file> to create).
# Creates the article using the makepage.htm template.
# Reads alternate title for list from $ARTICLES_TITLE_FILE (1st line).
# Adds links to NB_ArticleLinks.

# sample code for templates, based off the default stylesheet
#
# $NB_Article_Links

# set BASE_URL for links to $ARTICLE_DIR
set_baseurl "./"

# space seperated list of sub-directories inside $BLOG_DIR, where articles are located
set_articleconf(){
# e.g. ARTICLE_DIRS="articles stories poems long\ name\ with\ spaces"
: ${ARTICLE_DIRS:=articles}
: ${ARTICLE_SUFFIX:=txt}
: ${ARTICLE_TEMPLATE:=$NB_TEMPLATE_DIR/$MAKEPAGE_TEMPLATE}
: ${ARTICLE_FILTERCMD:=sort}
: ${ARTICLES_TITLE_FILE:=.articles_title.txt}
: ${ARTICLE_FORMAT:=$PAGE_FORMAT}
}

# reset basic configs to allow for multiple article configs
reset_articleconf(){
ARTICLE_SUFFIX=; ARTICLE_TEMPLATE=; ARTICLE_FORMAT=
set_articleconf
}

ARTICLE_PLUGIN_OUTFILE="$BLOG_DIR/$PARTS_DIR/article_links.$NB_FILETYPE"

set_articlelink(){
articlelink_var="$1"
#article_title=`sed 1q "$BLOG_DIR/$ARTICLE_DIR/$articlelink_var"`
read_metadata TITLE "$BLOG_DIR/$ARTICLE_DIR/$articlelink_var"
if [ -z "$METADATA" ]; then
	article_title="$notitle"
else
	article_title="$METADATA"
fi

# new way
article_name=`echo "$articlelink_var" |cut -d"." -f 1`
article_dir=`set_title2link "$article_name"`
article_file="$article_dir/index.$NB_FILETYPE"
article_link="$article_dir/$NB_INDEX"

# old way
#article_file=`chg_suffix "$articlelink_var"`
#article_link="$article_file"
}

addalist_name(){
NB_ArticlesListTitle=
# Reads alternate title for list from $ARTICLES_TITLE_FILE (1st line).
[ -f "$BLOG_DIR/$ARTICLE_DIR/$ARTICLES_TITLE_FILE" ] &&
	NB_ArticlesListTitle=`sed 1q $BLOG_DIR/$ARTICLE_DIR/$ARTICLES_TITLE_FILE`
[ -z "$NB_ArticlesListTitle" ] && NB_ArticlesListTitle="$ARTICLE_DIR"
# fallback to our language definition for list's title
[ ! -z "$template_articles" ] && [ -z "$NB_ArticlesListTitle" ] &&
	NB_ArticlesListTitle="$template_articles"
cat >> "$ARTICLE_PLUGIN_OUTFILE" <<-EOF
	<div class="sidetitle">
		$NB_ArticlesListTitle
	</div>
EOF
NB_ArticlesListTitleHTML=$(< "$ARTICLE_PLUGIN_OUTFILE")
> "$ARTICLE_PLUGIN_OUTFILE"
}

add_articlelink(){
	echo '<!--'$BLOGPAGE_TITLE'--><a href="'${BASE_URL}$ARTICLE_DIR/$article_link'">'$BLOGPAGE_TITLE'</a><br />' >> "$ARTICLE_PLUGIN_OUTFILE"
	}

create_article(){
BLOGPAGE_SRCFILE="$BLOG_DIR/$ARTICLE_DIR/$article_srcfile"
BLOGPAGE_OUTFILE="$BLOG_DIR/$ARTICLE_DIR/$article_file"
[ "$USR_QUERY" = articles ] || [ "$USR_QUERY" = all ] && rm -f "$BLOGPAGE_OUTFILE"
if [ "$BLOGPAGE_SRCFILE" -nt "$BLOGPAGE_OUTFILE" ]; then
	# set text formatting for page content
	BLOGPAGE_FORMAT="$ARTICLE_FORMAT"
	weblog_page "$BLOGPAGE_SRCFILE" "$ARTICLE_TEMPLATE" "$BLOGPAGE_OUTFILE"
fi
}

cycle_articles_for(){
build_part="$1"
build_list=`cd "$BLOG_DIR/$ARTICLE_DIR"; for articles in *.$ARTICLE_SUFFIX; do echo "$articles"; done`
[ "$build_list" = "*.$ARTICLE_SUFFIX" ] && build_list=
article_lines=`echo "$build_list" |grep -n "." |cut -c1-2 |sed -e '/[\:\]/ s///g'`
for line in ${article_lines[@]}; do
	article_line=`echo "$build_list" |sed -n "$line"p`
	article_srcfile=`echo "$article_line"`
	if [ -f "$BLOG_DIR/$ARTICLE_DIR/$article_srcfile" ]; then
		set_articlelink "$article_srcfile"
		BLOGPAGE_TITLE="$article_title"
		"$build_part"
	fi
done
}

> "$ARTICLE_PLUGIN_OUTFILE"
set_articleconf
for articles_pass in 1 2; do
	for ARTICLE_DIR in ${ARTICLE_DIRS[@]}; do
		if [ -d "$BLOG_DIR/$ARTICLE_DIR" ]; then
			# load articles config file
			ARTICLE_CONF="$BLOG_DIR/$ARTICLE_DIR/article.conf"
			if [ -f "$ARTICLE_CONF" ]; then
				reset_articleconf
				. "$ARTICLE_CONF"
			fi
			if [ "$articles_pass" -lt 2 ]; then
				addalist_name
				cycle_articles_for add_articlelink
				NB_ArticleLinksHTML=`$ARTICLE_FILTERCMD "$ARTICLE_PLUGIN_OUTFILE"`
				cat > "$ARTICLE_PLUGIN_OUTFILE" <<-EOF
					$NB_ArticlesListTitleHTML
					<div class="side">
						$NB_ArticleLinksHTML
					</div>
				EOF
				NB_ArticleLinks=$(< "$ARTICLE_PLUGIN_OUTFILE")
			else
				[ -d "$BLOG_DIR/$ARTICLE_DIR" ] && nb_msg "$plugins_action articles for $BLOG_DIR/$ARTICLE_DIR ..."
				cycle_articles_for create_article
			fi
		fi
	done
done
# clear settings for some page plugins, like markdown.sh
reset_articleconf
