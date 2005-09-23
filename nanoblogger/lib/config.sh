# Module for configuration file management

# loads global and user configurations
load_config(){
# set deprecated BASE_DIR for temporary compatibility
BASE_DIR="$NB_BASE_DIR"
# always load global configs
[ -f "$NB_BASE_DIR/nb.conf" ] && . "$NB_BASE_DIR/nb.conf"
# check for user's .nb.conf in their home directory
[ -f "$HOME/.nb.conf" ] && . "$HOME/.nb.conf"
# allow user specified weblog directories 
[ ! -z "$USR_BLOGDIR" ] && BLOG_DIR="$USR_BLOGDIR"
# auto-detect blog.conf from our CWD
[ -f "$PWD/blog.conf" ] && BLOG_DIR="$PWD"
# export BLOG_DIR for the benefit of other components
export BLOG_DIR
: ${BLOG_CONF:="$BLOG_DIR/blog.conf"}
# allow user specified weblog config files
[ -f "$USR_BLOGCONF" ] && BLOG_CONF="$USR_BLOGCONF"
# load weblog config file
[ -f "$BLOG_CONF" ] && . "$BLOG_CONF"
# set data directory
[ -d "$BLOG_DIR/data" ] && NB_DATA_DIR="$BLOG_DIR/data"
# allow user specified weblog data directories
[ ! -z "$USR_DATADIR" ] && NB_DATA_DIR="$USR_DATADIR"
# set template directory
: ${NB_TEMPLATE_DIR:=$BLOG_DIR/templates}
# allow user specified template directories
[ ! -z "$USR_TEMPLATE_DIR" ] && NB_TEMPLATE_DIR="$USR_TEMPLATE_DIR"
# where plugins are located and run by default
: ${PLUGINS_DIR:=$NB_BASE_DIR/plugins}
# default to $USER for author
: ${BLOG_AUTHOR:=$USER}
# allow user specified author names
[ ! -z "$USR_AUTHOR" ] && BLOG_AUTHOR="$USR_AUTHOR"
# default to lynx for browser
: ${BROWSER:=lynx}
# default to vi for editor
: ${EDITOR:=vi}
# default to txt for datatype suffix
: ${NB_DATATYPE:=txt}
# default to db for database suffix
: ${NB_DBTYPE:=db}
# default to html for page suffix
: ${NB_FILETYPE:=html}
# default to xml for feed suffix
: ${NB_SYND_FILETYPE:=xml}
# default to AUTO_TZD for iso dates
: ${BLOG_TZD:=$AUTO_TZD}
# default to max filter for query mode
: ${QUERY_MODE:=max}
# defaults for maximum entries to display on each page
: ${MAX_ENTRIES:=10}; : ${MAX_PAGE_ENTRIES:=$MAX_ENTRIES}
# defaults for index file name
: ${NB_INDEXFILE:=index.$NB_FILETYPE}
# default for previous and next page symbols, using html entities
: ${NB_NextPage:=[&#62;&#62;]}
: ${NB_PrevPage:=[&#60;&#60;]}
# default sort arguments (-u|nique is required)
: ${SORT_ARGS:=-ru}
}

# deconfigure, clear some auto-default variables
deconfig(){ BLOG_AUTHOR=; PLUGINS_DIR=; NB_DATATYPE=; NB_DBTYPE=; \
	NB_FILETYPE=; NB_SYND_FILETYPE=; BLOG_TZD=; QUERY_MODE=; MAX_ENTRIES=; \
	SORT_ARGS=; }

# insure a sane configuration or die
check_config(){
load_config
# die without the base directory
[ ! -d "$NB_BASE_DIR" ] &&
	die "`basename $0`: base directory '$NB_BASE_DIR' doesn't exist! goodbye."
[ -z "$BLOG_DIR" ] && die "no weblog directory specified! goodbye."
[ ! -z "$USR_BLOGCONF" ] &&
	[ ! -f "$USR_BLOGCONF" ] && die "weblog config file '$USR_BLOGCONF' doesn't exist! goodbye."
[ ! -d "$BLOG_DIR" ] && die "weblog directory '$BLOG_DIR' doesn't exist! goodbye."
[ ! -d "$NB_DATA_DIR" ] && die "weblog's data directory '$NB_DATA_DIR' doesn't exist! goodbye."
[ ! -d "$BLOG_DIR/$CACHE_DIR" ] && die "weblog's cache directory '$CACHE_DIR' doesn't exist! goodbye."
[ ! -d "$NB_TEMPLATE_DIR" ] && die "weblog's templates directory '$NB_TEMPLATE_DIR' doesn't exist! goodbye."
}

# edit $BLOG_CONF
config_weblog(){
nb_edit "$BLOG_CONF"
# check if file's been modified since opened
[ ! -N "$BLOG_CONF" ] && die "no changes were made! goodbye."
deconfig; load_config
}

