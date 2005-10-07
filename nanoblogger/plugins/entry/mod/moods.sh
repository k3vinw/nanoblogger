# Auto-format plugin that converts mood variables
# to emoticons, controlled by moods.conf file

: ${MOODS_DIR:=$BLOG_DIR/moods}
MOODS_URL="${BASE_URL}moods"

if [ -d "$MOODS_DIR" ]; then
	load_moods(){
	if [ -f "$MOODS_DIR/moods.conf" ]; then
		if [ -z "$mood_lines" ]; then
			mood_lines=`cat "$MOODS_DIR/moods.conf" |sed -e '/^$/d; /[\#\]/d' |grep -n "" |cut -c1-2 |sed -e '/[\:\]/ s///g'`
		fi
		if [ -z "$mood_list" ]; then
			mood_list=`cat "$MOODS_DIR/moods.conf" |sed -e '/^$/d; /^[\#\]/d'`
		fi
		for mood in $mood_lines; do
			mood_line=`echo "$mood_list" |sed -n "$mood"p`
			if [ ! -z "$mood_line" ] ; then
				mood_var=`echo "$mood_line" |cut -d" " -f1 | sed -e '/[\*\]/ s//[*]/'`
				mood_img=`echo "$mood_line" |cut -d" " -f3`
				create_moods
			fi
		done
	fi
	}

	create_moods(){
	mood_url=`echo "$MOODS_URL/$mood_img" |sed -e '/[\/\]/ s//\\\\\//g'`
	sed_sub=' <img src="'$mood_url'" alt="'$mood_var'" \/>'
	sed_script='/[ ]'$mood_var'[ ]/ s// '$sed_sub' /g; /[ ]'$mood_var'$/ s// '$sed_sub'/g; /'$mood_var'[ ]/ s//'$sed_sub' /g'
	NB_EntryBody=`echo "$NB_EntryBody" |sed -e "$sed_script"`
	}

	load_moods
fi

