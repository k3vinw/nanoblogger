# Module for error handling

# function to die with a message
die(){
cat <<-EOF
	$@
EOF
exit 1
}

nb_msg(){
if [ "$VERBOSE" != 0 ]; then
	cat <<-EOF
		$@
	EOF
fi
}

