# Quick Reference Card

## Installation

```bash
# Interactive Installation
sudo ./install.sh

# Silent Installation
sudo ./install.sh --config config.conf

# Check what will be installed (dry-run)
sudo ./install.sh --help
```

## Management

```bash
# Launch interactive menu
sudo ./panel-manager.sh

# Check status
sudo ./install.sh --status

# Update panel
sudo ./install.sh --update

# Create backup
sudo ./install.sh --backup

# Restore backup
sudo ./install.sh --restore /root/pterodactyl-backups/backup-XXXXXXXX
```

## Service Control

```bash
# Restart all services
sudo systemctl restart nginx mariadb redis-server pteroq

# Check service status
sudo systemctl status nginx
sudo systemctl status mariadb
sudo systemctl status pteroq
sudo systemctl status docker

# View logs
sudo journalctl -u pteroq -f
sudo journalctl -u nginx -f
```

## Common Tasks

```bash
# Create admin user
cd /var/www/pterodactyl
sudo php artisan p:user:make

# Restart queue worker
sudo systemctl restart pteroq

# Check firewall
sudo ufw status

# View installation logs
sudo tail -f /var/log/pterodactyl-installer/install-*.log

# View errors
sudo tail -f /var/log/pterodactyl-installer/error.log
```

## File Locations

| Type | Location |
|------|----------|
| Panel Files | `/var/www/pterodactyl` |
| Panel Config | `/var/www/pterodactyl/.env` |
| Nginx Config | `/etc/nginx/sites-available/pterodactyl.conf` |
| PHP Config | `/etc/php/8.2/fpm/pool.d/www.conf` |
| Install Logs | `/var/log/pterodactyl-installer/` |
| Backups | `/root/pterodactyl-backups/` |
| SSL Certs | `/etc/letsencrypt/live/` |

## Troubleshooting

```bash
# Full system check
sudo ./install.sh --status

# Check all services
sudo ./panel-manager.sh  # Option 2

# View recent errors
sudo ./panel-manager.sh  # Option 9

# Test database connection
sudo mysql -u pterodactyl -p -h 127.0.0.1

# Check SSL certificate
sudo certbot certificates

# Test panel accessibility
curl -I https://your-domain.com
```

## URLs

| Service | URL |
|---------|-----|
| Panel | `https://your-domain.com` |
| phpMyAdmin | `http://server-ip:8081` |
| Wings API | `http://server-ip:8080` |

## Emergency Commands

```bash
# Restore from backup
sudo ./install.sh --restore /path/to/backup

# Stop all services
sudo systemctl stop nginx mariadb redis-server pteroq

# Start all services
sudo systemctl start nginx mariadb redis-server pteroq

# Check disk space
df -h

# Check memory usage
free -h

# Check running processes
htop
```

## Update Commands

```bash
# Update panel (with auto-backup)
sudo ./install.sh --update

# Update installer script
sudo ./install.sh --self-update

# Update system packages
sudo apt update && sudo apt upgrade -y
```

## Configuration Files

```bash
# Panel environment
sudo nano /var/www/pterodactyl/.env

# Nginx configuration
sudo nano /etc/nginx/sites-available/pterodactyl.conf

# PHP-FPM configuration
sudo nano /etc/php/8.2/fpm/pool.d/www.conf

# Firewall rules
sudo ufw status numbered
```

## Security

```bash
# Check fail2ban status
sudo fail2ban-client status

# Check SSH configuration
sudo nano /etc/ssh/sshd_config

# View firewall rules
sudo ufw status verbose

# Check for updates
sudo apt list --upgradable
```

## Quick Diagnosis

**Panel not loading?**
1. `sudo systemctl status nginx`
2. `sudo ./install.sh --status`
3. `sudo tail -f /var/log/nginx/error.log`

**Queue not processing?**
1. `sudo systemctl restart pteroq`
2. `sudo journalctl -u pteroq -f`

**Database issues?**
1. `sudo systemctl status mariadb`
2. `sudo mysql -u root -p`

**SSL issues?**
1. `sudo certbot certificates`
2. `sudo certbot renew --dry-run`

---

**For full documentation, run:** `sudo ./install.sh --help`
