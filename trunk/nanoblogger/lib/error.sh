# Module for error handling
# Last modified: 2010-02-20T13:06:38-05:00

# function that immitate perl's die command
die(){
cat <<-EOF
	$@
EOF
exit 1
}

# function wrapper to echo
nb_msg(){
cat <<-EOF
	$@
EOF
}

# function wrapper to eval
nb_eval(){
	if [ "$VERBOSE" != 0 ]; then
		eval "$@" # verbose eval
	else
		FAKE_DEVNULL=`eval "$@" 2>&1`
	fi
	return $?
}

