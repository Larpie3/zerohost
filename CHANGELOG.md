# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.0] - 2026-01-11

### Added - Installation Modes & Hardened Backups 🎯

#### New Installation Modes

**1. Minimal Mode (`--minimal`)**
   - Installs only core components: Panel, MariaDB, PHP 8.2, Nginx, Redis, Docker
   - Skips all optional features: Cloudflare, SSL certificates, UFW firewall, Fail2ban, ModSecurity, phpMyAdmin, Tailscale, web hosting
   - Perfect for users who want to add security features manually or handle them differently
   - Fastest installation option for bare-bones setup
   - Usage: `sudo ./install.sh --minimal`

**2. Essentials Mode (`--essentials`)**
   - Designed specifically for Cloudflare users
   - Installs: Core components + Wings daemon + Tailscale VPN
   - Skips: SSL certificates (Cloudflare handles HTTPS at edge), firewall configuration, security extras
   - **Automatically runs Wings installer** with `--auto --tailscale --no-firewall` after panel installation
   - Complete working setup in one command for Cloudflare deployments
   - Usage: `sudo ./install.sh --essentials`

**3. Wings Installer Non-Interactive Flags**
   - `--auto`: Skip all prompts, use default settings (non-interactive mode)
   - `--tailscale`: Automatically install Tailscale VPN without prompting
   - `--no-firewall`: Skip UFW firewall configuration
   - Perfect for scripting and automation
   - Usage: `sudo ./install-wings.sh --auto --tailscale --no-firewall`

#### Hardened Factory Reset Backup Process

**Multiple Database Backup Fallback Methods:**
   - Primary method: Use `/root/.my.cnf` credentials if available
   - Fallback 1: Try `/etc/mysql/debian.cnf` credentials
   - Fallback 2: Attempt root access without credentials
   - Each method tries full database dump first, then panel-only as fallback
   - Creates `DATABASE_BACKUP_FAILED.txt` file if all methods fail
   - **Installation continues even if database backup fails** (previously would abort)

**Resilient Archive Creation:**
   - All `tar` backup commands now use `|| print_warning` instead of failing
   - Warnings displayed but backup process continues
   - If final archive creation fails, backup directory is still preserved
   - Users can manually create archive or access raw backup files
   - No data loss even if compression fails

**Preserved Backup Directory:**
   - Backup folder always preserved at `/var/backups/pterodactyl-full/full-backup-TIMESTAMP/`
   - Even if tar archive creation fails, all individual backup files remain intact
   - Manual recovery possible from backup directory
   - Instructions provided for manual archiving if automated archiving fails

### Changed

**Installation Flow:**
   - `--essentials` mode now automatically invokes Wings installer after panel setup
   - Wings installer checks for install-wings.sh script existence before running
   - Non-zero exit from Wings installer shows warning but doesn't fail main installation

**Backup Robustness:**
   - Database backup no longer uses nested conditional short-circuits
   - Clear success/failure tracking with `db_backup_success` variable
   - Each backup method attempted independently with proper error messages
   - User-friendly messages guide through each backup attempt

**Help Messages:**
   - Updated `--help` output with detailed mode descriptions
   - Added usage examples for all three installation modes
   - Wings installer now has comprehensive `--help` and `--version` flags
   - Better documentation of what each mode includes/excludes

### Documentation

**New Cloudflare Deployment Guide:**
   - Comprehensive step-by-step guide in CONFIGURATION.md
   - DNS configuration examples for panel and Wings nodes
   - SSL/TLS settings for Cloudflare dashboard
   - Post-installation Tailscale setup instructions
   - Advanced configurations: security rules, page rules, firewall rules
   - Optional origin certificate installation guide
   - Troubleshooting section for common Cloudflare issues

**Usage Examples & Scenarios:**
   - 7 real-world deployment scenarios in README.md
   - Scenario 1: Standard full-featured installation
   - Scenario 2: Cloudflare-hosted panel with Wings
   - Scenario 3: Bare minimum panel (add features later)
   - Scenario 4: Scripted/automated deployment
   - Scenario 5: Wings node on separate server
   - Scenario 6: Multi-node setup with Tailscale
   - Scenario 7: Development/testing environment
   - Each scenario includes complete commands and expected results

