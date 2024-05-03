#!/usr/bin/env bash

# WARNING: this script will update all aurora-mysql database clusters to the specified engine version and apply changes immediately!
# do not run this script if you are not sure about the consequences!

TOOLS="aws jq"

echo "> checking requirements..."
for tool in $TOOLS; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo >&2 "ERROR: $tool is required. Aborting."
    exit 1
  }
done

ENGINE_VERSIONS=$(aws rds describe-db-engine-versions --engine aurora-mysql | jq -r '.DBEngineVersions[].EngineVersion' | tail -n +2)

if [ -z "$1" ]; then
  echo "> parameter \`engine_version\` is required. please provide \`latest\` or a valid version string"
  echo "> these are available engine version strings for aurora-mysql:"
  echo "$ENGINE_VERSIONS"
  echo "> script exiting..."
  exit 1
fi

if [ "$1" == "latest" ]; then
  ENGINE=$(echo "$ENGINE_VERSIONS" | tail -1)
elif [[ "$ENGINE_VERSIONS" =~ $1 ]]; then
  ENGINE=$1
else
  echo "> parameter \`engine_version\` is required. please provide \`latest\` or a valid version string"
  echo "> these are available engine version strings for aurora-mysql:"
  echo "$ENGINE_VERSIONS"
  echo "> script exiting..."
  exit 1
fi

DBCLUSTERS=$(aws rds describe-db-clusters | jq -r '.DBClusters[] | .DBClusterIdentifier')

echo "> updating database clusters to engine_version $ENGINE"
for cluster in $DBCLUSTERS; do
  echo "> db-cluster-identifier: $cluster"
  aws rds modify-db-cluster --db-cluster-identifier "$cluster" --engine-version "$ENGINE" --apply-immediately
done
