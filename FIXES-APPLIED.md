# Fresh Installation Guide for Clean Server

## ✅ Fixes Applied

The following critical issues have been fixed for your clean server installation:

### 1. **MariaDB Compatibility (CRITICAL FIX)**
- ✅ Fixed the `mysql.user` view error you encountered
- ✅ Updated from deprecated `UPDATE mysql.user SET Password = PASSWORD(...)` 
- ✅ Now uses modern `ALTER USER 'root'@'localhost' IDENTIFIED BY '...'` syntax
- ✅ Added fallback support for different MariaDB versions
- ✅ Updated to use `mysql.global_priv` table when available

### 2. **Database User Creation**
- ✅ Added `IF NOT EXISTS` checks to prevent errors on clean installs
- ✅ Improved error handling for database operations

### 3. **Compatibility**
- ✅ Works with MariaDB 10.4+ (modern versions)
- ✅ Backward compatible with older MariaDB versions
- ✅ Ubuntu 20.04, 22.04, 24.04 supported
- ✅ Debian 11, 12 supported

## 🚀 Installation Steps for Your Clean Server

### Step 1: Pre-Installation Check (Recommended)
```bash
sudo ./pre-install-check.sh
```
This will verify your system meets all requirements before installation.

### Step 2: Run the Installer
```bash
sudo ./install.sh
```

### Step 3: Follow the Interactive Prompts
The installer will ask you for:
- Domain name (FQDN)
- Email address
- Database password
- Optional components (Tailscale, Cloudflare, etc.)

## 📋 What Was Wrong

The error you saw:
```
ERROR 1356 (HY000) at line 1: View 'mysql.user' references invalid table(s) 
or column(s) or function(s) or definer/invoker of view lack rights to use them
```

**Cause**: The script was using old MySQL 5.x syntax that doesn't work with modern MariaDB:
```sql
UPDATE mysql.user SET Password = PASSWORD('...') WHERE User = 'root'
```

**Fixed**: Now uses modern MariaDB-compatible syntax:
```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'password';
```

## 🔧 If You Already Have MariaDB Installed

If you already installed MariaDB and encountered the error, run this to fix it:

```bash
# Set the root password manually
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'YOUR_PASSWORD_HERE';"

# Or if that doesn't work, try:
sudo mysql_secure_installation
```

Then run the installer again.

## ✨ New Features Available

Your installer now supports:
- ✅ MariaDB with automatic secure setup
- ✅ PHP 8.2 with optimal configuration
- ✅ Docker for game servers
- ✅ Nginx with automatic SSL (Let's Encrypt)
- ✅ Tailscale VPN integration
- ✅ Cloudflare integration
- ✅ phpMyAdmin (optional)
- ✅ Fail2ban security (optional)
- ✅ ModSecurity WAF (optional)
- ✅ Automatic backups
- ✅ System resource auto-detection

## 📝 Silent/Automated Installation

You can also use a configuration file for automated installation:

1. Copy the example config:
```bash
cp config.conf.example config.conf
```

2. Edit the config file with your settings

3. Run with config:
```bash
sudo ./install.sh --config config.conf
```

## 🆘 Troubleshooting

### If installation fails:
Check the logs:
```bash
tail -f /var/log/pterodactyl-installer/install-*.log
tail -f /var/log/pterodactyl-installer/error.log
```

### If you need to start over:
```bash
sudo ./uninstall.sh
```

## ⚡ Quick Tips

1. **Use a clean server** - Factory reset was a good choice!
2. **Update first**: `sudo apt update && sudo apt upgrade -y`
3. **Set a strong database password** when prompted
4. **Use a valid domain name** for SSL to work
5. **Open required ports** in your firewall/cloud provider

## 📞 Support

If you encounter issues:
1. Check `/var/log/pterodactyl-installer/error.log`
2. Review the output of `./pre-install-check.sh`
3. Ensure all ports are accessible (80, 443, 3306, 8080)

---

**Ready to install!** Your scripts are now fixed and ready for your clean server. 🎉
