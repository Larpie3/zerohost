# ZeroHost v2.2.0 Release Notes

## 🎯 New Installation Modes

### --essentials Mode
Perfect for Cloudflare-fronted deployments:
```bash
sudo ./install.sh --essentials
```

**Includes:**
- ✅ Pterodactyl Panel
- ✅ MariaDB database
- ✅ PHP 8.2 + extensions
- ✅ Nginx (HTTP only, port 80)
- ✅ Redis cache
- ✅ Docker runtime
- ✅ Wings node daemon
- ✅ Tailscale VPN

**Skips:**
- ❌ Cloudflare integration scripts
- ❌ Let's Encrypt SSL (Cloudflare handles HTTPS)
- ❌ UFW firewall
- ❌ Fail2ban
- ❌ ModSecurity
- ❌ phpMyAdmin
- ❌ Web hosting

**Use Case:** When you want Cloudflare to terminate HTTPS at the edge and only install the essentials to run Pterodactyl.

### --minimal Mode
Core panel-only installation:
```bash
sudo ./install.sh --minimal
```

Same as essentials but **without Wings and Tailscale**. Add them later with:
```bash
sudo ./install-wings.sh --auto --tailscale --no-firewall
```

## 🔧 Wings Installer Automation

New non-interactive flags for `install-wings.sh`:

```bash
sudo ./install-wings.sh --auto --tailscale --no-firewall
```

- `--auto` - Skip all prompts, proceed with selected options
- `--tailscale` - Install Tailscale VPN
- `--no-firewall` - Skip UFW firewall configuration

## 🛡️ Safer Factory Reset

Backup process hardened to never abort:

- Multiple fallback credentials for `mysqldump` (`/root/.my.cnf`, `/etc/mysql/debian.cnf`, root)
- All tar operations warn and continue on minor errors
- Final archive creation warns if it fails; backup directory is preserved
- Factory reset now completes successfully even if individual backup steps encounter warnings

## 📚 Cloudflare Deployment Guide

1. **Run essentials install:**
   ```bash
   sudo ./install.sh --essentials
   ```

2. **Point Cloudflare DNS to your server IP and enable proxy (orange cloud)**

3. **Set Cloudflare SSL/TLS mode to "Full (strict)"** (optionally install origin certs later)

4. **Connect Tailscale:**
   ```bash
   sudo tailscale up
   ```

5. **Configure Wings from your panel and start:**
   ```bash
   systemctl start wings
   ```

## 🔄 Upgrade Path

From any previous version:
```bash
cd /path/to/zerohost
git pull origin main
# No changes to existing installations
```

The new modes are opt-in via command-line flags only.

## 📝 Full Changelog

See [CHANGELOG.md](CHANGELOG.md) for complete details.

---

**Questions?** Open an issue on GitHub or check the updated [README.md](README.md) for usage examples.
