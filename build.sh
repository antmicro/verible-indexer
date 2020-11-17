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

	cd -
end_command_group

#─────────────────────────────────────────────────────────────────────────────
# Build verible-verilog-kythe-extractor

begin_command_group 'Build verible-verilog-kythe-extractor'
	cd verible
	$BAZEL clean
	$BAZEL build //verilog/tools/kythe:verible-verilog-kythe-extractor
	cd -
end_command_group

VERIBLE_VERILOG_KYTHE_EXTRACTOR="$(readlink -f "./verible/bazel-bin/verilog/tools/kythe/verible-verilog-kythe-extractor")"

#─────────────────────────────────────────────────────────────────────────────
# Scan and index Ibex sources

begin_command_group 'Index Ibex source code'
	cd ibex

	file_args=$($SELF_DIR/ibex_extractor_args ibex ./src_files.yml)
	$VERIBLE_VERILOG_KYTHE_EXTRACTOR --print_kythe_facts json $file_args > "$OUT_DIR/entries"

	cd -
end_command_group

#─────────────────────────────────────────────────────────────────────────────
# Create tables

begin_command_group 'Create graphstore'
	$KYTHE_DIR/tools/entrystream \
			--read_format=json \
			< "$OUT_DIR/entries" \
		| $KYTHE_DIR/tools/write_entries \
			-graphstore "$OUT_DIR/graphstore"
end_command_group

begin_command_group 'Create tables'
	$KYTHE_DIR/tools/write_tables \
			-graphstore "$OUT_DIR/graphstore" \
			-out "$ARTIFACTS_DIR/tables"
end_command_group

#─────────────────────────────────────────────────────────────────────────────
# Copy static files to artifacts directory

begin_command_group 'Copy static files'
	cp -R $STATIC_DIR/* $ARTIFACTS_DIR/
end_command_group

