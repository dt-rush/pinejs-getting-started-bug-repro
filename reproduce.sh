#!/bin/bash

curl -X POST -d name=testdevice -d note=testnote -d type=raspberry http://localhost:1337/example/device -s -o /dev/null

curl -v -X PUT -d name=testdevice -d note=updatednote http://localhost:1337/example/device\(1\)
