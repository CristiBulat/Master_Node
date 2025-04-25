-- Master Database Schema for SMTP Master
-- This is the central database that will store data from all mail servers

-- Server registry table
CREATE TABLE IF NOT EXISTS `mail_servers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `hostname` varchar(255) NOT NULL,
  `ip_address` varchar(45) NOT NULL,
  `description` varchar(255),
  `status` varchar(20) NOT NULL DEFAULT 'active',
  `last_sync` datetime,
  PRIMARY KEY (`id`),
  UNIQUE KEY `hostname` (`hostname`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Master virtual_domains table with server reference
CREATE TABLE IF NOT EXISTS `master_virtual_domains` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `server_id` int(11) NOT NULL,
  `origin_id` int(11) NOT NULL,
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `server_domain` (`server_id`, `name`),
  FOREIGN KEY (`server_id`) REFERENCES `mail_servers`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Master virtual_users table with server reference
CREATE TABLE IF NOT EXISTS `master_virtual_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `server_id` int(11) NOT NULL,
  `origin_id` int(11) NOT NULL,
  `domain_id` int(11) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(106) NOT NULL,
  `created` datetime NOT NULL,
  `modified` datetime NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `server_email` (`server_id`, `email`),
  FOREIGN KEY (`server_id`) REFERENCES `mail_servers`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`domain_id`) REFERENCES `master_virtual_domains`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Master virtual_aliases table with server reference
CREATE TABLE IF NOT EXISTS `master_virtual_aliases` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `server_id` int(11) NOT NULL,
  `origin_id` int(11) NOT NULL,
  `domain_id` int(11) NOT NULL,
  `source` varchar(100) NOT NULL,
  `destination` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `server_source` (`server_id`, `source`),
  FOREIGN KEY (`server_id`) REFERENCES `mail_servers`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`domain_id`) REFERENCES `master_virtual_domains`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Master DKIM keys table with server reference
CREATE TABLE IF NOT EXISTS `master_dkim_keys` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `server_id` int(11) NOT NULL,
  `origin_id` int(11) NOT NULL,
  `domain_id` int(11) NOT NULL,  -- Using domain_id instead of domain VARCHAR
  `selector` varchar(63) NOT NULL,
  `private_key` text NOT NULL,
  `public_key` text NOT NULL, 
  `dns_record` text NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `server_domain_selector` (`server_id`, `domain_id`, `selector`),
  FOREIGN KEY (`server_id`) REFERENCES `mail_servers`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`domain_id`) REFERENCES `master_virtual_domains`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Change tracking table
CREATE TABLE IF NOT EXISTS `master_changes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `server_id` int(11) NOT NULL,
  `change_type` enum('INSERT','UPDATE','DELETE') NOT NULL,
  `table_name` varchar(50) NOT NULL, 
  `record_id` int(11) NOT NULL,
  `sql_statement` text NOT NULL,
  `change_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `applied` tinyint(1) NOT NULL DEFAULT 0,
  `apply_time` datetime,
  PRIMARY KEY (`id`),
  KEY `server_applied` (`server_id`, `applied`),
  FOREIGN KEY (`server_id`) REFERENCES `mail_servers`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create useful views for querying
CREATE OR REPLACE VIEW view_all_domains AS
SELECT 
  md.id, 
  s.hostname AS server, 
  md.name AS domain
FROM master_virtual_domains md
JOIN mail_servers s ON md.server_id = s.id;

CREATE OR REPLACE VIEW view_all_users AS
SELECT 
  mu.id, 
  s.hostname AS server, 
  md.name AS domain,
  mu.email,
  mu.active
FROM master_virtual_users mu
JOIN master_virtual_domains md ON mu.domain_id = md.id
JOIN mail_servers s ON mu.server_id = s.id;

CREATE OR REPLACE VIEW view_all_aliases AS
SELECT 
  ma.id, 
  s.hostname AS server, 
  md.name AS domain,
  ma.source,
  ma.destination
FROM master_virtual_aliases ma
JOIN master_virtual_domains md ON ma.domain_id = md.id
JOIN mail_servers s ON ma.server_id = s.id;

-- Create view for DKIM keys
CREATE OR REPLACE VIEW view_all_dkim_keys AS
SELECT 
  dk.id, 
  s.hostname AS server, 
  md.name AS domain,
  dk.selector,
  dk.dns_record
FROM master_dkim_keys dk
JOIN master_virtual_domains md ON dk.domain_id = md.id
JOIN mail_servers s ON dk.server_id = s.id;