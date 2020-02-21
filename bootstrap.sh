#!/bin/bash
set -e

curl https://shipyard.run/install | bash 

shipyard run github.com/hashicorp/qcon-debugging-microservices//stack

shipyard pause