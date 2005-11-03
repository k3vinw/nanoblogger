# NanoBlogger plugin to filter page content through markdown
# Markdown is documented and implemented at
#   <URL:http://daringfireball.net/projects/markdown/>

MARKDOWN="/usr/bin/markdown"
MARKDOWN_OPTS=""

# nb_msg "$plugins_textformataction `basename $nb_plugin` ..."
MKPAGE_CONTENT=`echo "$MKPAGE_CONTENT" | ${MARKDOWN} ${MARKDOWN_OPTS}`

