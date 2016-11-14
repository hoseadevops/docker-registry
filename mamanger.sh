#!/bin/bash

set -e

prj_path=$(cd $(dirname $0); pwd -P)
SCRIPTFILE=`basename $0`

source $prj_path/base.sh


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

    # mount data directory
    args="$args -v $prj_path:$prj_path"
    args="$args -v $path/docker-registry:/var/lib/registry"

    args="$args -w $prj_path"

    run_cmd "docker run -d $args --name $docker_registry_container $docker_registry_image"
}

function run_ui() {
    local path='/opt/data'
    args="--restart always"
    args="$args -p 11480:80"

    # mount data directory
    args="$args -v $path/docker-registry-ui:/var/lib/registry-ui"

    local ENV_DOCKER_REGISTRY_HOST="docker-registry.sunfund.com"
    local ENV_DOCKER_REGISTRY_PORT=""

    # set env variables for auth
    args="$args -e ENV_DOCKER_REGISTRY_HOST=$ENV_DOCKER_REGISTRY_HOST"
    args="$args -e ENV_DOCKER_REGISTRY_PORT=$ENV_DOCKER_REGISTRY_PORT"

    run_cmd "docker run -d $args --name $docker_ui_container $docker_ui_image"
}

# we can run into docker registry container to execute some task, generate password for example.
function to_registry() {
    local cmd="bash"
    run_cmd "docker exec -it $docker_registry_container bash -c '$cmd'"
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

function help() {
    cat <<-EOF

    Usage: mamanger.sh [options]

        Valid options are:

            run

            run_registry
            run_ui

            to_registry
            
            build
            build_ui
            build_registry

            stop
            stop_uid
            stop_registry

            restart
            restart_ui
            restart_registry

            test_push

            help                      show this help message and exit

EOF
    exit 1
}

action=${1:-help}
ALL_COMMANDS="help run run_registry run_ui to_registry stop stop_registry stop_ui build build_ui build_registry restart restart_ui restart_registry test_push"
list_contains ALL_COMMANDS "$action" || action=help
$action "$@"
