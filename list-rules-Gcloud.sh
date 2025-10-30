#!/bin/bash

# List all projects
projects=$(gcloud projects list --format="value(projectId)")

# Port you want to filter
port="445"

for project in $projects; do
  echo "Checking firewall rules in project: $project"
  gcloud compute firewall-rules list --project=$project --filter="allowed.IPProtocol=('tcp') AND allowed.ports=('$port')" --format=json --quiet
done
