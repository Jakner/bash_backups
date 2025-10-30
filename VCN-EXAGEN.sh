#!/bin/sh
########## Preecher os campos abaixo com os dados do recurso. ##################
hostname=VCN-EXAGEN
OCID=ocid1.vcn.oc1.sa-saopaulo-1.amaaaaaaqafmunaae54o2mvntqe7t2q7ohgaryve274hzhkipygjcxradelq
OCID1=ocid1.compartment.oc1..aaaaaaaaj7czxcc2rkfd7nuwyafv2q57ufatkxtwti4bbqqjvuzeeidqgyaa 
mkdir -p /opt/backup/oracle/resources/$hostname
################################################################################
#diretorio de backup
backup_path="/opt/backup/oracle/resources/$hostname/$hostname"
source /root/myenv/bin/activate
oci network vcn get --vcn-id $OCID >> "$backup_path"
oci network subnet list --compartment-id $OCID1 >> "$backup_path"
oci network route-table list --compartment-id $OCID1 >> "$backup_path"
oci network local-peering-gateway list --compartment-id $OCID1 >> "$backup_path"
oci network dhcp-options list --compartment-id $OCID1 >> "$backup_path"
oci network security-list list --compartment-id $OCID1 >> "$backup_path"

#diretorio para onde o backup vai
internal_path="/opt/backup/oracle/resources/$hostname"

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
rm -f /opt/backup/oracle/resources/$hostname/$hostname
