#!/bin/bash
set -e

docker system prune -f

curl https://shipyard.run/install | bash 

shipyard run github.com/hashicorp/qcon-debugging-microservices//stack

shipyard pause