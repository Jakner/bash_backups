#!/bin/bash

# Arquivo de dispositivos
device_file="/resources/devices.txt"

# URI
uri="api/v2/monitor/system/config/backup?scope=global&access_token"

# Caminho base para backups
base_backup_path="/opt/backup/fortinet/resources"
log_file="/var/log/daily-backup.log"

# Formato de data
date_format=$(date "+%d-%m-%Y")

# Função para fazer backup de um dispositivo
backup_device() {
    local hostname="$1"
    local ip="$2"
    local port="$3"
    local token="$4"

    local backup_dir="$base_backup_path/$hostname"
    local backup_path="$backup_dir/$hostname"
    local final_archive="$hostname-$date_format.tar.gz"

    # Criar diretório de backup se não existir
    mkdir -p "$backup_dir"

    # Realizar o backup com curl
    local backup_file
    backup_file=$(mktemp)
    curl --noproxy "*" -k -H "Authorization: Bearer $token"  "https://$ip:$port/$uri" -o "$backup_file"
    if [ $? -ne 0 ]; then
        printf "[$hostname-$date_format] BACKUP ERROR: Failed to download backup.\n" >> "$log_file"
        rm -f "$backup_file"
        return 1
    fi

    # Criar arquivo tar.gz do backup
    tar -czSpf "$backup_dir/$final_archive" -C "$(dirname "$backup_file")" "$(basename "$backup_file")"
    if [ $? -ne 0 ]; then
        printf "[$hostname-$date_format] BACKUP ERROR: Failed to create archive.\n" >> "$log_file"
        rm -f "$backup_file"
        return 1
    fi

    # Log de sucesso e limpeza
    printf "[$hostname-$date_format] BACKUP SUCCESS.\n" >> "$log_file"
    rm -f "$backup_file"
}

# Ler dispositivos do arquivo e fazer backup de cada um
while IFS=, read -r hostname ip port token; do
    # Ignorar linhas em branco ou começando com #
    [[ -z "$hostname" || -z "$ip" || -z "$port" || -z "$token" || "$hostname" =~ ^# ]] && continue
    backup_device "$hostname" "$ip" "$port" "$token"
done < "$device_file"

# Desenvolvido por Vagner Miranda - 10/06/2024.

