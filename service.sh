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

source_env() {
    set -a
    source app/.env || error "Failed to load app .env file"
    source database/.env || error "Failed to load database .env file"
    source gateway/.env || error "Failed to load gateway .env file"
    source monitoring/.env || error "Failed to load monitoring .env file"
    set +a
}

start() {
    info "Starting service..."

    source_env
    success "Loaded environment variables"

    info "Creating infra network..."
    docker network create --driver=bridge infra || warn "Infra network already exists"
    success "Created infra network"

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

stop() {
    info "Stopping service..."

    docker-compose -f gateway/docker-compose.yml down || warn "Failed to stop gateway"
    docker-compose -f monitor/docker-compose.yml down || warn "Failed to stop monitoring"
    docker-compose -f app/docker-compose.yml down || warn "Failed to stop app"
    docker-compose -f database/docker-compose.yml down || warn "Failed to stop database"

    success "Service stopped successfully"
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
    stop) stop;;
    restart) restart;;
    *)
        echo "Unknown command: $COMMAND"
        exit 1
        ;;
esac
