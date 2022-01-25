#!/usr/bin/env bash

chap print_header "$0 $*"

chap info_msg "Hello there."
chap nominal_msg "This checks out."
chap attention_msg "One developer to another, you should check my work."
chap warning_msg "Oh, that's not right."
chap mod_msg "We're changing things."
echo ""
chap info_cmd "ls -al" "chap's source code"
echo ""
chap confirm_cmd "touch deleteme; rm -v deleteme" "Create and delete a file?"