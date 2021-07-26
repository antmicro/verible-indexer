#!/bin/bash
# Copyright (c) 2020 Antmicro <https://www.antmicro.com>

SELF_DIR="$(dirname $(readlink -f ${BASH_SOURCE[0]}))"

. $SELF_DIR/common.inc.sh
. $SELF_DIR/deps.inc.sh

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Get Kythe binaries

KYTHE_VERSION='v0.0.48'
KYTHE_URL="https://github.com/kythe/kythe/releases/download/$KYTHE_VERSION/kythe-$KYTHE_VERSION.tar.gz"

begin_command_group 'Get Kythe'
	wget --no-verbose -O kythe.tar.gz "$KYTHE_URL"
	rm -rf kythe-bin
	mkdir kythe-bin
	tar -xzf kythe.tar.gz --strip-components=1 -C kythe-bin
end_command_group

#─────────────────────────────────────────────────────────────────────────────
# Get Kythe sources.

KYTHE_SRC_URL="https://github.com/kythe/kythe/archive/$KYTHE_VERSION.zip"

begin_command_group 'Get Kythe sources'
	wget --no-verbose -O kythe-src.zip "$KYTHE_SRC_URL"
	rm -rf kythe-src
	mkdir kythe-src
	unzip -q kythe-src.zip -d ./kythe-src
end_command_group

#─────────────────────────────────────────────────────────────────────────────
# Get Verible sources

begin_command_group 'Get Verible sources'
	read url branch <<< "${DEPENDENCIES[verible]}"
	git clone -n -b "$branch" "$url" verible
	rev="${DEPS_REVISIONS[verible]:-}"
	if [[ -n "$rev" ]]; then
		cd verible
		git checkout "$rev"
		cd -
	fi
end_command_group

#─────────────────────────────────────────────────────────────────────────────
# Get Ibex sources

begin_command_group 'Get Ibex sources'
	read url branch <<< "${DEPENDENCIES[ibex]}"
	git clone -n -b "$branch" "$url" ibex
	rev="${DEPS_REVISIONS[ibex]:-}"
	cd ibex
	if [[ -n "$rev" ]]; then
		git checkout "$rev"
	fi
	pip3 install wheel
	pip3 install -r python-requirements.txt
	cd -
end_command_group

