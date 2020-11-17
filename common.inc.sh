#!/bin/bash
# Copyright (c) 2020 Antmicro <https://www.antmicro.com>

# Expected environment:
# - SELF_DIR - path to toplevel directory

set -e -u -o pipefail
shopt -s nullglob
shopt -s extglob

script_error() {
	local _file="$1"
	local _lineno="$2"
	local _msg="$3"
	local _command="$4"
	local _cmdlines=()

	while read line; do
		_cmdlines+=("$line")
	done <<< "$_command"

	if [[ -t 2 ]]; then
		printf '\033[0;1m%s:%d: \033[31merror:\033[0m %s:\n' "$_file" "$_lineno" "$_msg"
	else
		printf '%s:%d: error: %s:\n' "$_file" "$_lineno" "$_msg"
	fi
	printf '\t%s\n' "${_cmdlines[@]}" >&2
	printf '\n' >&2

	if [[ -n "${GITHUB_WORKFLOW:-}" ]]; then
		printf '::error file=%s,line=%d::%s\n' "$_file" "$_lineno" "$_msg" >&2
	fi
}

set -E -o functrace
script_error_handler() {
	local _command="${1:-?}"
	local _exit_status="${2:-0}"

	if [[ $_exit_status -eq 0 ]]; then
		return 0
	fi

	script_error \
		"${BASH_SOURCE[1]}" "${BASH_LINENO[0]}" \
		"Command terminated with status ${_exit_status}" \
		"$_command"

	exit $_exit_status
}
trap 'script_error_handler "$BASH_COMMAND" "$?"' ERR


function begin_command_group() {
	if [[ -n "${GITHUB_WORKFLOW:-}" ]]; then
		echo "::group::$*"
	else
		echo -e "\n\033[1;92mRunning step: $1\033[0m\n"
	fi
}

function end_command_group() {
	if [[ -n "${GITHUB_WORKFLOW:-}" ]]; then
		echo "::endgroup::"
	fi
}

#─────────────────────────────────────────────────────────────────────────────

BUILD_DIR=$SELF_DIR/_build
mkdir -p "$BUILD_DIR"
OUT_DIR="$(readlink -f "$BUILD_DIR/output")"
mkdir -p "$OUT_DIR"
ARTIFACTS_DIR="$(readlink -f "$OUT_DIR/artifacts")"
mkdir -p "$ARTIFACTS_DIR"

cd $BUILD_DIR

