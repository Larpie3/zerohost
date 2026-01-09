# ZeroHost Configuration Examples

## Cloudflare SSL Configuration

For optimal security with Cloudflare, use these settings:

### Cloudflare Dashboard Settings
1. **SSL/TLS → Overview**
   - Encryption mode: Full (strict)

2. **SSL/TLS → Edge Certificates**
   - Always Use HTTPS: ON
   - Minimum TLS Version: 1.2
   - Opportunistic Encryption: ON
   - TLS 1.3: ON
   - Automatic HTTPS Rewrites: ON

3. **Security → Settings**
   - Security Level: Medium
   - Challenge Passage: 30 minutes
   - Browser Integrity Check: ON

### DNS Configuration
```
Type: A
Name: panel (or @)
IPv4: YOUR_SERVER_IP
Proxy: Enabled (Orange Cloud)
TTL: Auto
```

## Tailscale Configuration

### Basic Setup
```bash
# Install and authenticate
sudo tailscale up

# With custom settings
sudo tailscale up --accept-routes --accept-dns=false

# Check status
sudo tailscale status

# Get IP
sudo tailscale ip -4
```

### Panel-to-Node via Tailscale
In your node configuration on the panel, use the Tailscale IP instead of public IP:
```
FQDN: 100.x.x.x (Tailscale IP)
```

## Nginx Custom Configuration

### Rate Limiting
Add to `/etc/nginx/conf.d/rate-limit.conf`:
```nginx
limit_req_zone $binary_remote_addr zone=panel_limit:10m rate=10r/s;
limit_req zone=panel_limit burst=20 nodelay;
```

### Additional Security Headers
Add to server block:
```nginx
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
```

## Database Optimization

### MariaDB Configuration
Edit `/etc/mysql/mariadb.conf.d/50-server.cnf`:
```ini
[mysqld]
# Performance
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
innodb_flush_method = O_DIRECT
innodb_file_per_table = 1

# Connection
max_connections = 500
connect_timeout = 10
wait_timeout = 600

# Query Cache
query_cache_type = 1
query_cache_size = 64M
query_cache_limit = 2M
```

Restart MariaDB:
```bash
sudo systemctl restart mariadb
```

## Firewall Rules for Specific Games

### Minecraft
```bash
sudo ufw allow 25565/tcp
sudo ufw allow 25565/udp
```

### FiveM (GTA V)
```bash
sudo ufw allow 30120/tcp
sudo ufw allow 30120/udp
```

### Rust
```bash
sudo ufw allow 28015/tcp
sudo ufw allow 28015/udp
sudo ufw allow 28016/tcp
```

### CS:GO / Source Games
```bash
sudo ufw allow 27015/tcp
sudo ufw allow 27015/udp
sudo ufw allow 27020/udp
```

### Valheim
```bash
sudo ufw allow 2456:2458/tcp
sudo ufw allow 2456:2458/udp
```

## Backup Scripts

### Panel Backup
Create `/root/backup-panel.sh`:
```bash
#!/bin/bash
BACKUP_DIR="/root/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup database
mysqldump -u root -p"YOUR_PASSWORD" panel > $BACKUP_DIR/panel_db_$DATE.sql

# Backup panel files
tar -czf $BACKUP_DIR/panel_files_$DATE.tar.gz /var/www/pterodactyl

# Remove backups older than 7 days
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
```

Make executable and add to cron:
```bash
chmod +x /root/backup-panel.sh
crontab -e
# Add: 0 2 * * * /root/backup-panel.sh
```

## Wings Configuration Template

Example `/etc/pterodactyl/config.yml`:
```yaml
debug: false
uuid: YOUR_NODE_UUID
token_id: YOUR_TOKEN_ID
token: YOUR_TOKEN
api:
  host: 0.0.0.0
  port: 8080
  ssl:
    enabled: false
  upload_limit: 100
system:
  root_directory: /var/lib/pterodactyl/volumes
  log_directory: /var/log/pterodactyl
  data: /etc/pterodactyl
  sftp:
    bind_port: 2022
allowed_mounts: []
remote: https://panel.example.com
```

## Environment Variables

Useful environment variables for `/var/www/pterodactyl/.env`:

```env
# Application
APP_ENV=production
APP_DEBUG=false
APP_TIMEZONE=UTC
APP_URL=https://panel.example.com

# Cache
CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis

# Redis
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

# Database
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=panel
DB_USERNAME=pterodactyl
DB_PASSWORD=YOUR_PASSWORD

# Mail (Example: Gmail SMTP)
MAIL_DRIVER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password
MAIL_ENCRYPTION=tls
MAIL_FROM=your-email@gmail.com
```

## Performance Tuning

### PHP-FPM Optimization
Edit `/etc/php/8.2/fpm/pool.d/www.conf`:
```ini
pm = dynamic
pm.max_children = 50
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20
pm.max_requests = 500
```

Restart PHP-FPM:
```bash
sudo systemctl restart php8.2-fpm
```

### System Limits
Add to `/etc/security/limits.conf`:
```
* soft nofile 65536
* hard nofile 65536
```

## Monitoring Setup

### Install Netdata
```bash
bash <(curl -Ss https://my-netdata.io/kickstart.sh)
```

Access at: `http://YOUR_IP:19999`

### Basic Monitoring Commands
```bash
# System resources
htop

# Disk usage
df -h
du -sh /var/www/pterodactyl

# Network connections
netstat -tulpn

# Docker stats
docker stats

# Service logs
journalctl -u pteroq -f
journalctl -u wings -f
journalctl -u nginx -f
```
