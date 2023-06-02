# Kythe Verible Indexer

Copyright (c) 2020-2023 [Antmicro](https://www.antmicro.com)

This project enables selection of multiple repositories to create a set of indexed webpages. The indexing is performed by the [Verible Indexing Action](https://github.com/antmicro/verible-indexing-action). Cores meant for indexing are selected in the [deps.json file](https://github.com/antmicro/verible-indexer/blob/mczyz/gh-action/deps.json) and can be easily expanded by adding another entry in the JSON array,e.g.:

	{
		"repository_name": "repo-you-need",
		"repository_url": "https://github.com/path/to/repo-you-need",
		"repository_branch": "valid-name-of-branch",
		"repository_revision": "valid-sha-of-revision"
	}

The workflow checks if newer revision are available for any of the defined repositories and, if needed, performs indexing. The outputs are captured in docker images, where each repository is given a unique image with an http_server installed. Repository name variable is used to tag images, e.g. ghcr.io/antmicro/verible-indexer:repo-you-need.

## Supported Cores

Links to App Engine:

* [Ibex](https://github.com/lowRISC/ibex) - [link](https://ibex-dot-catx-ext-chips-alliance.uc.r.appspot.com)
* [VeeR-EL2](https://github.com/antmicro/Cores-VeeR-EL2) - [link](https://cores-veer-el2-dot-catx-ext-chips-alliance.uc.r.appspot.com)
* [Caliptra](https://github.com/chipsalliance/caliptra-rtl) - [link](https://caliptra-rtl-dot-catx-ext-chips-alliance.uc.r.appspot.com)

## Docker Images

In order to test the docker image locally, pull and run the image (update the path to the image with any of the [tagged images](https://github.com/antmicro/verible-indexer/pkgs/container/verible-indexer)):

	docker pull ghcr.io/antmicro/verible-indexer:latest
	sudo docker run ghcr.io/antmicro/verible-indexer:latest

It may be useful to run the image with a shell entrypoint for debugging purposes, which can be achieved with the following command:

	sudo docker run -ti --entrypoint /bin/bash ghcr.io/antmicro/verible-indexer:latest

Find IP of the docker image

	docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <docker_id>

In a web browser, connect to IP on port 8080.