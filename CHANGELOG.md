# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2026-01-09

### Added - Web Hosting Feature 🌐

#### Dynamic Website Hosting
- **Web hosting option** - Host dynamic PHP websites alongside Pterodactyl
- **Domain-based hosting** - Configure website with custom domain and auto-SSL
- **IP-based hosting** - Fallback to port 8080 without domain
- **Multi-site support** - Host multiple websites on one server
- **`add-website` command** - Easy helper script for creating additional sites
- **PHP 8.2 support** - Full FastCGI integration for dynamic content
- **Sample landing page** - Beautiful gradient PHP page included
- **Nginx virtual hosts** - Automatic configuration generation
- **SSL integration** - Auto-configures HTTPS for website domains
- **Separate document root** - `/var/www/websites/` directory structure

#### Configuration
- **`ENABLE_WEB_HOSTING`** - Enable/disable in config file
- **`WEB_HOSTING_DOMAIN`** - Optional domain for website
- **Interactive prompts** - Guided setup during installation
- **Configuration template** - Updated `config.conf.example`

#### Management
- **add-website script** - `/usr/local/bin/add-website` for easy site creation
- **Multi-site management** - Create unlimited websites with domains or ports
- **Automatic permissions** - Sets correct www-data ownership
- **Nginx reload** - Auto-reloads configuration after changes

### Documentation
- **README.md updated** - Complete web hosting usage guide
- **Deployment instructions** - How to upload and deploy websites
- **Examples** - Domain-based and IP-based configurations

## [2.0.1] - 2026-01-09

### Added - Backup & Factory Reset Features 🏭

#### Full System Backup
- **`--full-backup` command** - Creates comprehensive backup of entire system
- **Complete data preservation** - All game servers, configs, certificates included
- **ALL Docker volumes** - Backs up every container volume (not just pterodactyl/wings)
- **Progress tracking** - Shows backup progress with volume counters
- **Restore instructions** - Included in every backup for easy recovery
- **Downloadable archive** - SCP command provided for easy download
- **System metadata** - Saves OS info, packages, network config, disk usage

#### Factory Reset Feature
- **`--factory-reset` or `--wipe` command** - Complete server cleanup with data safety
- **Automatic backup first** - Creates full backup before any deletion
- **Two-step confirmation** - Requires "WIPE SERVER" + "yes" for safety
- **Complete removal** - Pterodactyl, Wings, Docker, MariaDB, Nginx, PHP, Redis
- **Clean configuration** - Removes all related config files
- **Firewall reset** - Returns UFW to default state
- **Fresh Ubuntu state** - Ready for clean reinstall or restoration
- **Data preservation** - Backup stored separately and retrievable

#### Enhanced Backup System
- **Quick backup** - `--backup` for panel + database only
- **Full backup** - `--full-backup` for everything including game servers
- **Panel manager integration** - Options 6, 15, 16 for backup operations
- **Volume listing** - Shows all Docker volumes being backed up
- **Error handling** - Graceful failure for individual volumes

### Fixed
- **Game server backup coverage** - Now backs up ALL Docker volumes, not just filtered ones
- **Docker volume detection** - Removed restrictive grep filter for pterodactyl/wings naming
- **Backup completeness** - Ensures all game server data is captured

### Improved
- Factory reset UX with clear warning boxes and dual confirmation
- Backup process visibility with progress indicators
- Documentation with factory reset guide (FACTORY-RESET.md)
- Help text includes new factory reset and full backup options
- Panel manager menu expanded to 16 options

## [2.0.0] - 2026-01-09

### Added - Major Feature Release 🎉

#### Installation & Management
- **Installation Logging System** - Complete logs saved to `/var/log/pterodactyl-installer/`
- **Pre-flight System Checks** - Validates RAM, CPU, disk, ports, and internet before installation
- **Error Handling & Rollback** - Automatic rollback capability on installation failure
- **Progress Tracking** - Real-time progress bars and step counters
- **Configuration File Support** - Silent/automated installations with config files
- **State Management** - Can resume failed installations from last successful step

