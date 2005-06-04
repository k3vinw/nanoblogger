# NanoBlogger Monthly Calendar Plugin, requires the cal command.
# converts the output of cal to an HTML Table and creates links of entries
#
# sample code for template - based off default stylesheet
#
# <div class="side">
# $NB_Monthly_Calendar
# </div>

PLUGIN_OUTFILE="$BLOG_DIR/$PARTS_DIR/$month_dir/cal.$NB_FILETYPE"
: ${CAL_CMD:=cal}

mkdir -p `dirname "$PLUGIN_OUTFILE"`
if $CAL_CMD > "$PLUGIN_OUTFILE" 2>&1 ; then
nb_msg "generating monthly weblog calendar ..."
cal_year=`echo $month |cut -c1-4`
cal_month=`echo $month |cut -c6-7`

[ ! -z "$DATE_LOCALE" ] && CALENDAR=`LC_ALL="$DATE_LOCALE" $CAL_CMD $CAL_ARGS "$cal_month" "$cal_year"`
[ -z "$DATE_LOCALE" ] && CALENDAR=`$CAL_CMD $CAL_ARGS "$cal_month" "$cal_year"`
CAL_HEAD=`echo "$CALENDAR" |sed -e '/^[ ]*/ s///g; 1q'`
WEEK_DAYS=`echo "$CALENDAR" |sed -n 2p`
DAYS=`echo "$CALENDAR" |sed 1,2d`
NUM_DAY_LINES=`echo "$DAYS" |grep -n "." |cut -c1`

query_db all
MONTH_LIST=`echo "$DB_RESULTS" |grep '[-]'$cal_month'[-]'`

echo '<table border="0" cellspacing="4" cellpadding="0" summary="Calendar with links to days with entries">' > "$PLUGIN_OUTFILE"
echo '<caption class="calendarhead">'$CAL_HEAD'</caption>' >> "$PLUGIN_OUTFILE"
echo '<tr>' >> "$PLUGIN_OUTFILE"
for wd in $WEEK_DAYS ; do
	echo '<th style="text-align:center;"><span class="calendarday">'$wd'</span></th>' >> "$PLUGIN_OUTFILE"
done
echo '</tr>' >> "$PLUGIN_OUTFILE"
for line in $NUM_DAY_LINES ; do
	DN_LINES=`echo "$DAYS" |sed -n "$line"p`
	echo '<tr>' >> "$PLUGIN_OUTFILE"
	echo "$DN_LINES" | sed -e '/  [ \t]/ s//<td style="text-align:center"><\/td>\ /g; /[0-9]/ s///g' >> "$PLUGIN_OUTFILE"
	for dn in $DN_LINES ; do
		set_link=0
		MONTH_LINE=`echo "$MONTH_LIST" |grep $dn`
		for entry in $MONTH_LINE ; do
			entry_year=`echo $entry |cut -c1-4`
			entry_month=`echo $entry |cut -c6-7`
			entry_day=`echo $entry |cut -c9-10 |sed -e '/^0/ s///g'`
			if [ "$cal_year$cal_month$dn" = "$entry_year$entry_month$entry_day" ] ; then
				set_link=1
				NB_EntryID=`set_entryid $entry`
				set_entrylink "$entry" altlink
				dn='<a href="'${ARCHIVES_PATH}$NB_EntryPermalink'">'$dn'</a>'
				echo '<td style="text-align:center"><span class="calendar">'$dn'</span></td>' >> "$PLUGIN_OUTFILE"
			fi
		done
		if [ "$set_link" != 1 ] ; then
			echo '<td style="text-align:center"><span class="calendar">'$dn'</span></td>' >> "$PLUGIN_OUTFILE"
		fi
	done
	echo '</tr>' >> "$PLUGIN_OUTFILE"
done
echo '</table>' >> "$PLUGIN_OUTFILE"

# The calendar's place-holder for the templates
NB_MonthlyCalendar=$(< "$PLUGIN_OUTFILE")
# make NB_ArchiveTitle pretty
NB_ArchiveTitle="$CAL_HEAD"
CALENDAR=
fi
