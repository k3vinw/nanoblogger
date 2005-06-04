# NanoBlogger Auto-format plugin to convert %base_url% to relative path
# e.g. %base_url% = "./" or "../"

if [ "$AUTO_FORMAT" = 1 ]; then
	base_url=`echo "$BASE_URL" |sed -e '/[\/\]/ s//\\\\\//g'`
	sed_script='/\%base_url\%/ s//'$base_url'/g'
	NB_EntryBody=`echo "$NB_EntryBody" |sed -e "$sed_script"`
fi
