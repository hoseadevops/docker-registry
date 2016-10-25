#!/bin/bash

set -e

prj_path=$(cd $(dirname $0); pwd -P)
SCRIPTFILE=`basename $0`

source $prj_path/base.sh

usage() {
	cat <<-EOF
		Usage: mamanger.sh [options]

		Valid options are:

		    build 
		    run   
		    to-docker-registry
		    stop
		    restart
		    backup
		    to-docker-registry

		    test-push
		    -h                      show this help message and exit
EOF
	exit $1
}

docker_registry_image=registry:2.2
docker_registry_container=sunfund-registry
docker_registry_container_runtime=sunfund-registry-c
test_image=nginx:1.11

test_push() {
    push_image $test_image
}

build() {
   run_cmd "docker pull $docker_registry_image"
}

run() {
    local path='/opt/data'
    args="--restart always"
    args="$args -p 11380:5000"

    # mount config
    args="$args -v $prj_path/config/passwd:/auth/htpasswd"

    # set env variables for auth
    args="$args -e REGISTRY_AUTH=htpasswd"
    args="$args -e 'REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm'"
    args="$args -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd"

    # mount data directory
    args="$args -v $path/docker-registry:/var/lib/registry"

    run_cmd "docker run -it $args --name $docker_registry_container $docker_registry_image"
}

to_docker_registry() {
    args=""
    run_cmd "docker run -it --rm $args --entrypoint /bin/bash --name $docker_registry_container_runtime $docker_registry_image"
}

stop() {
    stop_container $docker_registry_container
}

backup() {
    cmd='docker_registry-rake docker_registry:backup:create'
    run_cmd "docker exec -it $args $docker_registry_container $cmd"
}

while :; do
    case $1 in
        -h|-\?|--help)
            usage
            exit
            ;;
        run)
            run
            exit
            ;;
        to-docker-registry)
            to_docker_registry
            exit
            ;;
        stop)
            stop
            exit
            ;;
        build)
            build
            exit
            ;;
        backup)
            backup
            exit
            ;;
        restart)
            stop
            run
            exit
            ;;
        test-push)
            test_push
            exit
            ;;
        to-docker-registry)
            to_docker_registry
            exit
            ;;
        *)
            usage
            exit 1
    esac

    shift
done
