#!/bin/bash
# Copyright (c) 2020 Antmicro <https://www.antmicro.com>

# Expected environment:
# - SELF_DIR - path to toplevel directory

set -e -u -o pipefail
shopt -s nullglob
shopt -s extglob

# For logging in contexts with redirected output
exec 3>&2

script_error() {
	local _file="$1"
	local _lineno="$2"
	local _msg="$3"
	local _command="${4:-}"
	local _cmdlines=()

	if [[ -n "$_command" ]]; then
		while read line; do
			_cmdlines+=("$line")
		done <<< "$_command"
	fi

	if [[ -t 2 ]]; then
		printf '\033[0;1m%s:%d: \033[31merror:\033[0m %s:\n' "$_file" "$_lineno" "$_msg"
	else
		printf '%s:%d: error: %s:\n' "$_file" "$_lineno" "$_msg"
	fi
	if [[ -n "$_command" ]]; then
		printf '\t%s\n' "${_cmdlines[@]}" >&3
		printf '\n' >&3
	fi

	if [[ -n "${GITHUB_WORKFLOW:-}" ]]; then
		printf '::error file=%s,line=%d::%s\n' "$_file" "$_lineno" "$_msg" >&3
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

function fatal_error() {
	script_error \
		"${BASH_SOURCE[1]}" "${BASH_LINENO[0]}" \
		"$*"
	exit 1
}

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

function log_cmd() {
	printf '\x1b[32;1m#' >&3
	printf ' %q' "$@" >&3
	printf '\x1b[0m\n' >&3
	"$@"
}

#─────────────────────────────────────────────────────────────────────────────

declare -A DEPENDENCIES=(
	# Value syntax: GIT_URL<whitespace>BRANCH
	[verible]='https://github.com/google/verible.git master'
	[ibex]='https://github.com/lowRISC/ibex.git master'
)

DEPS_REVISIONS_FILE="$SELF_DIR/deps-revisions.txt"

#─────────────────────────────────────────────────────────────────────────────

BUILD_DIR=$SELF_DIR/_build
mkdir -p "$BUILD_DIR"
OUT_DIR="$(readlink -f "$BUILD_DIR/output")"
mkdir -p "$OUT_DIR"
ARTIFACTS_DIR="$(readlink -f "$OUT_DIR/artifacts")"
mkdir -p "$ARTIFACTS_DIR"

cd $BUILD_DIR
