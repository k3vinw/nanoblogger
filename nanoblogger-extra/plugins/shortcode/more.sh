# NanoBlogger More Shortcode Plugin
# converts [more] to <!--more-->
# works in conjunction with entry excerpts plugin
#
# e.g. [more] -> <!--more-->

# quickly detect moretag shortcode
shortcode_moretag_specified="${NB_MetaBody//*[\[]more[\]]*/true}"

if [ "$shortcode_moretag_specified" = true ]; then
	shortcode_moretag_output=; shortcode_moretag_sedscript=
	# don't change BASE_URL of entries
	[ ! -z "$weblogpage_plugin" ] && set_moretag "" "$BLOGPAGE_OUTFILE"
	shortcode_moretag_output="<\!--more-->"
	shortcode_moretag_sedscript='s/\[more\]/'$shortcode_moretag_output'/g'
	NB_MetaBody=`echo "$NB_MetaBody" |sed -e "$shortcode_moretag_sedscript"`

fi

