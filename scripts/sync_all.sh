#!/bin/bash
# Simple script to synchronize all mail servers

# Load environment variables
if [ -f docker/.env ]; then
  source docker/.env
fi

# Set path to Ansible
ANSIBLE_PATH="$(pwd)/ansible"

# Run the sync playbook
echo "Starting synchronization of all mail servers..."
ansible-playbook $ANSIBLE_PATH/playbooks/sync.yml || {
  echo "Error: Synchronization failed!"
  exit 1
}

echo "Synchronization completed successfully."

# Display last sync times
echo "Last synchronization times:"
mysql -u$MASTER_DB_USER -p$MASTER_DB_PASSWORD master_postfix -e "SELECT hostname, last_sync FROM mail_servers ORDER BY hostname;"

exit 0