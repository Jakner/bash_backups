#!/bin/bash

# ID do projeto fixo
project_id="detraninfosiga-prod"

echo "Listando todas as regras de firewall no projeto: $project_id"
gcloud compute firewall-rules list \
  --project="$project_id" \
  --format="json(
    name,
    direction,
    priority,
    allowed[].IPProtocol:label=PROTOCOL,
    allowed[].ports:label=PORTS,
    sourceRanges:label=SRC_RANGES,
    targetTags:label=TARGET_TAGS,
    disabled
  )" \
  --quiet
