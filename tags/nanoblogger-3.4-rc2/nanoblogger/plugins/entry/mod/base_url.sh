# NanoBlogger plugin to convert %base_url% to relative path
# e.g. %base_url% -> "./" or "../"

base_url="${BASE_URL//\//\\/}"
sed_script='/\%base_url\%/ s//'$base_url'/g'
NB_EntryBody=`echo "$NB_EntryBody" |sed -e "$sed_script"`

