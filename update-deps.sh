#!/bin/bash
# Copyright (c) 2020 Antmicro <https://www.antmicro.com>

SELF_DIR="$(dirname $(readlink -f ${BASH_SOURCE[0]}))"

. $SELF_DIR/common.inc.sh
. $SELF_DIR/deps.inc.sh

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -A new_deps_revisions=()

dir="$PWD"
for name in "${!DEPENDENCIES[@]}"; do
	cd $dir
	read url branch <<< "${DEPENDENCIES[$name]}"

	git clone --depth=1 -b "$branch" "$url" "$name" || continue
	cd "$name"
	rev="$(git rev-parse "$branch")" || continue
	if [[ "${DEPS_REVISIONS[$name]:-}" != "$rev" ]]; then
		new_deps_revisions["$name"]="$rev"
	fi
	cd -
done

if [[ "${#new_deps_revisions[@]}" -gt 0 ]]; then
	new_deps_revisions_file="$(mktemp -q)"
	for name in "${!DEPENDENCIES[@]}"; do
		printf '%s\t%s\n' \
				"$name" \
				"${new_deps_revisions[$name]:-${DEPS_REVISIONS[$name]}}" \
				>> "$new_deps_revisions_file"
	done
	mv "$new_deps_revisions_file" "$DEPS_REVISIONS_FILE"
fi