**Updated Documentation Files:**
   - README.md: New installation modes section, usage examples
   - INSTALL-NOW.md: Updated with v2.2.0 features and mode selection guide
   - CONFIGURATION.md: New Cloudflare deployment guide section (top of file)

### Fixed

**Backup System:**
   - Factory reset no longer aborts if mysqldump encounters warnings
   - Tar operations continue even if individual files have issues
   - Archive creation failure doesn't delete the backup directory
   - All error paths now preserve data and continue gracefully

### Backward Compatibility

- ✅ All changes are fully backward compatible
- ✅ Existing installations not affected unless using new flags
- ✅ Default interactive mode unchanged
- ✅ Configuration file format unchanged
- ✅ All existing scripts and workflows continue to work

---

## [2.1.2] - 2026-01-10

### Fixed - Production-Ready Installation 🚀

#### Critical Installation Improvements (12 Issues Resolved)
Performed deep trace analysis of entire installation flow and fixed all discovered issues.

**CRITICAL FIXES (Would Cause Installation Failures):**

1. **Redis Service Not Started Before Use** ✅
   - Issue: Pterodactyl setup tried to use Redis before it was running
   - Fix: Start and verify Redis immediately after installation in dependencies phase
   - Impact: Prevents artisan migration failures

2. **Nginx Started Before Configuration** ✅
   - Issue: Nginx enabled/started before configuration file was created
   - Fix: Delay Nginx start until after configuration is complete
   - Impact: Prevents service startup failures and conflicts

3. **No Error Checking on Downloads** ✅
   - Issue: curl failures went unnoticed, tar would fail on corrupt files
   - Fix: Added error checking, retry logic, and file size verification
   - Impact: Prevents cascading failures from network issues

4. **Silent Composer Failures** ✅
   - Issue: Composer install with `-q` flag hid critical errors
   - Fix: Removed `-q`, added exit code checking, show actual progress
   - Impact: Makes dependency installation issues visible and actionable

5. **Database Migration No Error Handling** ✅
   - Issue: Migration failures didn't stop installation, left DB in broken state
   - Fix: Check exit codes, return 1 on failure to trigger rollback
   - Impact: Prevents broken installations with incomplete database

6. **Admin Password Lost** ✅
   - Issue: Random password generated but never displayed to user
   - Fix: Save to `/root/.pterodactyl_admin_password` and display in summary
   - Impact: Users can now access their admin account!

**HIGH PRIORITY FIXES (Would Cause Runtime Issues):**

7. **pteroq Service Missing Database Dependency** ✅
   - Issue: Queue worker could start before MariaDB was ready
   - Fix: Added `After=mariadb.service` to systemd service file
   - Impact: Prevents queue worker crashes and failed jobs

8. **File Permissions Set Too Late** ✅
   - Issue: chown executed after artisan commands that create files
   - Fix: Set www-data permissions before running any artisan commands
   - Impact: Prevents permission-denied errors in Laravel

9. **Duplicate Cron Jobs on Re-run** ✅
   - Issue: Re-running script added duplicate cron entries
   - Fix: Check if cron job exists before adding
   - Impact: Prevents cron spam and multiple scheduler runs

**BEST PRACTICE IMPROVEMENTS:**

10. **No Cleanup of Old Downloads** ✅
    - Issue: Old panel.tar.gz files could cause corruption
    - Fix: `rm -f panel.tar.gz` before downloading
    - Impact: Ensures fresh, uncorrupted downloads every time

11. **No Service Status Verification** ✅
    - Issue: Services could fail to start silently
    - Fix: Added `systemctl is-active` checks after all service starts
    - Impact: Better error detection and user feedback

12. **Nginx Configuration Not Tested** ✅
    - Issue: Bad config could break nginx restart
    - Fix: Run `nginx -t` before starting, show errors if test fails
    - Impact: Prevents service failures from configuration errors

#### Additional Improvements

- **PHP-FPM Configuration**: Added file existence check before modifying config
- **PHP PPA Duplicate Prevention**: Check if ondrej/php PPA already exists
- **Service Startup Order**: Proper sequencing - Redis → PHP → MariaDB → Pterodactyl → Nginx
- **Error Messages**: More descriptive error output throughout installation
- **Progress Visibility**: Composer install now shows progress instead of being silent
- **Admin Credentials**: Password displayed prominently in installation summary

