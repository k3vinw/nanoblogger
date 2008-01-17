# NanoBlogger plugin to render Markdown format entries
# Markdown is documented and implemented at
#   <URL:http://daringfireball.net/projects/markdown/>

MARKDOWN="/usr/bin/markdown"
MARKDOWN_OPTS=""

# nb_msg "$plugins_entryfilteraction `basename $nb_plugin` ..."
NB_EntryBody=$(echo "$NB_EntryBody" | ${MARKDOWN} ${MARKDOWN_OPTS})

