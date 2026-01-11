# 🎯 Ready to Install - v2.2.0 Production Ready!

## ✅ All Issues Fixed + New Installation Modes!

**v2.2.0** adds flexible installation modes and safer backups on top of the 12 critical fixes from v2.1.2:

### 🆕 New in v2.2.0:
- 🟩 **--minimal mode**: Core components only (Panel, DB, PHP, Nginx, Redis, Docker)
- 🟩 **--essentials mode**: Core + Wings + Tailscale, perfect for Cloudflare users
- 🛡️ **Hardened backups**: Factory reset continues even if warnings occur
- 🔧 **Wings automation**: `--auto`, `--tailscale`, `--no-firewall` flags for scripting

### ❌ Issues That Are Now Fixed (v2.1.2):
- ✅ Redis service race condition (prevented migration failures)
- ✅ Nginx startup timing (prevented service failures)
- ✅ Download failures (network issues handled gracefully)
- ✅ Silent composer failures (now visible with progress)
- ✅ Database migration errors (proper rollback on failure)
- ✅ **Lost admin password (NOW DISPLAYED AND SAVED!)**
- ✅ Queue worker dependencies (no more crashes)
- ✅ File permission timing (no more Laravel errors)
- ✅ Duplicate cron jobs (clean re-runs)
- ✅ Stale downloads (fresh files every time)
- ✅ Service verification (failures detected immediately)
- ✅ Nginx config testing (prevents startup failures)

### 🎉 What You'll Experience:
- ✅ **Admin password displayed at the end** (saved to `/root/.pterodactyl_admin_password`)
- ✅ Visible composer progress (no more wondering if it's stuck)
- ✅ Better error messages (know exactly what failed)
- ✅ Service status confirmations (see what's running)
- ✅ Automatic rollback if something fails
- ✅ Proper service ordering (no race conditions)

## 🚀 Installation on Your Clean Server

Since you factory reset your server, choose the installation mode that fits your setup:

### Option 1: Standard Interactive Install
```bash
sudo ./install.sh
```
Full installation with all prompts - choose exactly what you want.

### Option 2: Minimal Install (Core Only)
```bash
sudo ./install.sh --minimal
```
**Installs:** Panel, MariaDB, PHP, Nginx, Redis, Docker  
**Skips:** Cloudflare, SSL, firewall, Fail2ban, ModSecurity, phpMyAdmin, Tailscale, web hosting  
**Best for:** Adding security/extras manually later

### Option 3: Essentials Install (Cloudflare-Ready)
```bash
sudo ./install.sh --essentials
```
**Installs:** Core + Wings + Tailscale  
**Skips:** SSL (Cloudflare handles it), firewall, security extras  
**Auto-runs:** Wings installer with `--auto --tailscale --no-firewall`  
**Best for:** Using Cloudflare proxy + SSL termination

**📖 Full Cloudflare setup guide:** See [CONFIGURATION.md](CONFIGURATION.md) → Cloudflare Deployment Guide

### 1. Run Pre-Check (Optional but Recommended)
```bash
sudo ./pre-install-check.sh
```

### 2. Start Installation
```bash
sudo ./install.sh
```

### 3. Answer the Prompts
The installer will ask for:
- **FQDN** (e.g., panel.yourdomain.com)
- **Email** (for SSL certificates)
- **Database Password** (create a strong one)
- **Optional Features** (Tailscale, phpMyAdmin, etc.)

## ⚡ Quick Install (if you know what you want)

Create a config file first:
```bash
nano config.conf
```

Add your settings:
```bash
INSTALL_MARIADB=true
FQDN="panel.yourdomain.com"
EMAIL="your@email.com"
DB_PASSWORD="YourStrongPasswordHere"
```

Then run:
```bash
sudo ./install.sh --config config.conf
```

## 📊 System Requirements (Your Clean Server Should Meet These)

- ✅ Ubuntu 20.04/22.04/24.04 or Debian 11/12
- ✅ 2GB+ RAM (4GB recommended)
- ✅ 2+ CPU cores
- ✅ 20GB+ disk space
- ✅ Internet connection
- ✅ Ports 80, 443 open (for web access)

## 🔒 What Gets Installed

**Standard mode includes:**
1. **MariaDB** - Database server (with the fixes!)
2. **PHP 8.2** - With all required extensions
3. **Nginx** - Web server
4. **Docker** - For game server containers
5. **Pterodactyl Panel** - Latest version
6. **SSL/TLS** - Free Let's Encrypt certificates (if enabled)
7. **Redis** - Caching server
8. **Optional**: phpMyAdmin, Fail2ban, ModSecurity, Tailscale

**Minimal mode (`--minimal`):**
- Panel, MariaDB, PHP, Nginx, Redis, Docker only

**Essentials mode (`--essentials`):**
- All minimal components + Wings + Tailscale (auto-installed)

## 🎮 Installing Wings Node

### Interactive Install:
```bash
curl -sSL https://raw.githubusercontent.com/Larpie3/zerohost/main/install-wings.sh -o install-wings.sh
chmod +x install-wings.sh
sudo ./install-wings.sh
```

### Automated Install (No Prompts):
```bash
sudo ./install-wings.sh --auto --tailscale --no-firewall
```

**Flags:**
- `--auto`: Skip all prompts, use defaults
- `--tailscale`: Automatically install Tailscale VPN
- `--no-firewall`: Skip UFW firewall configuration

**Note:** When using `--essentials` mode, Wings is installed automatically!

## 📝 Installation Time

- Basic installation: ~10-15 minutes
- With all options: ~20-25 minutes

## ✨ After Installation

The script will show you:
- Panel URL (https://your-domain.com)
- Admin user creation command
- Next steps

## 🆘 If Something Goes Wrong

Check the logs:
```bash
tail -f /var/log/pterodactyl-installer/install-*.log
```

Need to retry? Uninstall first:
```bash
sudo ./uninstall.sh
sudo ./install.sh
```

---

## 🎉 You're All Set!

Your scripts are fixed and ready. The MariaDB error is solved. 
Just run `sudo ./install.sh` and follow the prompts!

Good luck with your installation! 🚀
