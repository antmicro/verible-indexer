#!/bin/bash
# Copyright (c) 2020 Antmicro <https://www.antmicro.com>

SELF_DIR="$(dirname $(readlink -f ${BASH_SOURCE[0]}))"

. $SELF_DIR/common.inc.sh
. $SELF_DIR/deps.inc.sh

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -A new_deps_revisions=()

for name in "${!DEPENDENCIES[@]}"; do
	read url branch <<< "${DEPENDENCIES[$name]}"
	read rev ref < <(git ls-remote -q "$url" "$branch") || :
	if [[ -z "$rev" ]]; then
		printf '::warning file=%s,line=%d::Failed to read revision for %s %s\n' \
					"${BASH_SOURCE[0]}" "$LINENO" "$url" "$branch"
		continue
	fi
	if [[ "${DEPS_REVISIONS[$name]:-}" != "$rev" ]]; then
		new_deps_revisions["$name"]="$rev"
	fi
done

if [[ "${#new_deps_revisions[@]}" -gt 0 ]]; then
	if [[ "${GITHUB_ACTIONS:-}" == 'true' ]]; then
		# Get details about changes
		commit_msg="$(mktemp -q)"
		echo "Update revisions" > $commit_msg
		echo "::set-output name=commit-msg::$commit_msg"

		for name in "${!new_deps_revisions[@]}"; do
			old_rev="${DEPS_REVISIONS[$name]:-}"
			if [[ -z "${old_rev}" ]]; then
				continue;
			fi
			new_rev="${new_deps_revisions[$name]}"
			read url branch <<< "${DEPENDENCIES[$name]}"
			git clone -n "$url" "$name" || continue
			cd "$name"
			echo -e "\n** $name: **\n" >> $commit_msg
			git log --oneline --no-decorate "${old_rev}..${new_rev}" >> $commit_msg || :
			cd -
		done
	fi

	new_deps_revisions_file="$(mktemp -q)"
	for name in "${!DEPENDENCIES[@]}"; do
		printf '%s\t%s\n' \
				"$name" \
				"${new_deps_revisions[$name]:-${DEPS_REVISIONS[$name]}}" \
				>> "$new_deps_revisions_file"
	done
	mv "$new_deps_revisions_file" "$DEPS_REVISIONS_FILE"
fi
