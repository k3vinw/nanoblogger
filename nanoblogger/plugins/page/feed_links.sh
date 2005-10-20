# NanoBlogger Page Plugin: Feed links

# Atom 0.3
if [ ! -z "$NB_AtomVer" ]; then
	NB_AtomAltLink=$(
	cat <<-EOF
		<link rel="alternate" type="application/atom+xml"
			title="Atom $NB_AtomVer"
			href="${BASE_URL}$NB_AtomFile"
		/>
	EOF
	)
fi

# update category info
if [ ! -z "$cat_arch" ] && [ "$cat_arch" != "$fdlinksprev_cat_arch" ]; then
	set_catlink "$cat_arch"
fi
fdlinksprev_cat_arch="$cat_arch"

# RSS 2.0
if [ ! -z "$NB_RSS2Ver" ]; then
	if [ "$MKPAGE_TEMPLATE" = "$NB_TEMPLATE_DIR/$CATEGORY_TEMPLATE" ]; then
		NB_RSS2CatFile=`echo "$category_file" |sed -e 's/[\.]'$NB_FILETYPE'/-rss.'$NB_SYND_FILETYPE'/g'`
		NB_RSS2Link="${ARCHIVES_PATH}$NB_RSS2CatFile"
		NB_RSS2Title="RSS $NB_RSS2Ver: $NB_ArchiveTitle"
	else
		NB_RSS2Link="${BASE_URL}rss.$NB_SYND_FILETYPE"
		NB_RSS2Title="RSS $NB_RSS2Ver"
	fi
	NB_RSS2AltLink=$(
	cat <<-EOF
		<link rel="alternate" type="application/rss+xml"
			title="$NB_RSS2Title"
			href="$NB_RSS2Link"
		/>
	EOF
	)
fi

# RSS 1.0
if [ ! -z "$NB_RSSVer" ]; then
	if [ "$MKPAGE_TEMPLATE" = "$NB_TEMPLATE_DIR/$CATEGORY_TEMPLATE" ]; then
		NB_RSSCatFile=`chg_suffix "$category_file" $NB_SYND_FILETYPE`
		NB_RSSLink="${ARCHIVES_PATH}$NB_RSSCatFile"
		NB_RSSTitle="RSS $NB_RSSVer: $NB_ArchiveTitle"
	else
		NB_RSSLink="${BASE_URL}index.$NB_SYND_FILETYPE"
		NB_RSSTitle="RSS $NB_RSSVer"
	fi
	NB_RSSAltLink=$(
	cat <<-EOF
		<link rel="alternate" type="application/rss+xml"
			title="$NB_RSSTitle"
			href="$NB_RSSLink"
		/>
	EOF
	)
fi

