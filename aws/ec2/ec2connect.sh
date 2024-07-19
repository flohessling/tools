#!/usr/bin/env bash

# This script uses fzf to select an EC2 instance to connect to using AWS SSM.
# It can be declared as a function in your shell configuration file (e.g. .bashrc, .zshrc) to make it easier to use.
# Adjust the region variable as needed or maybe even include it as an argument to the function.

region="eu-central-1"
instances=$(aws ec2 describe-instances --region $region --query "Reservations[*].Instances[*].{InstanceId:InstanceId,PrivateIP:PrivateIpAddress,Name:Tags[?Key=='Name']|[0].Value,Type:InstanceType}" --filters Name=instance-state-name,Values=running --output text)
instanceID=$(echo "$instances" | fzf -1 -q "$*" | awk '{print $1}')

if [ -z "$instanceID" ]; then
    echo "no instance selected"
fi

aws ssm start-session --target "$instanceID" --region "$region"