### Changed
- Removed `-q` (quiet) flag from composer install for better visibility
- Nginx now starts only after configuration is complete and tested
- Redis service started immediately after package installation
- File permissions set before artisan commands instead of after
- All critical operations now check exit codes and fail gracefully

### Security
- Admin password now securely saved with 600 permissions
- Better service isolation with proper systemd dependencies

## [2.1.1] - 2026-01-10

### Fixed - Critical MariaDB Compatibility 🔧

#### MariaDB Installation Error Resolution
- **CRITICAL FIX**: Resolved `ERROR 1356 (HY000)` - View 'mysql.user' references invalid table(s)
- **Modern MariaDB syntax**: Updated from deprecated `UPDATE mysql.user SET Password = PASSWORD(...)` to `ALTER USER 'root'@'localhost' IDENTIFIED BY '...'`
- **Backward compatibility**: Added fallback support for different MariaDB versions (10.4+)
- **Dual table support**: Works with both `mysql.user` and `mysql.global_priv` tables
- **Improved error handling**: Better handling of database operations during setup
- **Clean install support**: Added `IF NOT EXISTS` checks to prevent duplicate user errors

#### New Tools & Documentation
- **pre-install-check.sh**: System requirements verification tool before installation
  - OS version check (Ubuntu 20.04/22.04/24.04, Debian 11/12)
  - RAM, CPU, and disk space validation
  - Internet and DNS connectivity tests
  - Port availability checks (80, 443, 3306, 8080)
  - Existing installation detection
- **INSTALL-NOW.md**: Quick start guide for clean server installations
- **FIXES-APPLIED.md**: Detailed documentation of all fixes and improvements

#### Database Setup Improvements
- **Secure installation**: Modern MariaDB security best practices
- **Anonymous user removal**: Properly handles both `mysql.global_priv` and legacy tables
- **Remote root access**: Safely removes remote root login capabilities
- **Test database cleanup**: Removes test databases using modern syntax
- **Connection testing**: Validates database connectivity after setup

### Changed
- **MariaDB root password**: Now uses `ALTER USER` instead of deprecated `UPDATE` command
- **User creation**: Added conditional creation with `IF NOT EXISTS`
- **Error suppression**: Better 2>/dev/null handling for version compatibility
- **Database privileges**: Maintained full compatibility across MariaDB versions

### Documentation
- **Installation guides**: Clear step-by-step instructions for clean servers
- **Troubleshooting**: Added common issue resolution steps
- **Error explanations**: Detailed explanation of the mysql.user view error

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

## [2.2.0] - 2026-01-11

### Added - Essentials & Minimal Modes + Safer Factory Reset

#### New Installation Modes
- **`--minimal`**: Install only core components (Panel, MariaDB, PHP, Nginx, Redis, Docker). Skips Cloudflare integration, Let's Encrypt SSL, Fail2ban, ModSecurity, UFW firewall, phpMyAdmin, and web hosting.
- **`--essentials`**: Everything in `--minimal` plus automated Wings and Tailscale installation. Skips Cloudflare, SSL, Fail2ban, firewall, and other extras. Ideal for Cloudflare-terminated HTTPS.

#### Wings Installer Automation
- `install-wings.sh` now supports **`--auto`**, **`--tailscale`**, and **`--no-firewall`** flags for non-interactive installs.
- Auto mode skips prompts and proceeds with selected options.

#### Factory Reset & Backup Hardening
- Backup step no longer aborts on `mysqldump` or `tar` warnings; uses multiple credentials fallbacks and continues safely.
- Final archive creation warns and continues even if archive fails; backup directory is preserved.

#### Documentation & Help
- Updated help text to include `--minimal` and `--essentials`.
- README updated with quick usage examples for Cloudflare-based deployments.

### Notes
- Essentials mode configures Nginx for HTTP only (port 80). Use Cloudflare proxy to terminate HTTPS and set SSL mode to **Full (strict)** or add origin certs later.

[2.2.0]: https://github.com/Larpie3/zerohost/releases/tag/v2.2.0
