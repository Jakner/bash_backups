#!/bin/bash

# Projeto alvo
project_id="detraninfosiga-prod"

# Portas de alto risco
critical_ports=("22" "3389" "445")

echo "🔍 Listando todas as regras de firewall no projeto: $project_id"
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

echo -e "\n🚨 Verificando regras abertas para 0.0.0.0/0 com portas críticas expostas..."

# Inicializa flag
found_critical=false

# Loop por cada porta crítica
for port in "${critical_ports[@]}"; do
  result=$(gcloud compute firewall-rules list \
    --project="$project_id" \
    --filter="sourceRanges=('0.0.0.0/0') AND allowed.ports=('${port}')" \
    --format="table(name, direction, allowed[].IPProtocol, allowed[].ports)")

  if [[ -n "$result" && "$result" != "Listed 0 items." ]]; then
    echo -e "\n⚠️ ALTO RISCO: Porta $port exposta ao mundo (0.0.0.0/0)!"
    echo "$result"
    found_critical=true
  fi
done

# Verifica se nenhuma foi encontrada
if [ "$found_critical" = false ]; then
  echo "✅ Nenhuma porta crítica exposta ao mundo encontrada."
fi

