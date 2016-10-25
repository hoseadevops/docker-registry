#!/bin/bash

set -e

prj_path=$(cd $(dirname $0); pwd -P)
SCRIPTFILE=`basename $0`

source $prj_path/base.sh

function usage() {
	cat <<-EOF
		Usage: mamanger.sh [options]

		Valid options are:

		    build 
		    build-registry
		    build-ui

		    run   
		    run-registry
		    run-ui

		    stop
		    stop-registry
		    stop-ui

		    restart
		    restart-registry
		    restart-ui

		    to-docker-registry
		    test-push

		    -h                      show this help message and exit
EOF
	exit $1
}

host_ip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | awk '{print $1}' | head  -1)
docker_registry_image=registry:2.2
docker_registry_container=sunfund-registry

docker_ui_image=konradkleine/docker-registry-frontend:v2
docker_ui_container=sunfund-registry-ui

docker_registry_container_runtime=sunfund-registry-c

test_image=nginx:1.11

function test_push() {
    push_image $test_image
}

function build_registry() {
   run_cmd "docker pull $docker_registry_image"
}

function build_ui(){
   run_cmd "docker pull $docker_ui_image"
}

function build() {
    build_ui
    build_registry
}

function run_registry() {
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

    run_cmd "docker run -d $args --name $docker_registry_container $docker_registry_image"
}

function run_ui() {
    local path='/opt/data'
    args="--restart always"
    args="$args -p 11480:80"

    # mount data directory
    args="$args -v $path/docker-registry-ui:/var/lib/registry-ui"

    # TODO
    ENV_DOCKER_REGISTRY_HOST="docker-registry.sunfund.com"
    ENV_DOCKER_REGISTRY_PORT=""

    ENV_DOCKER_REGISTRY_HOST="$host_ip"
    ENV_DOCKER_REGISTRY_PORT="11380"

    # set env variables for auth
    args="$args -e ENV_DOCKER_REGISTRY_HOST=$ENV_DOCKER_REGISTRY_HOST"
    args="$args -e ENV_DOCKER_REGISTRY_PORT=$ENV_DOCKER_REGISTRY_PORT"

    run_cmd "docker run -d $args --name $docker_ui_container $docker_ui_image"
}

# we can run into docker registry container to execute some task, generate password for example.
function to_docker_registry() {
    args=""
    run_cmd "docker run -it --rm $args --entrypoint /bin/bash --name $docker_registry_container_runtime $docker_registry_image"
}

function run() {
    run_registry
    run_ui
}

function stop_registry() {
    stop_container $docker_registry_container
}

function stop_ui() {
    stop_container $docker_ui_container
}

function stop() {
    stop_ui
    stop_registry
}

function restart_registry() {
    stop_registry
    run_registry
}

function restart_ui() {
    stop_ui
    run_ui
}

function restart() {
    restart_registry
    restart_ui
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
        run-registry)
            run_registry
            exit
            ;;
        run-ui)
            run_ui
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
        stop-registry)
            stop_registry
            exit
            ;;
        stop-ui)
            stop_ui
            exit
            ;;
        build)
            build
            exit
            ;;
        build-ui)
            build_ui
            exit
            ;;
        build-registry)
            build_registry
            exit
            ;;
        restart)
            restart
            exit
            ;;
        restart-ui)
            restart_ui
            exit
            ;;
        restart-registry)
            restart_registry
            exit
            ;;
        test-push)
            test_push
            exit
            ;;
        *)
            usage
            exit 1
    esac

    shift
done
