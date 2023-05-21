#!/bin/bash

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
BLUE=$(tput setaf 4)
YELLOW=$(tput setaf 3)
NORMAL=$(tput sgr0)

error() { echo "${RED}ERROR    => $1 ${NORMAL}"; echo; exit 0; }
warn() { echo "${YELLOW}WARNING    => $1 ${NORMAL}"; }
success() { echo "${GREEN}SUCCESS    => $1 ${NORMAL}"; }
info() { echo "${BLUE}INFO    => $1 ${NORMAL}"; }

SERVICE_NAME="calendar_parser"

source_env() {
    set -a
    source app/.env || error "Failed to load app .env file"
    source database/.env || error "Failed to load database .env file"
    source gateway/.env || error "Failed to load gateway .env file"
    source monitoring/.env || error "Failed to load monitoring .env file"
    source portainer/.env || error "Failed to load portainer .env file"
    set +a
}

create_networks() {
    if [[ $1 == true ]]; then
        info "Creating app network..."
        docker network create --driver=overlay --attachable app || warn "Could not create network or app network already exists"
        success "Created app network"

        info "Creating database network..."
        docker network create --driver=overlay --attachable database || warn "Could not create network or database network already exists"
        success "Created database network"

        info "Creating monitoring network..."
        docker network create --driver=overlay --attachable monitoring || warn "Could not create network or monitoring network already exists"
        success "Created monitoring network"

        info "Creating portainer network..."
        docker network create --driver=overlay --attachable portainer || warn "Could not create network or portainer network already exists"
        success "Created portainer network"

        info "Creating gateway_bridge network..."
        docker network create --driver=overlay --attachable gateway_bridge || warn "Could not create network or gateway_bridge network already exists"
        success "Created gateway_bridge network"
    else
        info "Creating app network..."
        docker network create --driver=bridge app || warn "Could not create network or app network already exists"
        success "Created app network"

        info "Creating database network..."
        docker network create --driver=bridge database || warn "Could not create network or database network already exists"
        success "Created database network"

        info "Creating monitoring network..."
        docker network create --driver=bridge monitoring || warn "Could not create network or monitoring network already exists"
        success "Created monitoring network"

        info "Creating portainer network..."
        docker network create --driver=bridge portainer || warn "Could not create network or portainer network already exists"
        success "Created portainer network"

        info "Creating gateway_bridge network..."
        docker network create --driver=bridge gateway_bridge || warn "Could not create network or gateway_bridge network already exists"
        success "Created gateway_bridge network"
    fi
}

start() {
    info "Starting service..."

    info "Loading environment variables..."
    source_env
    success "Loaded environment variables"

    info "Creating networks..."
    create_networks
    success "Created networks"

    info "Starting portainer..."
    docker-compose -f portainer/docker-compose.yml up -d || error "Failed to start portainer"

    info "Starting database..."
    docker-compose -f database/docker-compose.yml up -d || error "Failed to start database"

    info "Starting app..."
    docker-compose -f app/docker-compose.yml up -d || error "Failed to start app"

    info "Starting monitoring..."
    docker-compose -f monitoring/docker-compose.yml up -d || error "Failed to start monitoring"

    info "Starting gateway..."
    docker-compose -f gateway/docker-compose.yml up -d || error "Failed to start gateway"

    success "Service started successfully"
}

deploy() {
   info "Deploying service to cluster $SERVICE_NAME..."

    info "Loading environment variables..."
    source_env
    success "Loaded environment variables"

    info "Creating networks..."
    create_networks true
    success "Created networks"

    info "Deploying portainer..."
    docker stack deploy -c portainer/docker-compose.yml $SERVICE_NAME || error "Failed to deploy portainer"

    info "Deploying database..."
    docker stack deploy -c database/docker-compose.yml $SERVICE_NAME || error "Failed to deploy database"

    info "Deploying app..."
    docker stack deploy -c app/docker-compose.yml $SERVICE_NAME || error "Failed to deploy app"

    info "Deploying monitoring..."
    docker stack deploy -c monitoring/docker-compose.yml $SERVICE_NAME || error "Failed to deploy monitoring"

    info "Deploying gateway..."
    docker stack deploy -c gateway/docker-compose.yml $SERVICE_NAME || error "Failed to deploy gateway"

    success "Service deployed successfully" 
}

remove_networks() {
    info "Removing networks..."

    docker network rm gateway_bridge || warn "Failed to remove gateway_bridge network"
    docker network rm monitoring || warn "Failed to remove monitoring network"
    docker network rm app || warn "Failed to remove app network"
    docker network rm database || warn "Failed to remove database network"
    docker network rm portainer || warn "Failed to remove portainer network"

    success "Removed networks"
}

stop() {
    info "Stopping service..."

    docker-compose -f gateway/docker-compose.yml down || warn "Failed to stop gateway"
    docker-compose -f monitoring/docker-compose.yml down || warn "Failed to stop monitoring"
    docker-compose -f app/docker-compose.yml down || warn "Failed to stop app"
    docker-compose -f database/docker-compose.yml down || warn "Failed to stop database"
    docker-compose -f portainer/docker-compose.yml down || warn "Failed to stop portainer"

    success "Service stopped successfully"

    remove_networks
}

deploy-stop(){
    info "Stopping service..."

    docker stack rm $SERVICE_NAME || warn "Failed to stop service"

    success "Service stopped successfully"

    remove_networks
}

restart() {
    info "Restarting service..."
    stop
    start
}

COMMAND=$1

if [[ -z $COMMAND ]]; then
    echo "Usage: $0 [start|stop|restart]"
    exit 1
fi

case $COMMAND in
    start) start;;
    deploy) deploy;;
    stop) stop;;
    deploy-stop) deploy-stop;;
    restart) restart;;
    *)
        echo "Unknown command: $COMMAND"
        exit 1
        ;;
esac
