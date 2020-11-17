#!/bin/bash
# Copyright (c) 2020 Antmicro <https://www.antmicro.com>

set -e -u -o pipefail
shopt -s nullglob
shopt -s extglob

#─────────────────────────────────────────────────────────────────────────────

SELF_DIR="$(dirname $(readlink -f ${BASH_SOURCE[0]}))"
STATIC_DIR=$(readlink -f "$SELF_DIR/static")

# Download and build things in a subdirectory
mkdir -p $SELF_DIR/_build
cd $SELF_DIR/_build

OUT_DIR="$(readlink -f "./output")"
mkdir -p $OUT_DIR
ARTIFACTS_DIR="$(readlink -f "$OUT_DIR/artifacts")"
mkdir -p $ARTIFACTS_DIR
BAZEL_ROOT="$(readlink -f "$OUT_DIR/bazel_cache")"
mkdir -p "$BAZEL_ROOT"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Dev helpers which allow to skip steps that already succeeded. Useful in
# "run until error - fix error - run again" scenarios.
# FIXME: development-only. Remove from production version

RUN_SH_PROGRESS_DIR=$(readlink -f ./_run.sh.progress)
mkdir -p "$RUN_SH_PROGRESS_DIR"

CURRENT_STEP=''
function is_step_finished() {
	local step_name="$1"
	CURRENT_STEP="$step_name"
	if [[ -e "$RUN_SH_PROGRESS_DIR/$step_name" ]]; then
		echo -e "\033[1;32m++ Step $step_name already done - skipping\033[0m"
		true
	else
		echo -e "\033[1;37m>> Step $step_name\033[0m"
		false
	fi
}

function mark_step_finished() {
	local step_name="${1:-$CURRENT_STEP}"
	touch "$RUN_SH_PROGRESS_DIR/$step_name"
	echo -e "\033[1;32m++ Step $step_name done\033[0m"
	CURRENT_STEP=''
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Get Kythe binaries

KYTHE_VERSION='v0.0.48'
KYTHE_URL="https://github.com/kythe/kythe/releases/download/$KYTHE_VERSION/kythe-$KYTHE_VERSION.tar.gz"

if ! is_step_finished get_kythe; then
	wget --no-verbose -O kythe.tar.gz "$KYTHE_URL"
	tar -xzf kythe.tar.gz

	mark_step_finished;
fi

KYTHE_DIR="$(readlink -f "kythe-$KYTHE_VERSION")"

#─────────────────────────────────────────────────────────────────────────────
# Get Kythe sources.

KYTHE_SRC_URL="https://github.com/kythe/kythe/archive/$KYTHE_VERSION.zip"

if ! is_step_finished get_kythe_src; then
	wget --no-verbose -O kythe-src.zip "$KYTHE_SRC_URL"
	rm -rf kythe-src
	mkdir kythe-src
	unzip kythe-src.zip -d ./kythe-src

	mark_step_finished;
fi

KYTHE_SRC_DIR="$(readlink -f ./kythe-src/kythe*/)"

# FIXME: install bazel first (see script in Verible CI)
BAZEL="/usr/bin/bazel --output_user_root=$BAZEL_ROOT"

# Build web ui and static http_server, which are not present in binary release

if ! is_step_finished build_kythe_utils; then
	cd $KYTHE_SRC_DIR
	$BAZEL build \
			-c opt \
			--@io_bazel_rules_go//go/config:static \
			//kythe/go/serving/tools:http_server \
			//kythe/web/ui:ui

	mkdir -p $ARTIFACTS_DIR/{web-ui,bin}
	cp -R ./kythe/web/ui/resources/public/* $ARTIFACTS_DIR/web-ui/
	cp -R ./bazel-bin/kythe/web/ui/resources/public/js $ARTIFACTS_DIR/web-ui/
	cp ./bazel-bin/kythe/go/serving/tools/http_server/http_server $ARTIFACTS_DIR/bin/

	cd -

	mark_step_finished;
fi

#─────────────────────────────────────────────────────────────────────────────
# Get Verible sources

if ! is_step_finished get_verible; then
	#git clone --depth=1 https://github.com/google/verible.git
	# FIXME use google/verible when the fix become merged
	git clone --depth=1 -b mglb/fix-json-output git@github.com:antmicro/verible.git

	mark_step_finished;
fi

#─────────────────────────────────────────────────────────────────────────────
# Build verible-verilog-kythe-extractor

if ! is_step_finished build_verible; then
	cd verible
	$BAZEL clean
	$BAZEL build //verilog/tools/kythe:verible-verilog-kythe-extractor
	cd -

	mark_step_finished;
fi

VERIBLE_VERILOG_KYTHE_EXTRACTOR="$(readlink -f "./verible/bazel-bin/verilog/tools/kythe/verible-verilog-kythe-extractor")"

#─────────────────────────────────────────────────────────────────────────────
# Get Ibex sources

if ! is_step_finished get_ibex; then
	git clone --depth=1 https://github.com/lowRISC/ibex.git

	mark_step_finished;
fi

#─────────────────────────────────────────────────────────────────────────────
# Scan and index Ibex sources

if ! is_step_finished index_ibex; then
	cd ibex

	file_args=$($SELF_DIR/ibex_extractor_args ibex ./src_files.yml)
	printf "--> %s\n" $VERIBLE_VERILOG_KYTHE_EXTRACTOR $args
	$VERIBLE_VERILOG_KYTHE_EXTRACTOR --print_kythe_facts json $file_args > "$OUT_DIR/entries"

	cd -

	mark_step_finished;
fi

#─────────────────────────────────────────────────────────────────────────────
# Create tables

if ! is_step_finished make_graphstore; then
	$KYTHE_DIR/tools/entrystream \
			--read_format=json \
			< "$OUT_DIR/entries" \
		| $KYTHE_DIR/tools/write_entries \
			-graphstore "$OUT_DIR/graphstore"

	mark_step_finished;
fi

if ! is_step_finished make_tables; then
	$KYTHE_DIR/tools/write_tables \
			-graphstore "$OUT_DIR/graphstore" \
			-out "$ARTIFACTS_DIR/tables"

	mark_step_finished;
fi

#─────────────────────────────────────────────────────────────────────────────
# Copy static files to artifacts directory

cp $STATIC_DIR/run-kythe-server.sh $ARTIFACTS_DIR/
