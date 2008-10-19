# NanoBlogger Base-URL Shortcode  Plugin
# converts [base-url] to relative path
#
# e.g. [base-url] -> "./" or "../"

# quickly detect baseurl shortcode
oldscode_baseurl_specified="${NB_MetaBody//*[\%]base\_url[\%]*/true}"
shortcode_baseurl_specified="${NB_MetaBody//*[\[]base?url[\]]*/true}"

# old shortocode for base-url
# e.g. %base_url% -> "./" or "../"
oldsc_baseurl_specified(){
if [ "$oldscode_baseurl_specified" = true ]; then
	set_baseurl "" "$BLOGPAGE_OUTFILE"
	baseurl_link="${BASE_URL//\//\\/}"
	sc_lines=`echo "$NB_MetaBody" |grep -n "\%base\_url\%" |sed -e '/[ ]/ s//_SHORTCODESPACER_/g'`
	sc_idlist=(`for sc_line in ${sc_lines[@]}; do echo ${sc_line%%\:*}; done`)
	shortcode_baseurl_data=`echo "$NB_MetaBody" |sed -e '/\%base\_url\%/!d; /[ ]/ s//_SHORTCODESPACER_/g'`
	sc_lineid=0
	for shortcode_baseurl_line in ${shortcode_baseurl_data[@]}; do
		shortcode_baseurl_output=; shortcode_baseurl_sedscript=
		shortcode_baseurl_line="${shortcode_baseurl_line//_SHORTCODESPACER_/ }"
		sc_id="${sc_idlist[$sc_lineid]}"
		shortcode_baseurl_output="$baseurl_link"
		shortcode_baseurl_sedscript=''$sc_id' s/\%base\_url\%/'$shortcode_baseurl_output'/'
		NB_MetaBody=`echo "$NB_MetaBody" |sed -e "$shortcode_baseurl_sedscript"`
		let sc_lineid=${sc_lineid}+1
	done
fi
}

# shortocode for base-url
sc_baseurl_specified(){
if [ "$shortcode_baseurl_specified" = true ]; then
	set_baseurl "" "$BLOGPAGE_OUTFILE"
	baseurl_link="${BASE_URL//\//\\/}"
	sc_lines=`echo "$NB_MetaBody" |grep -n "\[base.url\]" |sed -e '/[ ]/ s//_SHORTCODESPACER_/g'`
	sc_idlist=(`for sc_line in ${sc_lines[@]}; do echo ${sc_line%%\:*}; done`)
	shortcode_baseurl_data=`echo "$NB_MetaBody" |sed -e '/\[base.url\]/!d; /[ ]/ s//_SHORTCODESPACER_/g'`
	sc_lineid=0
	for shortcode_baseurl_line in ${shortcode_baseurl_data[@]}; do
		shortcode_baseurl_output=; shortcode_baseurl_sedscript=
		shortcode_baseurl_line="${shortcode_baseurl_line//_SHORTCODESPACER_/ }"
		sc_id="${sc_idlist[$sc_lineid]}"
		shortcode_baseurl_output="$baseurl_link"
		shortcode_baseurl_sedscript=''$sc_id' s/\[base.url\]/'$shortcode_baseurl_output'/'
		NB_MetaBody=`echo "$NB_MetaBody" |sed -e "$shortcode_baseurl_sedscript"`
		let sc_lineid=${sc_lineid}+1
	done
fi
}

for sc_baseurl in oldsc_baseurl_specified sc_baseurl_specified; do
	$sc_baseurl
done
