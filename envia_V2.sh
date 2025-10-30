#!/bin/bash

# Verificar se o mailx está instalado
if ! command -v mailx &> /dev/null; then
    echo "O mailx não está instalado. Instale-o antes de usar este script."
    exit 1
fi

# Caminho para o diretório de log
log_dir="/var/log"
log_file="daily-backup.log"

# Caminho para o diretório de backup
backup_dir="/opt/backup"

# Verificar se o arquivo de log existe
if [ ! -f "$log_dir/$log_file" ]; then
    echo "Arquivo de log $log_dir/$log_file não encontrado."
    exit 1
fi

# Configurações de e-mail
SMTP_SERVER=""
SMTP_PORT=""
SENDER=""
RECIPIENT=""
SUBJECT=""

# Data atual no formato dd-mm-yyyy
current_date=$(date "+%d-%m-%Y")

# Extrair logs do dia atual com base no nome do arquivo
filtered_log=$(grep "$current_date" "$log_dir/$log_file")

# Verificar se há logs para o dia atual
if [ -z "$filtered_log" ]; then
    echo "Nenhum log encontrado para a data $current_date."
    exit 0
fi

# Listar arquivos de backup do dia atual
backup_files=$(find "$backup_dir"/*/*/* -type f | grep "$current_date")

# Verificar arquivos abaixo de 1K
small_files=$(find "$backup_dir"/*/*/* -type f -size 1k | grep "$current_date")

# Montar corpo do e-mail
email_body="Logs do dia $current_date:\n\n$filtered_log\n\nArquivos de backup do dia $current_date:\n\n$backup_files"

# Verificar se houve falha por arquivos pequenos
if [ -n "$small_files" ]; then
    failure_message="AVISO: Existem arquivos abaixo de 1K:\n\n$small_files\n\n"
    email_body="$failure_message$email_body"
    SUBJECT="Relatório de Backup Diário - FALHA"
fi

# Função para enviar e-mail com log
send_log_email() {
    local subject="$1"
    local recipient="$2"
    local sender="$3"
    local body="$4"

    echo -e "$body" | mailx -v -s "$subject" \
        -r "$sender" \
        -S smtp="smtp://$SMTP_SERVER:$SMTP_PORT" \
        "$recipient"
}

# Enviar o log por e-mail
send_log_email "$SUBJECT" "$RECIPIENT" "$SENDER" "$email_body"

echo "E-mail enviado para $RECIPIENT com os logs do dia $current_date e a listagem de arquivos de backup."

