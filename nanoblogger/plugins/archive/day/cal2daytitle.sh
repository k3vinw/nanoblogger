# NanoBlogger Day Archive Title Plugin, requires the cal command.
# uses cal to print a fancy title for the daily archives
#
# replaces $NB_ArchiveTitle

: ${CAL_CMD:=cal}

if $CAL_CMD > "$SCRATCH_FILE.caltest" 2>&1 ; then
	cal_year=`echo $month |cut -c1-4`
	cal_month=`echo $month |cut -c6-7`

	[ ! -z "$DATE_LOCALE" ] && CALENDAR=`LC_ALL="$DATE_LOCALE" $CAL_CMD $CAL_ARGS "$cal_month" "$cal_year"`
	[ -z "$DATE_LOCALE" ] && CALENDAR=`$CAL_CMD $CAL_ARGS "$cal_month" "$cal_year"`
	CAL_HEAD=`echo "$CALENDAR" |sed -e '/^[ ]*/ s///g; 1q'`

	# make NB_ArchiveTitle pretty
	DayMonthTitle=`echo "$CAL_HEAD" |sed -e '/'$yearn'/ s///g'`
	NB_ArchiveTitle="$DayMonthTitle $dayn, $yearn"
	CALENDAR=
fi
