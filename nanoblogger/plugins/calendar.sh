# NanoBlogger Calendar Plugin, requires the cal command.
# converts the output of cal to an HTML Table and creates links of entries
#
# sample code for template - based off default stylesheet
#
# <div class="side">
# $NB_Calendar
# </div>

PLUGIN_OUTFILE="$BLOG_DIR/$PARTS_DIR/cal.htm"

if cal > "$PLUGIN_OUTFILE" 2>&1 ; then

	CALENDAR=`cal`
	CAL_HEAD=`echo "$CALENDAR" |sed -n 1p |sed -e 's/^[ ]*//g'`
	WEEK_DAYS=`echo "$CALENDAR" |sed -n 2p`
	DAYS=`echo "$CALENDAR" |sed 1,2d`
	NUM_DAY_LINES=`echo "$DAYS" |grep -n "" |cut -c1`

	curr_month=`date +%m`
	query_db all
	MONTH_LIST=`echo "$DB_RESULTS" |sort -r |grep '[-]'$curr_month'[-]'`

	html_nbsp="&nbsp;"

	echo '<table border="0" cellspacing="4" cellpadding="0">' > "$PLUGIN_OUTFILE"
	echo '<caption>'$CAL_HEAD'</caption>' >> "$PLUGIN_OUTFILE"
	echo '<tr>' >> "$PLUGIN_OUTFILE"
	for wd in $WEEK_DAYS ; do
		echo '<th align="center"><span class="calendar">'$wd'</span></th>' >> "$PLUGIN_OUTFILE"
	done
	echo '</tr>' >> "$PLUGIN_OUTFILE"
	for line in $NUM_DAY_LINES ; do
		DN_LINES=`echo "$DAYS" |sed -n "$line"p`
		echo '<tr>' >> "$PLUGIN_OUTFILE"
		echo "$DN_LINES" | sed 's/  [ \t]/<td align="center"><span class="calendar">\'$html_nbsp'\<\/span><\/td>\ /g; s/[0-9]//g' >> "$PLUGIN_OUTFILE"
		for dn in $DN_LINES ; do
			set_link="0"
			MONTH_LINE=`echo "$MONTH_LIST" |grep $dn`
			for entry in $MONTH_LINE ; do
				NB_EntryID=`echo "$entry" |sed -e 's/\_/\:/g; s/[\.]htm//g'`"$BLOG_TZD"
				entry_year=`echo $entry |cut -c1-4`
				entry_month=`echo $entry |cut -c6-7`
				entry_day=`echo $entry |cut -c9-10 |sed -e 's/^0//g'`
				curr_month=`date +%m`
				curr_year=`date +%Y`
			if [ "$curr_year-$curr_month-$dn" = "$entry_year-$entry_month-$entry_day" ] ; then
				set_link="1"
				if [ "$FULL_PERMALINKS" = "1" ] ; then
					permalink_entry=`chg_suffix $entry`
					dn='<a href="'$BLOG_URL'/'$PERMALINKS'/'$permalink_entry'">'$dn'</a>'
				else
					dn='<a href="'$BLOG_URL'/'$ARCHIVES'/'$FILE_BY_DIR'/'$entry_year-$entry_month'.html#'$NB_EntryID'">'$dn'</a>'
				fi
				echo '<td align="center"><span>'$dn'</span></td>' >> "$PLUGIN_OUTFILE"
			fi
			done
			if [ "$set_link" != "1" ] ; then
				echo '<td align="center"><span>'$dn'</span></td>' >> "$PLUGIN_OUTFILE"
			fi
		done
		echo '</tr>' >> "$PLUGIN_OUTFILE"
	done
	echo '</table>' >> "$PLUGIN_OUTFILE"

	# The calendar's place-holder for the templates
	NB_Calendar=`cat "$PLUGIN_OUTFILE"`
fi
