#!/bin/bash

IMGNAME="pinejs-getting-started-bug-repro"

if [ "${1}" != "--skip-build" ]; then
	docker build -t "${IMGNAME}" .
fi

docker run \
	-d \
	-p 1337:1337 \
	--cap-add SYS_ADMIN \
	-v /sys/fs/cgroup:/sys/fs/cgroup:ro \
	"${IMGNAME}"
