# NanoBlogger plugin to render Markdown format entries
# Markdown is documented and implemented at
#   <URL:http://daringfireball.net/projects/markdown/>

: ${MARKDOWN_CMD:=markdown}
: ${MARKDOWN_OPTS:= }

echo test |eval $MARKDOWN_CMD > "$SCRATCH_FILE".plugin_devnull 2>&1 &&
	MARKDOWN_INPATH=true
	
if [ "$MARKDOWN_INPATH" = "true" ]; then
	# nb_msg "$plugins_entryfilteraction `basename $nb_plugin` ..."
	NB_EntryBody=$(echo "$NB_EntryBody" | ${MARKDOWN_CMD} ${MARKDOWN_OPTS})
else
	die "$nb_plugin: $plugins_abort"
fi

