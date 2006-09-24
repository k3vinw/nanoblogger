# Module for configuration file management
# Last modified: 2006-09-23T23:21:10-04:00

### WARNING ###
# config variables that must always load

# automatically set time zone using GNU specific, 'date +%z'
tzd_mm=`date +%z |cut -c4-5`
AUTO_TZD=`date +%z |sed 's/..$/\:'$tzd_mm'/'`

### end WARNING ###

# loads global config
load_globals(){
# always load global configs
[ -f "$NB_CFG_DIR/nb.conf" ] && . "$NB_CFG_DIR/nb.conf"
# check for user's .nb.conf in their home directory
[ -f "$HOME/.nb.conf" ] && . "$HOME/.nb.conf"
# default language definition
: ${NB_LANG:=en}
}

# loads global and user configurations
load_config(){
# set deprecated BASE_DIR for temporary compatibility
BASE_DIR="$NB_BASE_DIR"
load_globals
# allow user specified weblog directories 
[ ! -z "$USR_BLOGDIR" ] && BLOG_DIR="$USR_BLOGDIR"
# auto-detect blog.conf from our CWD
[ -z "$USR_BLOGDIR" ] || [ "$USR_BLOGDIR" = "./" ] && [ -f "$PWD/blog.conf" ] &&
	BLOG_DIR="$PWD"
BLOG_DIR="${BLOG_DIR%%\/}" # remove trailing "/"
# export BLOG_DIR for the benefit of other components
export BLOG_DIR
: ${BLOG_CONF:="$BLOG_DIR/blog.conf"}
# allow user specified weblog config files
[ -f "$USR_BLOGCONF" ] && BLOG_CONF="$USR_BLOGCONF"
# load weblog config file
[ -f "$BLOG_CONF" ] && . "$BLOG_CONF"
# set data directory
[ -d "$BLOG_DIR" ] && NB_DATA_DIR="$BLOG_DIR/data"
# allow user specified weblog data directories
[ ! -z "$USR_DATADIR" ] && NB_DATA_DIR="$USR_DATADIR"
# set template directory
: ${NB_TEMPLATE_DIR:=$BLOG_DIR/templates}
# allow user specified template directories
[ ! -z "$USR_TEMPLATE_DIR" ] && NB_TEMPLATE_DIR="$USR_TEMPLATE_DIR"
# where main plugins are located and run by default
: ${PLUGINS_DIR:=$NB_BASE_DIR/plugins}
# default location for user plugins
: ${USR_PLUGINSDIR:=$BLOG_DIR/plugins}

### WARNING ###
# changing the following requires manually modifying
# the "default" and weblog directory structure

# load user defined directory to store archives
ARCHIVES_DIR="$BLOG_ARCHIVES_DIR"
# default directory to store archives of weblog
[ -z "$ARCHIVES_DIR" ] && ARCHIVES_DIR=archives

# load user defined directory to store cached data
CACHE_DIR="$BLOG_CACHE_DIR"
# default directory to store cached data of weblog
[ -z "$CACHE_DIR" ] && CACHE_DIR=cache

# load user defined directory to store parts
PARTS_DIR="$BLOG_PARTS_DIR"
# default directory to store parts of weblog
[ -z "$PARTS_DIR" ] && PARTS_DIR=parts

### end WARNING ###

# letter to prepend to entry's html id tag
# WARNING: effects permanent links
# load user defined id tag
x_id="$BLOG_ENTRYID_TAG"
: ${x_id:=e}

# default to $USER for author
: ${BLOG_AUTHOR:=$USER}
# allow user specified author names
[ ! -z "$USR_AUTHOR" ] && BLOG_AUTHOR="$USR_AUTHOR"
# default to lynx for browser
: ${BROWSER:=lynx}
# smart defaults for date locale
if [ -n "$LC_ALL" ]; then
	: ${DATE_LOCALE:=$LC_ALL}
elif [ -n "$LC_TIME" ]; then
	: ${DATE_LOCALE:=$LC_TIME}
else
	: ${DATE_LOCALE:=$LANG}
fi
# default date command
: ${DATE_CMD:=date}
# default to vi for editor
: ${EDITOR:=vi}
# default to txt for datatype suffix
: ${NB_DATATYPE:=txt}
# default to db for database suffix
: ${NB_DBTYPE:=db}
# default to html for page suffix
: ${NB_FILETYPE:=html}

### WARNING ###
# changing the following requires manually modifying
# *all* existing entry data files!

# default metadata marker (a.k.a. spacer)
: ${METADATA_MARKER:=-----}
# default metadata close tag (e.g. 'END-----')
: ${METADATA_CLOSETAG:=$METADATA_MARKER}

### end WARNING ###

# default to raw processing for page content
: ${PAGE_FORMAT:=raw}
# default to raw processing for entry body
: ${ENTRY_FORMAT:=raw}
# default to xml for feed suffix
: ${NB_SYND_FILETYPE:=xml}
# default to AUTO_TZD for iso dates
: ${BLOG_TZD:=$AUTO_TZD}
# default to max filter for query mode
: ${QUERY_MODE:=max}
# defaults for maximum entries to display on each page
: ${MAX_ENTRIES:=10}
: ${MAX_PAGE_ENTRIES:=$MAX_ENTRIES}
: ${MAX_CATPAGE_ENTRIES:=$MAX_PAGE_ENTRIES}
: ${MAX_MONTHPAGE_ENTRIES:=$MAX_PAGE_ENTRIES}
: ${MAX_MAINPAGE_ENTRIES:=$MAX_PAGE_ENTRIES}
# defaults for index file name
: ${NB_INDEXFILE:=index.$NB_FILETYPE}
# check if we need to append directory index file to links
: ${SHOW_INDEXFILE:=1}
if [ "$SHOW_INDEXFILE" = 1 ]; then
	NB_INDEX=$NB_INDEXFILE
else
	NB_INDEX=""
fi
# default for page navigation symbols (HTML entities)
: ${NB_NextPage:=&#62;} # >
: ${NB_PrevPage:=&#60;} # <
: ${NB_TopPage:=&#47;&#92;} # /\
: ${NB_EndPage:=&#92;&#47;} # \/
# default to auto cache management
: ${BLOG_CACHEMNG:=1}
# default for maximum entries to save in cache
: ${MAX_CACHE_ENTRIES:=$MAX_ENTRIES}
# default chronological order for archives
: ${CHRON_ORDER:=1}
# determine sort order (-u required)
if [ "$CHRON_ORDER" = 1 ]; then
	SORT_ARGS="-ru"
else
	SORT_ARGS="-u"
fi
# override configuration's interactive mode
[ ! -z "$USR_INTERACTIVE" ] &&
	BLOG_INTERACTIVE="$USR_INTERACTIVE"
# default for showing category links
: ${CATEGORY_LINKS:=1}
# default for friendly links
: ${FRIENDLY_LINKS:=1}
}

# deconfigure, clear some auto-default variables
deconfig(){ ARCHIVES_DIR=; CACHE_DIR=; PARTS_DIR=; BLOG_AUTHOR=; PLUGINS_DIR=; \
	NB_DATATYPE=; NB_DBTYPE=; NB_FILETYPE=; NB_SYND_FILETYPE=; BLOG_TZD=; \
	QUERY_MODE=; MAX_ENTRIES=; MAX_PAGE_ENTRIES=; MAX_CATPAGE_ENTRIES=; \
	MAX_MONTHPAGE_ENTRIES=; MAX_MAINPAGE_ENTRIES=; METADATA_MARKER=; \
	METADATA_CLOSETAG=; PAGE_FORMAT=; ENTRY_FORMAT=; BLOG_CACHEMNG=; \
	MAX_CACHE_ENTRIES=; SORT_ARGS=; SHOW_INDEXFILE=; CHRON_ORDER=; \
	USR_PLUGINSDIR=; CATEGORY_LINKS=; FRIENDLY_LINKS=;
}

# edit $BLOG_CONF
config_weblog(){
nb_edit "$BLOG_CONF"
# check if file's been modified since opened
[ ! -N "$BLOG_CONF" ] && die "$configweblog_nomod"
deconfig; load_config
}

