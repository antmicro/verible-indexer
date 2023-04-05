#!/bin/bash
# Copyright (c) 2020 Antmicro <https://www.antmicro.com>

# Expected environment:
# - SELF_DIR - path to toplevel directory

declare -A DEPENDENCIES=(
	# Value syntax: GIT_URL<whitespace>BRANCH
	[verible]='https://github.com/chipsalliance/verible.git master'
	[ibex]='https://github.com/lowRISC/ibex.git master'
	[VeeR_EL2]='https://github.com/antmicro/Cores-VeeR-EL2.git main'
	[caliptra_rtl]='https://github.com/chipsalliance/caliptra-rtl.git main'
)

DEPS_REVISIONS_FILE="$SELF_DIR/deps-revisions.txt"

declare -A DEPS_REVISIONS=()
while read -r name rev; do
	if [[ -n "$rev" ]]; then
		DEPS_REVISIONS["$name"]="$rev"
	fi
done < $DEPS_REVISIONS_FILE
