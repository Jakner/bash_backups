#!/bin/sh
################################################################################
# Backup via SSH + TAR (streaming) para múltiplos hosts
# - Exclui */dev/* (evita device files)
# - Timeouts de SSH e keepalive
# - Log detalhado e retenção de 30 dias
################################################################################

# hosts: nome;usuario@ip;caminho_remoto
#HOSTS="dns1i;root@10.1.5.35;/home/replicaacl/
#dns2i;root@10.1.5.91;/home/replicaacl/"

HOSTS="dns1i;root@10.1.5.35;/home/replicaacl/"

KEY_PATH="$HOME/.ssh/dns-prodesp"
LOG_FILE="/var/log/daily-backup.log"
DATE=$(date "+%d-%m-%Y")

# SSH: sem interação, aceita hostkey nova, timeout, keepalive
SSH_OPTS="-i $KEY_PATH -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 -o ServerAliveInterval=10 -o ServerAliveCountMax=6"

# garante log
touch "$LOG_FILE" 2>/dev/null || true

echo "$HOSTS" | while IFS= read -r entry; do
  # pula linhas vazias/espacos
  [ -z "$(printf %s "$entry" | tr -d ' \t\r')" ] && continue

  name=$(echo "$entry" | cut -d';' -f1)
  host=$(echo "$entry" | cut -d';' -f2)
  rpath=$(echo "$entry" | cut -d';' -f3)

  # valida campos
  if [ -z "$name" ] || [ -z "$host" ] || [ -z "$rpath" ]; then
    echo "[???] Linha inválida na lista HOSTS: '$entry'" | tee -a "$LOG_FILE" >/dev/null
    continue
  fi

  dest_dir="/opt/backup/datacenter/resources/$name"
  mkdir -p "$dest_dir" || { echo "[$name] ERRO mkdir $dest_dir" | tee -a "$LOG_FILE" >/dev/null; continue; }
  archive="$dest_dir/$name-$DATE.tar.gz"

  echo "[$name] Iniciando backup de $host:$rpath -> $archive" | tee -a "$LOG_FILE" >/dev/null

  # duas tentativas (resiliência)
  attempt=1
  success=0
  while [ $attempt -le 2 ]; do
    echo "[$name] Tentativa $attempt..." | tee -a "$LOG_FILE" >/dev/null

    if ssh $SSH_OPTS "$host" "tar -C \"$(dirname "$rpath")\" --exclude='*/dev/*' -czf - \"$(basename "$rpath")\"" \
       > "$archive".partial 2>>"$LOG_FILE"; then
      # valida tamanho > 0
      if [ -s "$archive".partial ]; then
        mv -f "$archive".partial "$archive"
        echo "[$name-$DATE] BACKUP SUCCESS ($archive)" | tee -a "$LOG_FILE" >/dev/null
        success=1
        break
      else
        echo "[$name] Arquivo parcial vazio; possível falha de rede." | tee -a "$LOG_FILE" >/dev/null
      fi
    else
      echo "[$name] Falha ssh/tar (veja log)." | tee -a "$LOG_FILE" >/dev/null
    fi

    attempt=$((attempt+1))
    sleep 3
  done

  # se não deu certo, limpa parcial
  [ $success -eq 1 ] || { rm -f "$archive".partial; echo "[$name-$DATE] BACKUP ERROR" | tee -a "$LOG_FILE" >/dev/null; }
done

# Retenção global: remove tar.gz com mais de 30 dias
find /opt/backup/datacenter/resources/ -type f -name "*.tar.gz" -mtime +30 -print -delete >> "$LOG_FILE" 2>&1

