# Pterodactyl Advanced Installer

![Version](https://img.shields.io/badge/version-2.0.1-blue)
![License](https://img.shields.io/badge/license-MIT-green)

A comprehensive, feature-rich installer for Pterodactyl Panel and Wings with advanced integrations including Tailscale VPN, Cloudflare SSL/Proxy, and enterprise-grade features.

## ✨ New in v2.0

- 🔍 **Pre-flight system checks** - Validates requirements before installation
- 📊 **Installation logging** - Complete logs for troubleshooting
- ⏮️ **Rollback support** - Automatic rollback on failure  
- 📈 **Progress tracking** - Real-time installation progress
- ⚙️ **Configuration files** - Silent/automated installations
- 🔄 **Update mechanism** - Easy panel and script updates
- 💾 **Backup/Restore** - Quick and full backup options
- 🏭 **Factory Reset** - Backup everything and wipe to fresh state
- 🏥 **Health checks** - Post-install validation and status monitoring
- 🛡️ **Security hardening** - Fail2ban, ModSecurity, SSH hardening
- 🎯 **Auto-optimization** - System resource detection and auto-configuration

## 🚀 Features

### Panel Installer
- ✅ **Pterodactyl Panel** - Latest version installation
- ✅ **MariaDB** - Database server with secure configuration
- ✅ **Nginx** - Web server with optimized configuration
- ✅ **PHP 8.2** - With all required extensions
- ✅ **Redis** - Cache and queue management
- ✅ **Composer** - PHP dependency manager
- ✅ **Docker** - Container runtime
- ✅ **Let's Encrypt SSL** - Free SSL certificates with DNS validation
- ✅ **Tailscale VPN** - Secure mesh networking
- ✅ **Cloudflare Integration** - Real IP restoration and SSL
- ✅ **phpMyAdmin** - Database management interface
- ✅ **UFW Firewall** - Security configuration
- ✅ **Fail2ban** - Intrusion prevention
- ✅ **ModSecurity** - Web application firewall (optional)
- ✅ **Auto Updates** - Unattended security updates
- ✅ **SSH Hardening** - Enhanced SSH security
- ✅ **Automatic Queue Worker** - Background job processing
- ✅ **Cron Jobs** - Scheduled tasks
- ✅ **Smart Logging** - Detailed installation and error logs
- ✅ **Rollback System** - Auto-rollback on failure
- ✅ **Progress Tracking** - Real-time installation status
- ✅ **Pre-flight Checks** - System requirements validation
- ✅ **Post-install Validation** - Health checks after installation
- ✅ **Backup System** - Automated backup and restore
- ✅ **Auto-optimization** - Resource-based configuration

### Wings Installer
- ✅ **Pterodactyl Wings** - Latest version
- ✅ **Docker** - Container runtime
- ✅ **Tailscale Support** - VPN connectivity
- ✅ **Firewall Configuration** - UFW with game server ports
- ✅ **Kernel Optimizations** - Performance tuning
- ✅ **Common Game Ports** - Pre-configured for popular games

## 📋 Requirements

### Supported Operating Systems
- Ubuntu 20.04 LTS
- Ubuntu 22.04 LTS
- Ubuntu 24.04 LTS
- Debian 11
- Debian 12

### Minimum Server Specifications
**Panel:**
- 2 CPU cores
- 4 GB RAM
- 20 GB disk space
- Public IP address

**Wings Node:**
- 2 CPU cores
- 4 GB RAM (more recommended for game servers)
- 40 GB disk space
- Public IP address (or Tailscale)

## 🔧 Installation

### Panel Installation

1. **Download the installer:**
```bash
curl -sSL https://raw.githubusercontent.com/Larpie3/zerohost/main/install.sh -o install.sh
```

2. **Make it executable:**
```bash
chmod +x install.sh
```

3. **Run the installer (Interactive mode):**
```bash
sudo ./install.sh
```

4. **Or use configuration file (Silent mode):**
```bash
# Copy example config
cp config.conf.example config.conf

# Edit with your settings
nano config.conf

# Run silent installation
sudo ./install.sh --config config.conf
```

5. **Interactive prompts will guide you through:**
   - Pre-flight system checks
   - Domain and email configuration
   - Database password setup
   - Component selection:
     - MariaDB
     - phpMyAdmin
     - Tailscale VPN
     - Cloudflare integration
     - UFW firewall
     - Let's Encrypt SSL
     - Fail2ban
     - ModSecurity

The installer will automatically:
- Validate system requirements
- Check for conflicts
- Optimize based on your RAM
- Create installation logs
- Run post-install health checks

### Wings Installation

1. **Download the wings installer:**
```bash
curl -sSL https://raw.githubusercontent.com/Larpie3/zerohost/main/install-wings.sh -o install-wings.sh
```

2. **Make it executable:**
```bash
chmod +x install-wings.sh
```

3. **Run the installer:**
```bash
sudo ./install-wings.sh
```

4. **Configure Wings:**
   - Create a node in your Pterodactyl panel
   - Copy the auto-deploy command
   - Run it on your Wings server
   - Start Wings: `systemctl start wings`

## 🔐 Post-Installation

### Panel Setup

1. **Access your panel:**
   - Navigate to: `https://your-domain.com`
   - Login with the admin credentials displayed after installation

2. **Create your first location and node:**
   - Go to Admin Panel → Locations → Create New
   - Go to Admin Panel → Nodes → Create New

3. **Configure your first server:**
   - Create allocation for your node
   - Add a new server

### Cloudflare Setup (if enabled)

1. **DNS Configuration:**
   - Add an A record pointing to your server IP
   - Enable Cloudflare proxy (orange cloud icon)

2. **SSL/TLS Settings:**
   - Set SSL/TLS encryption mode to "Full (strict)"
   - Enable "Always Use HTTPS"

3. **Additional Security:**
   - Enable "Under Attack Mode" if needed
   - Configure firewall rules
   - Set up rate limiting

### Tailscale Setup (if enabled)

1. **Authenticate Tailscale:**
```bash
sudo tailscale up
```

2. **Access via Tailscale:**
   - Your server will be accessible via Tailscale IP
   - Useful for secure node-to-panel communication
   - No need to expose ports publicly

## 🛠️ Management Commands

### Interactive Management Menu
```bash
# Launch interactive management menu
sudo ./panel-manager.sh
```

This provides a user-friendly menu with options for:
- Check installation status
- View service status
- View logs
- Restart services
- Create backups (quick and full)
- Update panel
- Create admin users
- Download backups
- Factory reset with backup
- And more...

### Panel Management
```bash
# Check installation status
sudo ./install.sh --status

# Update panel to latest version
sudo ./install.sh --update

# Update installer script
sudo ./install.sh --self-update

# Create quick backup (panel + database)
sudo ./install.sh --backup

# Create FULL backup (panel, database, wings, docker volumes, SSL, configs)
sudo ./install.sh --full-backup

# Restore from backup
sudo ./install.sh --restore /path/to/backup

# Factory reset (backup everything, then wipe server clean)
sudo ./install.sh --factory-reset

# Show help
sudo ./install.sh --help

# Restart panel queue
sudo systemctl restart pteroq

# View queue logs
sudo journalctl -u pteroq -f

# Manual panel update
cd /var/www/pterodactyl
sudo php artisan p:upgrade

# Create admin user
sudo php artisan p:user:make
```

### Backup & Recovery

**Quick Backup** (Panel + Database only):
```bash
sudo ./install.sh --backup
```

**Full Backup** (Everything - Panel, Wings, Docker, SSL, Configs):
```bash
sudo ./install.sh --full-backup
```

**Download Backup to Local Machine:**
```bash
# Full backups are stored at: /var/backups/pterodactyl-full/
scp root@your-server:/var/backups/pterodactyl-full/full-backup-*.tar.gz .
```

**Factory Reset** (Clean slate with backup):
```bash
sudo ./install.sh --factory-reset
```

This will:
1. ✅ Create a complete backup of ALL data (panel, database, wings, docker volumes, SSL certificates, configs)
2. ✅ Save backup to `/var/backups/pterodactyl-full/`
3. ✅ Remove all Pterodactyl components
4. ✅ Remove Docker, MariaDB, Nginx, PHP
5. ✅ Clean all configuration files
6. ✅ Reset server to fresh Ubuntu state

**Your backup is preserved** and can be restored on the clean server or a new server!

**Restore on Fresh Server:**
```bash
# 1. Download backup from old server
scp root@old-server:/var/backups/pterodactyl-full/full-backup-*.tar.gz .

# 2. Transfer to new server
scp full-backup-*.tar.gz root@new-server:/tmp/

# 3. Extract and follow restore instructions
cd /tmp
tar -xzf full-backup-*.tar.gz
cat full-backup-*/RESTORE-INSTRUCTIONS.txt
```

### Wings Management
```bash
# Start Wings
sudo systemctl start wings

# Stop Wings
sudo systemctl stop wings

# Restart Wings
sudo systemctl restart wings

# View Wings logs
sudo journalctl -u wings -f

# Update Wings
sudo wings update
```

### Database Management
```bash
# Access MySQL
sudo mysql -u root -p

# Backup database
sudo mysqldump -u root -p panel > panel_backup.sql

# Restore database
sudo mysql -u root -p panel < panel_backup.sql

# Use built-in backup
sudo ./install.sh --backup
```

### System Logs & Monitoring
```bash
# View installation logs
sudo tail -f /var/log/pterodactyl-installer/install-*.log

# View error logs
sudo tail -f /var/log/pterodactyl-installer/error.log

# Check installation status
sudo ./install.sh --status

# View all service logs
sudo journalctl -xe
```

### Firewall Management
```bash
# Check firewall status
sudo ufw status

# Allow a port
sudo ufw allow 25565/tcp

# Delete a rule
sudo ufw delete allow 25565/tcp

# Reload firewall
sudo ufw reload
```

## 🎮 Pre-configured Game Ports

The Wings installer includes these common game server ports:

| Game | Port(s) | Protocol |
|------|---------|----------|
| Minecraft | 25565 | TCP/UDP |
| Source Games | 27015 | TCP/UDP |
| ARK/Unreal | 7777 | TCP/UDP |

Add more ports as needed for your specific games.

## 🔄 Updates

### Updating the Panel
```bash
cd /var/www/pterodactyl
sudo php artisan down
curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | sudo tar -xzv
sudo chmod -R 755 storage/* bootstrap/cache
sudo composer install --no-dev --optimize-autoloader
sudo php artisan view:clear
sudo php artisan config:clear
sudo php artisan migrate --seed --force
sudo chown -R www-data:www-data /var/www/pterodactyl/*
sudo php artisan queue:restart
sudo php artisan up
```

### Updating Wings
```bash
sudo systemctl stop wings
curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64"
sudo chmod u+x /usr/local/bin/wings
sudo systemctl start wings
```

## 📊 Monitoring

### Check Service Status
```bash
# Panel services
sudo systemctl status nginx
sudo systemctl status mariadb
sudo systemctl status redis
sudo systemctl status pteroq

# Wings services
sudo systemctl status wings
sudo systemctl status docker
```

### Resource Monitoring
```bash
# CPU and Memory
htop

# Disk usage
df -h

# Docker containers
sudo docker ps
sudo docker stats
```

## 🐛 Troubleshooting

### Using Built-in Status Check
```bash
sudo ./install.sh --status
```
This will show:
- Service status (nginx, mariadb, redis, etc.)
- Port availability
- System resources
- Log locations

### Panel Issues

**Cannot access panel:**
- Run `sudo ./install.sh --status` to check all services
- Check Nginx: `sudo systemctl status nginx`
- Check SSL certificate: `sudo certbot certificates`
- Verify DNS is pointing to server
- Check firewall: `sudo ufw status`
- Review logs: `sudo tail -f /var/log/pterodactyl-installer/error.log`

**Queue not processing:**
- Restart queue worker: `sudo systemctl restart pteroq`
- Check logs: `sudo journalctl -u pteroq -f`

**Database connection error:**
- Verify MariaDB is running: `sudo systemctl status mariadb`
- Check credentials in `/var/www/pterodactyl/.env`
- Test connection manually

**Installation failed:**
- Check error log: `/var/log/pterodactyl-installer/error.log`
- Review installation log: `/var/log/pterodactyl-installer/install-*.log`
- The installer may have attempted auto-rollback
- You can manually restore from backup if created

### Wings Issues

**Wings won't start:**
- Check config: `sudo wings configure`
- Verify Docker is running: `sudo systemctl status docker`
- Check logs: `sudo journalctl -u wings -f`

**Network issues:**
- Verify ports are open: `sudo ufw status`
- Check Docker network: `sudo docker network ls`
- Test connectivity from panel

## 🔒 Security Recommendations

1. **Keep everything updated:**
   - Regularly update OS packages
   - Update Pterodactyl panel and Wings
   - Update Docker

2. **Use strong passwords:**
   - Database passwords
   - Admin panel passwords
   - SFTP passwords

3. **Enable 2FA:**
   - Use two-factor authentication for admin accounts

4. **Firewall rules:**
   - Only open necessary ports
   - Use Tailscale for private communication
   - Consider using Cloudflare for DDoS protection

5. **Backups:**
   - Regular database backups
   - Panel file backups
   - Wings configuration backups

## 📝 Default Ports

| Service | Port | Purpose |
|---------|------|---------|
| Nginx (HTTP) | 80 | Web server |
| Nginx (HTTPS) | 443 | Secure web server |
| Wings API | 8080 | Wings daemon API |
| SFTP | 2022 | File transfer |
| phpMyAdmin | 8081 | Database management |
| Tailscale | 41641 | VPN (UDP) |

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## ⚠️ Disclaimer

This installer is provided as-is. Always backup your data and test in a non-production environment first. The authors are not responsible for any damage or data loss.

## 🆘 Support

For issues and questions:
- Open an issue on GitHub
- Check Pterodactyl documentation: https://pterodactyl.io/
- Join Pterodactyl Discord: https://discord.gg/pterodactyl

## 🙏 Credits

- [Pterodactyl Panel](https://pterodactyl.io/) - The awesome game server management panel
- [Tailscale](https://tailscale.com/) - Secure mesh VPN
- [Cloudflare](https://cloudflare.com/) - CDN and security services
- ForestRacks - Inspiration for the original installer

---

Made with ❤️ for the Pterodactyl community