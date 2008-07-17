# NanoBlogger plugin to filter page content through markdown
# Markdown is documented and implemented at
#   <URL:http://daringfireball.net/projects/markdown/>

: ${MARKDOWN_CMD:=markdown}
: ${MARKDOWN_OPTS:= }

eval $MARKDOWN_CMD > "$SCRATCH_FILE".plugin_devnull 2>&1 &&
	MARKDOWN_INPATH=true

if [ "$MARKDOWN_INPATH" = "true" ]; then
	nb_msg "$plugins_entryfilteraction `basename $nb_plugin` ..."
	MKPAGE_CONTENT=`echo "$MKPAGE_CONTENT" | ${MARKDOWN_CMD} ${MARKDOWN_OPTS}`
fi

