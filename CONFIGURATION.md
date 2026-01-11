# ZeroHost Configuration Examples

## 🌐 Cloudflare Deployment Guide

### Quick Start with Essentials Mode

The `--essentials` mode is specifically designed for Cloudflare users who want Cloudflare to handle SSL/HTTPS:

```bash
sudo ./install.sh --essentials
```

**What it does:**
- ✅ Installs Panel, MariaDB, PHP 8.2, Nginx (HTTP only), Redis, Docker
- ✅ Automatically installs Wings daemon
- ✅ Installs Tailscale VPN for secure node communication
- ❌ Skips Let's Encrypt SSL (Cloudflare handles it)
- ❌ Skips UFW firewall (Cloudflare protects you)
- ❌ Skips Fail2ban, ModSecurity, phpMyAdmin
- ⚡ Runs Wings installer automatically with `--auto --tailscale --no-firewall`

### Step-by-Step Cloudflare Setup

#### 1. Prepare Your Server
```bash
# Download the installer
curl -sSL https://raw.githubusercontent.com/Larpie3/zerohost/main/install.sh -o install.sh
chmod +x install.sh

# Run essentials mode
sudo ./install.sh --essentials
```

#### 2. Configure DNS in Cloudflare
**Before running the installer, set up DNS:**
```
Type: A
Name: panel (creates panel.yourdomain.com)
IPv4: YOUR_SERVER_PUBLIC_IP
Proxy: Enabled (🟠 Orange Cloud)
TTL: Auto
```

**For the Wings node (same server):**
```
Type: A
Name: node1 (or @)
IPv4: YOUR_SERVER_PUBLIC_IP
Proxy: Disabled (☁️ Gray Cloud - DNS only)
TTL: Auto
```

> **Important:** Wings node should NOT be proxied through Cloudflare as game servers need direct connections.

#### 3. Cloudflare SSL/TLS Settings

Navigate to **SSL/TLS → Overview**:
- **Encryption mode:** Full (strict)

Navigate to **SSL/TLS → Edge Certificates**:
- ✅ Always Use HTTPS: ON
- ✅ Minimum TLS Version: 1.2
- ✅ Opportunistic Encryption: ON
- ✅ TLS 1.3: ON
- ✅ Automatic HTTPS Rewrites: ON
- ✅ Certificate Transparency Monitoring: ON

#### 4. Post-Installation Configuration

**Activate Tailscale:**
```bash
sudo tailscale up
# Note your Tailscale IP (usually 100.x.x.x)
sudo tailscale ip -4
```

**Check Services:**
```bash
systemctl status nginx
systemctl status wings
systemctl status pteroq
```

**Access Your Panel:**
- Navigate to: `https://panel.yourdomain.com`
- Cloudflare automatically provides HTTPS
- No SSL certificates needed on your server!

#### 5. Configure Node in Panel

When creating your node in the Pterodactyl panel:

**Option A: Public IP (not proxied through Cloudflare)**
```
FQDN: node1.yourdomain.com
Listen Port: 8080
SFTP Port: 2022
```

**Option B: Tailscale IP (recommended for security)**
```
FQDN: 100.x.x.x (your Tailscale IP)
Listen Port: 8080
SFTP Port: 2022
```

### Advanced Cloudflare Configuration

#### Security Rules

**Rate Limiting (recommended):**
```
If: URI Path equals /api/
Then: Rate Limit 100 requests per minute
```

**Block Known Bots:**
```
If: Known Bots
Then: Challenge (Managed Challenge)
```

#### Page Rules

**Cache Panel Assets:**
```
URL: panel.yourdomain.com/assets/*
Settings:
  - Cache Level: Standard
  - Edge Cache TTL: 1 month
```

**Bypass Panel API:**
```
URL: panel.yourdomain.com/api/*
Settings:
  - Cache Level: Bypass
```

#### Firewall Rules

**Allow Only Cloudflare IPs (optional but recommended):**
Since Cloudflare proxies traffic, configure your server firewall:
```bash
# Install UFW manually if needed
sudo apt install -y ufw

# Allow SSH
sudo ufw allow 22/tcp

# Allow Cloudflare IPs only for HTTP/HTTPS
# (Cloudflare updates their IP ranges, so use their script)
curl -sSL https://www.cloudflare.com/ips-v4 | while read ip; do
    sudo ufw allow from $ip to any port 80 proto tcp
    sudo ufw allow from $ip to any port 443 proto tcp
done

# Allow Wings ports (not proxied)
sudo ufw allow 8080/tcp
sudo ufw allow 2022/tcp

# Allow Tailscale
sudo ufw allow 41641/udp

# Enable firewall
sudo ufw --force enable
```

### Optional: Origin Certificates

If you want extra security, install Cloudflare Origin Certificates:

#### 1. Generate Origin Certificate in Cloudflare
- Go to **SSL/TLS → Origin Server**
- Click **Create Certificate**
- Select **RSA (2048)**, 15 years validity
- Copy both the certificate and private key

#### 2. Install on Your Server
```bash
# Create certificate directory
sudo mkdir -p /etc/ssl/cloudflare

# Save certificate
sudo nano /etc/ssl/cloudflare/cert.pem
# Paste certificate, save and exit

# Save private key
sudo nano /etc/ssl/cloudflare/key.pem
# Paste private key, save and exit

# Set permissions
sudo chmod 600 /etc/ssl/cloudflare/key.pem
```

#### 3. Update Nginx Configuration
```bash
sudo nano /etc/nginx/sites-available/pterodactyl.conf
```

Change:
```nginx
server {
    listen 80;
    server_name panel.yourdomain.com;
    # ... rest of config
}
```

To:
```nginx
server {
    listen 80;
    listen 443 ssl http2;
    server_name panel.yourdomain.com;
    
    ssl_certificate /etc/ssl/cloudflare/cert.pem;
    ssl_certificate_key /etc/ssl/cloudflare/key.pem;
    
    # ... rest of config
}
```

Restart Nginx:
```bash
sudo nginx -t && sudo systemctl restart nginx
```

Now Cloudflare SSL/TLS mode "Full (strict)" will work with origin certificates!

### Troubleshooting

**Issue: Panel shows "Too many redirects"**
- Solution: Check Cloudflare SSL/TLS is set to "Full" or "Full (strict)", not "Flexible"

**Issue: Can't connect to Wings node**
- Solution: Make sure node DNS is NOT proxied (gray cloud ☁️)
- Or use Tailscale IP instead

**Issue: Panel loads slowly**
- Solution: Enable Cloudflare caching for `/assets/*`
- Check Cloudflare → Speed → Optimization settings

**Issue: API requests failing**
- Solution: Add Page Rule to bypass cache for `/api/*`

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
