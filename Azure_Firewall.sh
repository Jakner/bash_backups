#!/bin/sh
########## Preecher os campos abaixo com os dados do recurso. ##################
hostname=""
subscription=""
name=""
type=Microsoft.Network/azureFirewalls
ids=/subscriptions/$subscription/resourceGroups/$name/providers/$type/$hostname
mkdir -p /opt/backup/azure/resources/$hostname
################################################################################
#diretorio de backup
backup_path="/opt/backup/azure/resources/$hostname/$hostname"
az account set --subscription $subscription
az group export --name $name --resource-ids $ids > "$backup_path"

#diretorio para onde o backup vai
internal_path="/opt/backup/azure/resources/$hostname"

#Formato de arquivo
date_format=$(date "+%d-%m-%Y")
final_archive="$hostname-$date_format.tar.gz"

# Aonde o log será armazenado
log_file="/var/log/daily-backup.log"

########################################
# Inicio do backup.
########################################

if tar -czSpf "$internal_path/$final_archive" "$backup_path"; then
   printf "[$hostname-$date_format] BACKUP SUCESS. \n" >> $log_file
else
   printf "[$hostname-$date_format] BACKUP ERROR. \n" >> $log_file
fi
rm -f /opt/backup/azure/resources/$hostname/$hostname
#Desenvolvido por Vagner Miranda - 10/06/2024.
