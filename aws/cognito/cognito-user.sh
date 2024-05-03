#!/usr/bin/env bash

# This script allows you to manage users and groups in AWS Cognito.
# Thanks to github.com/janbuecker for this :)

TOOLS="aws fzf jq"

echo "> checking requirements..."
for tool in $TOOLS; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo >&2 "ERROR: $tool is required. Aborting."
    exit 1
  }
done

printf '%-14s ' "user pool id:"
poolID=$(aws cognito-idp list-user-pools --max-results 50 --output text --query 'UserPools[].Id' | fzf -1)
if [ -z "$poolID" ]; then
  exit 1
fi
echo "$poolID"

usernames=$(aws cognito-idp list-users --user-pool-id "$poolID" --query "Users[].Username" --output json | jq -r '.[]')
printf '%-14s ' "username:"
username=$(echo "$usernames" | fzf -1 -q "$1")
if [ -z "$username" ]; then
  return
fi
echo "$username"

availableGroups=$(aws cognito-idp list-groups --user-pool-id "$poolID" --output json --query "Groups[].GroupName" | jq -r '.[]')
currentGroups=$(aws cognito-idp admin-list-groups-for-user --user-pool-id "$poolID" --username "$username" --output json --query "Groups[].GroupName" | jq -r '.[]')
groups=$(echo "$availableGroups" | fzf --multi --preview-window="top:50%" --preview-label="Current groups" --preview "echo \"$currentGroups"\")
if [ -z "$groups" ]; then
  return
fi
printf '%-14s ' "groups:"

echo

diff --color=always -u <(echo "$currentGroups" | sort) <(echo "$groups" | sort) | tail -n +4

echo

read -r -p "continue? [y/N] " -n 1
echo
if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
  return
fi

for g in $groups; do
  if [[ ! " ${currentGroups[*]} " =~ $g ]]; then
    echo "* adding to $g"
    aws cognito-idp admin-add-user-to-group --user-pool-id "$poolID" --username "$username" --group-name "$g"
  fi
done

for g in $currentGroups; do
  if [[ ! " ${groups[*]} " =~ $g ]]; then
    echo "* removing from $g"
    aws cognito-idp admin-remove-user-from-group --user-pool-id "$poolID" --username "$username" --group-name "$g"
  fi
done
