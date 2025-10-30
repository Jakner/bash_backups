#!/bin/bash

# List all projects
projects=$(gcloud projects list --format="value(projectId)" --quiet)

# IP que você deseja encontrar
ip_address="10.153.44.0/23" # Substitua pelo IP desejado

for project in $projects; do
  echo "Checking IP associations in project: $project"
  
  # Listar instâncias e filtrar pelo IP
  result=$(gcloud compute instances list \
    --project=$project \
    --filter="networkInterfaces.networkIP=('$ip_address') OR networkInterfaces.accessConfigs.natIP=('$ip_address')" \
    --format="table[box](name, networkInterfaces.network, networkInterfaces.networkIP, networkInterfaces.accessConfigs.natIP)"\
    --quiet)

  if [[ -n "$result" ]]; then
    echo "IP found in project: $project"
    echo "$result"
  else
    echo "IP not found in project: $project"
  fi
done
