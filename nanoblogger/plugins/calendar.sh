# NanoBlogger Calendar Plugin, requires the cal command.
# converts the output of cal to an HTML Table and creates links of entries
#
# sample code for template - based off default stylesheet
#
# <div class="side">
# $NB_Calendar
# </div>

PLUGIN_OUTFILE="$BLOG_DIR/$PARTS_DIR/cal.$NB_FILETYPE"

: ${CAL_CMD:=cal}

if $CAL_CMD > "$PLUGIN_OUTFILE" 2>&1 ; then
	nb_msg "generating calendar ..."
	[ -z "$DATE_LOCALE" ] || CALENDAR=`LC_ALL="$DATE_LOCALE" $CAL_CMD $CAL_ARGS`
	[ ! -z "$CALENDAR" ] || CALENDAR=`$CAL_CMD $CAL_ARGS`
	CAL_HEAD=`echo "$CALENDAR" |sed -e '/^[ ]*/ s///g; 1q'`
	WEEK_DAYS=`echo "$CALENDAR" |sed -n 2p`
	DAYS=`echo "$CALENDAR" |sed 1,2d`
	NUM_DAY_LINES=`echo "$DAYS" |grep -n "." |cut -c1`

	curr_month=`date +%m`
	query_db all
	MONTH_LIST=`echo "$DB_RESULTS" |sort -r |grep '[-]'$curr_month'[-]'`

	echo '<table border="0" cellspacing="4" cellpadding="0" summary="Calendar with links to days with entries">' > "$PLUGIN_OUTFILE"
	echo '<caption class="calendarhead">'$CAL_HEAD'</caption>' >> "$PLUGIN_OUTFILE"
	echo '<tr>' >> "$PLUGIN_OUTFILE"
	for wd in $WEEK_DAYS ; do
		echo '<th style="text-align: center;"><span class="calendarday">'$wd'</span></th>' >> "$PLUGIN_OUTFILE"
	done
	echo '</tr>' >> "$PLUGIN_OUTFILE"
	for line in $NUM_DAY_LINES ; do
		DN_LINES=`echo "$DAYS" |sed -n "$line"p`
		echo '<tr>' >> "$PLUGIN_OUTFILE"
		echo "$DN_LINES" | sed -e '/  [ \t]/ s//<td style="text-align: center;"><\/td>\ /g; /[0-9]/ s///g' >> "$PLUGIN_OUTFILE"
		for dn in $DN_LINES ; do
			set_link=0
			MONTH_LINE=`echo "$MONTH_LIST" |grep $dn`
			for entry in $MONTH_LINE ; do
				entry_year=`echo $entry |cut -c1-4`
				NB_EntryID="$x_id$entry"
				entry_month=`echo $entry |cut -c6-7`
				entry_day=`echo $entry |cut -c9-10 |sed -e '/^0/ s///g'`
				curr_month=`date +%m`
				curr_year=`date +%Y`
			if [ "$curr_year-$curr_month-$dn" = "$entry_year-$entry_month-$entry_day" ] ; then
				set_link=1
				dn='<a href="'\${ARCHIVES_PATH}$entry_year-$entry_month'.'$NB_FILETYPE'#'$NB_EntryID'">'$dn'</a>'
				echo '<td style="text-align: center;"><span class="calendar">'$dn'</span></td>' >> "$PLUGIN_OUTFILE"
			fi
			done
			if [ "$set_link" != 1 ] ; then
				echo '<td style="text-align: center;"><span class="calendar">'$dn'</span></td>' >> "$PLUGIN_OUTFILE"
			fi
		done
		echo '</tr>' >> "$PLUGIN_OUTFILE"
	done
	echo '</table>' >> "$PLUGIN_OUTFILE"

	# The calendar's place-holder for the templates
	NB_Calendar=$(< "$PLUGIN_OUTFILE")
	load_template "$PLUGIN_OUTFILE"
	echo "$BLOG_HTML" > "$PLUGIN_OUTFILE"
fi
