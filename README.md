# Kythe Verible Indexer

Copyright (c) 2020-2023 [Antmicro](https://www.antmicro.com)

This project enables selection of multiple repositories to create a set of indexed webpages. Cores meant for indexing are selected in the "DEPENDENCIES" array in shell include scripts: deps.inc.sh, common.inc.sh

## Supported Cores

Currently indexed cores are:

* [Ibex](https://github.com/lowRISC/ibex) - [link](http://34.123.203.237)
* [VeeR-EL2](https://github.com/antmicro/Cores-VeeR-EL2) - [link](http://34.27.121.3)
* [Caliptra](https://github.com/chipsalliance/caliptra-rtl) - [link](http://34.31.62.228)

## Adding new cores

In order to add/remove a core from the build:
 * add/remove an entry in the DEPENDENCIES array (common.inc.sh and deps.inc.sh):
 <pre>
 declare -A DEPENDENCIES=(
	# Value syntax: GIT_URL<whitespace>BRANCH
	[verible]='https://github.com/chipsalliance/verible.git master'
    [my_new_repo]='https://github.com/my_new_ip_core/ip_core.git main'
)
 </pre>

 * Run script, which updates the deps-revisions.txt file
 <pre>
 ./update-deps.sh
 </pre>

 * Check if desired core is listed in the deps-revisions.txt (a manual fix may be required in some cases)

 Example of expected contents:
 <pre>
 ibex	93c8e92c0ddbeed1239b04251cfb7d9ae68b5d1f
 </pre>
