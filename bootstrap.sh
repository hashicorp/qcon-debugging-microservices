#!/bin/bash
set -e

docker system prune -f
yes | apt-get clean
yes | apt-get autoremove --purge
rm -rf /var/lib/apt/lists/*

curl https://shipyard.run/install | bash 
shipyard version

# Run shipyard only to cache the latest version of the docker images on the box to speed up start times
shipyard run --no-browser github.com/hashicorp/qcon-debugging-microservices//stack
shipyard destroy

df -h