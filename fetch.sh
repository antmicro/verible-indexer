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
# Get IP Core sources

for IP_CORE in "${IP_CORES[@]}"; do
	begin_command_group 'Get '$IP_CORE' sources'
		read url branch <<< "${DEPENDENCIES[$IP_CORE]}"
		printf "::info CORE   = %q\n" $IP_CORE >&2
		printf "::info URL    = %q\n" $url >&2
		printf "::info BRANCH = %q\n" $branch >&2
		git clone -n -b "$branch" "$url" $IP_CORE
		rev="${DEPS_REVISIONS[$IP_CORE]:-}"
		printf "::info REV    = %q\n" $rev >&2
		pushd $IP_CORE > /dev/null
		if [[ -n "$rev" ]]; then
			git checkout "$rev"
		fi
		if [[ "$IP_CORE" == "ibex" ]]; then
			pip3 install wheel
			pip3 install -r python-requirements.txt
		elif [[ "$IP_CORE" == "VeeR_EL2" ]]; then
			export RV_ROOT=$(pwd)
			configs/veer.config
		fi
		popd > /dev/null
	end_command_group
done