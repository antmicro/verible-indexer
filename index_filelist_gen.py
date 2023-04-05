#!/usr/bin/env python3
# Copyright (c) 2023 Antmicro <https://www.antmicro.com>

import argparse
import os
import sys
import shlex
import tempfile
from pathlib import Path

def main():
    """
        Parse arguments
    """
    parser = argparse.ArgumentParser(description="Index file list search")
    parser.add_argument(
        "--only_discover",
        action="store_true",
        help="Lists all found {.v|.sv|...} files ")
    parser.add_argument(
        "--path_core",
        default=None,
        help="Path to local repository, containg an IP core")
    args = parser.parse_args()

    """
        File extension configuration
    """
    source_file_exts = [".v", ".sv"]
    include_file_exts = [".vi",".svi"]
    header_file_exts = [".vh",".svh"]
    """

    """
    path_core_root = args.path_core
    if path_core_root is None:
        raise ValueError("Provide path to an IP core")

    file_list = []
    include_dir_list = []
    for root, dirs, files in os.walk(path_core_root):
        for file in files:
            for extension in source_file_exts:
                if file.endswith(extension):
                    file_list.append(os.path.join(root, file).split(str(path_core_root))[-1])
                    # paths.append(os.path.join(file))
                    # paths.append(file)
            for extension in include_file_exts+header_file_exts:
                if file.endswith(extension):
                    # breakpoint()
                    # include_dir_list.append(os.path.join(root, file))
                    include_dir_list.append(root.split(str(path_core_root))[-1])

    # Remove duplicates
    file_list = list(dict.fromkeys(file_list))
    include_dir_list = list(dict.fromkeys(include_dir_list))

    if args.only_discover:
        print("--source_files:")
        for path in file_list:
            print(path)
        print("--include_dir:")
        for path in include_dir_list:
            print(path)
        return 0

    if len(file_list) == 0:
        raise ValueError("File list is empty.")

    filelist = tempfile.NamedTemporaryFile(mode="w", delete=False, dir=os.getcwd(), prefix="file_list.", suffix=".txt")
    for fp in file_list:
        print(fp, file=filelist)

    include_dir_list = ",".join(include_dir_list)

    print(f"--include_dir_paths {shlex.quote(include_dir_list)} --file_list_path {shlex.quote(filelist.name)}")
    filelist.close()

    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        import traceback

        print("\n\033[1;94m*** EXCEPTION ***\033[0m\n", file=sys.stderr)
        traceback.print_exc()

        print("\n\033[1;94m*** ENVIRONMENT ***\033[0m\n", file=sys.stderr)
        print(
            f"Cmd:  {repr(sys.argv)}",
            f"CWD:  {repr(os.getcwd())}",
            f"PATH: {repr(os.environ['PATH'].split(':'))}",
            sep="\n", file=sys.stderr
        )
        sys.exit(255)