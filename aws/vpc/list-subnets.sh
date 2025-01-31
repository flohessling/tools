#!/usr/bin/env bash

# list all subnets in a vpc

# query the vpc ID and choose the vpc to list all subnets using fzf
vpc_id=$(aws ec2 describe-vpcs \
    --query 'Vpcs[*].[VpcId, CidrBlock]' \
    --output text | fzf | awk '{print $1}')

# list all subnets in the vpc
subnets=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$vpc_id" \
    --output json | jq -r '.Subnets[] | [(.Tags[]? | select(.Key=="Name") | .Value // "no name"), .CidrBlock] | @tsv' | sort -V -k2)

# check if there are subnets
if [ -z "$subnets" ]; then
    echo "no subnets found in vpc $vpc_id..."
    exit 1
fi

# print table header
echo -e "\nsubnet list for vpc: $vpc_id"
echo "---"
printf "%-25s %-20s\n" "subnet name" "cidr block"
echo "---"

# print table
echo "$subnets" | column -t -s $'\t'
