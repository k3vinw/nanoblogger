# Module for error handling
# Last modified: 2010-02-21T16:16:15-05:00

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
#FIXME: doh! why so hard to quite eval??
nb_eval(){
	if [ "$VERBOSE" != 0 ]; then
		eval "$@" # verbose eval
	else
		eval "$@" # verbose eval
	fi
	return $?
}

