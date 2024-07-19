#!/usr/bin/env bash

# This script uses fzf to select an ECS task to connect to using AWS ECS ExecuteCommand.
# It can be declared as a function in your shell configuration file (e.g. .bashrc, .zshrc) to make it easier to use.

printf '%-12s ' "cluster:"
cluster=$(aws ecs list-clusters --query 'clusterArns' | jq -r '.[]' | cut -d '/' -f2 | fzf -1 -q "$1")
if [ -z "$cluster" ]; then
    echo "no cluster found"
    return
fi
echo "$cluster"

printf '%-12s ' "service:"
service=$(aws ecs list-services --cluster "$cluster" --query 'serviceArns' | jq -r '.[]' | cut -d '/' -f3 | fzf -1 -q "$2")
if [ -z "$service" ]; then
    echo "no service found"
    return
fi
echo "$service"

printf '%-12s ' "container:"
taskDef=$(aws ecs describe-services --services "$service" --cluster "$cluster" | jq -r '.services[].taskDefinition')
if [ -z "$taskDef" ]; then
    echo "no task definition found"
    return
fi
container=$(aws ecs describe-task-definition --task-definition "$taskDef" | jq -r '.taskDefinition.containerDefinitions[] | select(.linuxParameters.initProcessEnabled == true) | .name' | fzf -1 -q "$3")
if [ -z "$container" ]; then
    echo "no container with SSM enabled found"
    return
fi
echo "$container"

printf '%-12s ' "task:"
taskID=$(aws ecs list-tasks --cluster "$cluster" --service "$service" --query 'taskArns' | jq -r '.[]' | cut -d'/' -f3 | fzf -1 -q "$4")
if [ -z "$taskID" ]; then
    echo "no task found"
    return
fi
echo "$taskID"
echo "---"
echo "connecting to $cluster/$service/$taskID/$container"

aws ecs execute-command --interactive --command /bin/sh --task "$taskID" --cluster "$cluster" --container "$container"