#### Command-Line Interface
- `--status` - Comprehensive health check and status report
- `--update` - Update Pterodactyl panel to latest version
- `--self-update` - Update installer script from repository
- `--backup` - Create complete backup of panel and database
- `--restore <path>` - Restore from backup file
- `--config <file>` - Silent installation with configuration file
- `--help` - Show detailed help message
- `--version` - Display installer version

#### System Intelligence
- **Resource Detection** - Auto-configures PHP-FPM based on available RAM
- **DNS Validation** - Verifies DNS before SSL certificate generation
- **SSL Validation** - Tests certificates after installation
- **Database Validation** - Confirms connection before proceeding
- **Panel Accessibility Test** - Validates panel is reachable after install
- **Conflict Detection** - Checks for Apache2 and other conflicting software

#### Security Hardening
- **Fail2ban Integration** - Automatic intrusion prevention setup
- **ModSecurity Support** - Optional web application firewall
- **SSH Hardening** - Secure SSH configuration
- **Automatic Security Updates** - Unattended security patch installation
- **Enhanced Firewall Rules** - Comprehensive UFW configuration

#### Backup & Recovery
- **Automated Backups** - Before updates and major operations
- **Backup Metadata** - Includes version info and timestamps
- **One-command Restore** - Easy restoration from backups
- **Pre-update Backups** - Automatic safety before panel updates

#### Post-Install Features
- **Health Check System** - Validates all services after installation
- **Service Status Monitoring** - Checks nginx, mariadb, redis, pteroq, docker, wings
- **Resource Monitoring** - Displays RAM, disk, and CPU usage
- **Pass/Fail Summary** - Clear validation results

#### User Experience
- **Interactive Management Menu** - New `panel-manager.sh` with 13 quick actions
- **Enhanced Progress Display** - Beautiful progress bars with percentages
- **Better Error Messages** - Descriptive errors with troubleshooting hints
- **Colored Output Enhancement** - Improved visual hierarchy
- **Spinner Animations** - Visual feedback during long operations

#### Documentation
- **config.conf.example** - Sample configuration file for silent installs
- **IMPROVEMENTS.md** - Complete feature documentation
- **Enhanced README** - Updated with all new features and commands
- **Inline Help** - Comprehensive `--help` documentation

### Changed
- **Version bumped to 2.0.0** - Major feature release
- **Installation flow redesigned** - Now includes pre-flight checks
- **All installation functions** - Now include progress tracking and rollback actions
- **PHP-FPM configuration** - Auto-optimized based on system RAM
- **SSL installation** - Now validates DNS first
- **Database setup** - Includes connection validation
- **Total steps calculation** - Dynamic based on selected components

### Improved
- Error handling throughout entire installation process
- Logging with timestamps and detailed context
- User prompts with better formatting and colors
- Service validation after installation
- Backup system with metadata tracking

### Fixed
- Potential failures due to DNS propagation delays
- Missing validation of critical services
- No recovery mechanism on partial installation failure
- Lack of installation progress visibility

## [1.0.0] - 2026-01-09

### Added
- Initial release of Pterodactyl Installer
- Panel installer with full Pterodactyl setup
- Wings installer for game server nodes
- Tailscale VPN integration
- Cloudflare SSL and proxy integration
- MariaDB database installation
- phpMyAdmin support
- UFW firewall configuration
- Let's Encrypt SSL certificates
- Automated queue worker setup
- Cron job configuration
- Docker installation and configuration
- Interactive installer with user prompts
- Comprehensive README documentation
- Configuration examples and templates
- Uninstaller script
- Support for Ubuntu 20.04, 22.04, 24.04
- Support for Debian 11, 12

[2.0.1]: https://github.com/Larpie3/zerohost/releases/tag/v2.0.1
[2.0.0]: https://github.com/Larpie3/zerohost/releases/tag/v2.0.0
[1.0.0]: https://github.com/Larpie3/zerohost/releases/tag/v1.0.0
