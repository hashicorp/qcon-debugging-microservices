#! /bin/bash
VERSION=v4.0.0

case "$1" in
"go")
	echo "Building application for linux"
	CGO_ENABLED=0 GOOS=linux go build -gcflags "-N -l" -o ./bin/service ./main.go ./tracing.go ./handler.go
	;;
"docker")
	echo "Creating Docker image"
	docker build -t nicholasjackson/broken-service:${VERSION} --no-cache .
	;;
*)
	echo "Options:"
	echo "go - Build the application binary"
	echo "docker - Create a Docker image for the application"
esac