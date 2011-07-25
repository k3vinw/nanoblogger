# NanoBlogger More Shortcode Plugin
# converts [more] to <!--more-->
# helps to create excerpts by working in conjunction with entry excerpts plugin
#
# e.g. [more] = <!--more-->

# quickly detect moretag shortcode
shortcode_moretag_specified="${NB_MetaBody//*[\[]more[\]]*/true}"

if [ "$shortcode_moretag_specified" = true ]; then
	shortcode_moretag_output=; shortcode_moretag_sedscript=
	shortcode_moretag_output="<\!--more-->"
	shortcode_moretag_sedscript='s/\[more\]/'$shortcode_moretag_output'/g'
	NB_MetaBody=`echo "$NB_MetaBody" |sed -e "$shortcode_moretag_sedscript"`
fi

