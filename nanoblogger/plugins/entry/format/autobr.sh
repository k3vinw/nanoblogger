# NanoBlogger Auto br plugin to convert line breaks to HTML
# 2 line breaks (blank line) = <br /><br />
 
NB_EntryBody=`echo "$NB_EntryBody" |sed -e '/^$/ s//\<br \/\>\<br \/\>/g'`

