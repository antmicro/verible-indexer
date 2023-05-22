#!/usr/bin/env python3
# Copyright (c) 2023 Antmicro <https://www.antmicro.com>

import os
import sys
import json
import git


def main():
    """
        Load dependencies from .JSON
    """
    pFile = open("deps.json")
    deps_list = json.load(pFile)
    # Any deps with new revision will be placed in this dict
    changed_deps_list = []
    # All deps after updates will be placed in this dict
    new_deps_list = []

    # Commit message
    commit_msg = ""

    print(f"Seeking cores with updated revisions")
    for core in deps_list["cores"]:
        core_name = core["repository_name"]
        url = core["repository_url"]
        branch = core["repository_branch"]
        revision = core["repository_revision"]
        print(f":: Core     = {core_name}")
        print(f":: URL      = {url}")
        print(f":: Branch   = {branch}")
        print(f":: Revision = {revision}")

        """
            Git check for new revisions
        """

        ls_remote_answer = (git.cmd.Git().ls_remote(
            "--q", url, branch)).split('\t')
        try:
            new_rev = ls_remote_answer[0]
            new_ref = ls_remote_answer[1]
        except Exception:
            print(
                f"Failed to read revision for ${core_name}, ${url}, ${branch}")
            return 1
        print(f":: Newest revision = {new_rev}")

        new_deps_list.append(core)

        if new_rev != revision:
            # update revision in file
            print(
                f"{revision} is different than {new_rev} - {core_name} will be updated")
            changed_deps_list.append(core)
            changed_deps_list[-1]["repository_revision"] = new_rev
            new_deps_list[-1]["repository_revision"] = new_rev

            repo = git.Git("./").clone(url)
            git_log = git.Git(f"./{core_name}").log("--oneline",
                                                    "--no-decorate", f"{revision}..{new_rev}")
            commit_msg += core_name+" "+git_log+"\n"
        print()

    """
        Setup commit message for the bot
    """
    commit_msg = "Update revisions\n" + commit_msg
    print(f":: Commit msg")
    print(commit_msg)

    """
        Save dependencies to .JSON
    """
    print("Update the following dependencies:")
    print(str(changed_deps_list))
    new_deps_dict = {}
    new_deps_dict["cores"] = new_deps_list
    with open("deps.json", "w") as pFile:
        print("New file:")
        print(str(new_deps_dict))
        json.dump(new_deps_dict, pFile)
    pFile.close()

    """
        Save environment for next steps.
        Will not work in local environment
    """
    gha_env_file = os.getenv('GITHUB_ENV')
    commit_msg_filename = "commit_message.txt"
    do_update = str(bool(len(changed_deps_list)))

    update_deps = changed_deps_list
    update_deps_dict = {}
    update_deps_dict["cores"] = update_deps

    print(f"update_deps={update_deps_dict}")
    with open("update-deps.json", "w") as pFile:
        json.dump(update_deps_dict, pFile)
    pFile.close()

    with open(gha_env_file, "a") as pFile:
        pFile.writelines(f"DO_UPDATE={do_update}\n")
        pFile.writelines(f"COMMIT_MSG_FILE={commit_msg_filename}\n")
    pFile.close()

    with open(commit_msg_filename, "w") as pFile:
        pFile.writelines(f"{commit_msg}")
    pFile.close()

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
