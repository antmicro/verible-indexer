#!/bin/bash
# Copyright (c) 2020 Antmicro <https://www.antmicro.com>

SELF_DIR="$(dirname $(readlink -f ${BASH_SOURCE[0]}))"

. $SELF_DIR/common.inc.sh

STATIC_DIR=$(readlink -f "$SELF_DIR/static")
BAZEL_ROOT="$(readlink -f "$OUT_DIR/bazel_cache")"
mkdir -p "$BAZEL_ROOT"

KYTHE_DIR="$(readlink -f kythe-bin)"
KYTHE_SRC_DIR="$(readlink -f ./kythe-src/kythe*/)"
BAZEL="bazel --output_user_root=$BAZEL_ROOT"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Build static http_server

begin_command_group 'Build Kythe http_server'
	cd $KYTHE_SRC_DIR
	$BAZEL build \
			-c opt \
			--@io_bazel_rules_go//go/config:static \
			//kythe/go/serving/tools:http_server

	mkdir -p $ARTIFACTS_DIR/bin
	cp ./bazel-bin/kythe/go/serving/tools/http_server/http_server $ARTIFACTS_DIR/bin/

	cd - > /dev/null
end_command_group

#─────────────────────────────────────────────────────────────────────────────
# Build verible-verilog-kythe-extractor

begin_command_group 'Build verible-verilog-kythe-extractor'
	cd verible
	$BAZEL clean
	$BAZEL build //verilog/tools/kythe:verible-verilog-kythe-extractor
	cd - > /dev/null
end_command_group

VERIBLE_VERILOG_KYTHE_EXTRACTOR="$(readlink -f "./verible/bazel-bin/verilog/tools/kythe/verible-verilog-kythe-extractor")"

#─────────────────────────────────────────────────────────────────────────────
# Scan and index Ibex sources

IBEX_CORE_NAME='lowrisc:ibex:ibex_top_tracing'

function log_indexer_warnings() {
	if [[ -n "${GITHUB_WORKFLOW:-}" ]]; then
		local _lines=""
		while read -r line; do
			if [[ -n "$line" ]]; then
				_lines="${_lines}%0A${line}"
			fi
		done
		if [[ -n "$_lines" ]]; then
			printf '::warning file=%s,line=%d::verible-verilog-kythe-extractor:%s\n' \
					"${BASH_SOURCE[1]}" "${BASH_LINENO[0]}" "$_lines" >&2
		fi
	else
		cat >&2
	fi
}

function get_file_size() { du -bs "$1" | cut -f1; }

begin_command_group 'Index Ibex source code'
	cd ibex

	file_args=$($SELF_DIR/ibex_extractor_args "$IBEX_CORE_NAME")
	log_cmd $VERIBLE_VERILOG_KYTHE_EXTRACTOR \
			--print_kythe_facts json \
			$file_args \
			> "$OUT_DIR/entries" \
			2> >(log_indexer_warnings)
	log_cmd ls -l "$OUT_DIR/entries"

	entries_size=$(get_file_size $OUT_DIR/entries)
	# At the moment of writing this, correct 'entries' file size was about 23MiB. 1MB seems to be a good error threshold.
	entries_min_expected_size=1000000
	if (( ${entries_size:-0} < $entries_min_expected_size )); then
		fatal_error "Generated 'entries' file is smaller than expected ($entries_size < $entries_min_expected_size)"
	fi

	cd - > /dev/null
end_command_group

#─────────────────────────────────────────────────────────────────────────────
# Create tables

begin_command_group 'Create graphstore'
	$KYTHE_DIR/tools/entrystream \
			--read_format=json \
			< "$OUT_DIR/entries" \
		| $KYTHE_DIR/tools/write_entries \
			-graphstore "$OUT_DIR/graphstore"
	log_cmd ls -l "$OUT_DIR/graphstore/"
end_command_group

begin_command_group 'Create tables'
	$KYTHE_DIR/tools/write_tables \
			-graphstore "$OUT_DIR/graphstore" \
			-out "$ARTIFACTS_DIR/tables"
	log_cmd ls -l "$ARTIFACTS_DIR/tables"

	tables_size=$(get_file_size $ARTIFACTS_DIR/tables)
	# At the moment of writing this, total size of generated table files was 29MiB. 2MB seems to be a good error threshold.
	tables_min_expected_size=2000000
	if (( ${tables_size:-0} < $tables_min_expected_size )); then
		fatal_error "Generated tables are smaller than expected ($tables_size < $tables_min_expected_size)"
	fi

end_command_group

#─────────────────────────────────────────────────────────────────────────────
# Copy static files to artifacts directory

begin_command_group 'Copy static files'
	cp -R $STATIC_DIR/* $ARTIFACTS_DIR/
end_command_group

