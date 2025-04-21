# SMTP Master

A centralized management system for multiple SMTP Node mail servers. This project allows you to manage multiple Postfix mail servers from a single point, keeping user accounts, domains, and configuration synchronized.

## Features

- Centralized database of all mail servers, domains, users, and aliases
- Ansible-based deployment and management
- Database synchronization between master and slave servers
- Command-line tools for management
- Support for pushing changes to mail servers

## Prerequisites

- Ubuntu 20.04 or newer
- Docker and Docker Compose
- Ansible 2.9 or newer
- Python 3.8 or newer
- MariaDB client

## Directory Structure

```
SMTP_Master/
├── ansible/             # Ansible playbooks and configuration
├── docker/              # Docker configuration for master server
├── sql/                 # SQL scripts for master database
├── scripts/             # Management scripts
└── data/                # Persistent data storage
```

## Setup Instructions

### 1. Initial Setup

```bash
# Clone the repository
git clone https://github.com/YourUsername/SMTP_Master.git
cd SMTP_Master

# Set up environment variables
cp docker/.env.template docker/.env
# Edit the .env file with your configuration

# Start the master database
cd docker
docker-compose up -d
cd ..

# Initialize the master database (if not done by Docker)
docker exec -i smtp_master_db mysql -uroot -p${MASTER_DB_ROOT_PASSWORD} < sql/master-schema.sql

# Set up Ansible
cd ansible
ansible-galaxy collection install community.mysql
ansible-galaxy collection install community.docker

# Create encrypted secrets
ansible-vault create vars/secrets.yml
# Add required secrets (see vars/secrets.yml.template)
```

### 2. Register Mail Servers

```bash
# Register an existing mail server
ansible-playbook playbooks/register_server.yml -e "hostname=mail1.example.com ip_address=192.168.1.101 description='Primary mail server'"

# Update your inventory file
nano inventory/hosts
# Add the new server with the server_id from the registration output
```

### 3. Deploy SMTP Node to a New Server

```bash
# Deploy to a registered server
ansible-playbook playbooks/deploy.yml --limit mail1.example.com
```

### 4. Synchronize Databases

```bash
# Sync all servers
ansible-playbook playbooks/sync.yml

# Sync a specific server
ansible-playbook playbooks/sync.yml --limit mail1.example.com
```

### 5. Push Changes to Servers

```bash
# Push changes to all servers
ansible-playbook playbooks/push.yml

# Push changes to a specific server
ansible-playbook playbooks/push.yml --limit mail1.example.com
```

## Setting Up Scheduled Synchronization

Add a cron job to regularly synchronize data:

```bash
# Add to crontab
crontab -e

# Add this line to run sync every 6 hours
0 */6 * * * cd /path/to/SMTP_Master && ansible-playbook ansible/playbooks/sync.yml >> /var/log/smtp_sync.log 2>&1
```

## Managing Mail Domains and Users

You can manage domains and users either by:

1. Making changes directly in the master database
2. Using the command-line scripts (to be developed)
3. Creating a web interface (optional - to be developed)

## Troubleshooting

### Common Issues

- **Connection errors**: Check network connectivity between master and slaves
- **Database sync failures**: Verify credentials and that the sync user exists
- **Deployment failures**: Ensure Docker is installed and running on the target server

## Future Enhancements

- Web interface for easier management
- Monitoring and alerting
- Backup and restore functionality
- Reporting tools
- API for integration with other systems