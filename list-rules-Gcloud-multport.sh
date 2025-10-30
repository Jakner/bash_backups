#!/bin/bash

# Definir as portas que você deseja filtrar (adicione quantas portas precisar)
ports=("22" "1433" "3389")

# Listar todos os project IDs
projects=$(gcloud projects list --format="value(projectId)")

# Criar o filtro de múltiplas portas
port_filter=""
for port in "${ports[@]}"; do
  if [ -z "$port_filter" ]; then
    port_filter="allowed.ports=$port"
  else
    port_filter="$port_filter OR allowed.ports=$port"
  fi
done

# Loop por cada projeto e aplicar o filtro de múltiplas portas
for project in $projects; do
  echo "Checking firewall rules in project: $project"
  
  # Aplicar o filtro de múltiplas portas
  gcloud compute firewall-rules list --project=$project --filter="allowed.IPProtocol=('tcp') AND ($port_filter)" --format=json --quiet

done


