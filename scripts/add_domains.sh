#!/bin/bash
# Script to add a domain to a mail server

if [ $# -lt 2 ]; then
  echo "Usage: $0 <domain> <server_id>"
  exit 1
fi

DOMAIN="$1"
SERVER_ID="$2"

# Load environment variables
source docker/.env

# Add domain to master
mysql -u$MASTER_DB_USER -p$MASTER_DB_PASSWORD master_postfix <<EOF
INSERT INTO master_virtual_domains (server_id, origin_id, name) 
VALUES ($SERVER_ID, NULL, '$DOMAIN');

INSERT INTO master_changes (server_id, change_type, table_name, record_id, sql_statement)
VALUES ($SERVER_ID, 'INSERT', 'virtual_domains', 0, 
        'INSERT INTO virtual_domains (name) VALUES ("$DOMAIN");');
EOF

# Get server hostname
SERVER=$(mysql -u$MASTER_DB_USER -p$MASTER_DB_PASSWORD master_postfix -N -e "SELECT hostname FROM mail_servers WHERE id=$SERVER_ID;")

# Push changes
ansible-playbook ansible/playbooks/push.yml --limit "$SERVER"

echo "Domain $DOMAIN added to server $SERVER (ID: $SERVER_ID)"
