#!/bin/bash

#########################################################################
# Pterodactyl Panel Advanced Installer                                #
# Enhanced installer with Tailscale, Cloudflare, and more             #
#########################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BG_BLUE='\033[44m'
BG_GREEN='\033[42m'
BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'
BLINK='\033[5m'
NC='\033[0m' # No Color

# Script version
VERSION="2.0.1"

# Logging
LOG_DIR="/var/log/pterodactyl-installer"
LOG_FILE="${LOG_DIR}/install-$(date +%Y%m%d_%H%M%S).log"
ERROR_LOG="${LOG_DIR}/error.log"
STATE_FILE="${LOG_DIR}/install.state"
CONFIG_FILE=""

# Global variables
INSTALL_MARIADB=false
INSTALL_PHPMYADMIN=false
INSTALL_TAILSCALE=false
INSTALL_CLOUDFLARE=false
CONFIGURE_FIREWALL=false
CONFIGURE_SSL=false
INSTALL_FAIL2BAN=false
INSTALL_MODSECURITY=false
ENABLE_WEB_HOSTING=false
AUTO_BACKUP=false
FQDN=""
EMAIL=""
DB_PASSWORD=""
WEB_HOSTING_DOMAIN=""
PANEL_VERSION="latest"
PHP_VERSION="8.2"
SILENT_MODE=false
STEP_COUNTER=0
TOTAL_STEPS=15

# Rollback tracking
declare -a INSTALLED_COMPONENTS=()
declare -a ROLLBACK_ACTIONS=()

#########################################################################
# Logging & Setup Functions                                            #
#########################################################################

setup_logging() {
    mkdir -p "$LOG_DIR"
    exec 1> >(tee -a "$LOG_FILE")
    exec 2> >(tee -a "$ERROR_LOG" >&2)
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Installation started" >> "$LOG_FILE"
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$ERROR_LOG"
}

save_state() {
    local step=$1
    echo "$step" > "$STATE_FILE"
    log "State saved: $step"
}

load_state() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    fi
}

add_rollback_action() {
    ROLLBACK_ACTIONS+=("$1")
    log "Rollback action added: $1"
}

execute_rollback() {
    print_warning "Executing rollback..."
    for ((i=${#ROLLBACK_ACTIONS[@]}-1; i>=0; i--)); do
        print_info "Rolling back: ${ROLLBACK_ACTIONS[$i]}"
        eval "${ROLLBACK_ACTIONS[$i]}" 2>/dev/null || true
    done
    print_success "Rollback complete"
}

trap_error() {
    local exit_code=$?
    log_error "Installation failed at step: $STEP_COUNTER"
    print_error "Installation failed! Check logs at: $LOG_FILE"
    echo
    printf "${YELLOW}Attempt rollback? (Y/n): ${NC}"
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        execute_rollback
    fi
    exit $exit_code
}

trap trap_error ERR

#########################################################################
# Helper Functions                                                      #
#########################################################################

print_header() {
    clear
    echo -e "${CYAN}"
    echo "═══════════════════════════════════════════════════════════════════════"
    echo -e "${PURPLE}${BOLD}"
    cat << "EOF"
    ____  __                          __           __
   / __ \/ /____  _________  ____/ /___ ______/ /___  __
  / /_/ / __/ _ \/ ___/ __ \/ __  / __ `/ ___/ __/ / / /
 / ____/ /_/  __/ /  / /_/ / /_/ / /_/ / /__/ /_/ /_/ /
/_/    \__/\___/_/   \____/\__,_/\__,_/\___/\__/\__, /
                                                /____/
EOF
    echo -e "${CYAN}"
    echo "═══════════════════════════════════════════════════════════════════════"
    echo -e "${GREEN}${BOLD}              Advanced Panel Installer ${WHITE}v${VERSION}${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo
}

print_success() {
    echo -e "${GREEN}${BOLD}[✓]${NC} ${GREEN}$1${NC}"
}

print_error() {
    echo -e "${RED}${BOLD}[✗]${NC} ${RED}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}${BOLD}[⚠]${NC} ${YELLOW}$1${NC}"
}

print_info() {
    echo -e "${BLUE}${BOLD}[➤]${NC} ${CYAN}$1${NC}"
}

print_step() {
    echo -e "${PURPLE}${BOLD}▓▓▓${NC} ${WHITE}$1${NC}"
}

print_progress() {
    local current=$1
    local total=$2
    local task=$3
    local percent=$((current * 100 / total))
    local filled=$((percent / 5))
    local empty=$((20 - filled))
    
    echo -ne "${CYAN}["
    printf "${GREEN}%${filled}s" | tr ' ' '█'
    printf "${DIM}%${empty}s" | tr ' ' '░'
    echo -e "${CYAN}] ${WHITE}${percent}%${NC} ${DIM}- $task${NC}\r"
}

show_progress() {
    STEP_COUNTER=$((STEP_COUNTER + 1))
    local task=$1
    print_progress $STEP_COUNTER $TOTAL_STEPS "$task"
    echo
    log "Step $STEP_COUNTER/$TOTAL_STEPS: $task"
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " ${CYAN}[%c]${NC} " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root!"
        exit 1
    fi
}

#########################################################################
# Pre-flight Checks                                                     #
#########################################################################

check_system_requirements() {
    print_info "Running system requirements check..."
    local checks_passed=true
    
    # RAM check
    local total_ram=$(free -m | awk '/^Mem:/{print $2}')
    if [ $total_ram -lt 2048 ]; then
        print_warning "RAM: ${total_ram}MB (Recommended: 4096MB+)"
        checks_passed=false
    else
        print_success "RAM: ${total_ram}MB"
    fi
    
    # CPU check
    local cpu_cores=$(nproc)
    if [ $cpu_cores -lt 2 ]; then
        print_warning "CPU Cores: $cpu_cores (Recommended: 2+)"
        checks_passed=false
    else
        print_success "CPU Cores: $cpu_cores"
    fi
    
    # Disk space check
    local disk_space=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ $disk_space -lt 20 ]; then
        print_warning "Disk Space: ${disk_space}GB (Recommended: 20GB+)"
        checks_passed=false
    else
        print_success "Disk Space: ${disk_space}GB available"
    fi
    
    if [ "$checks_passed" = false ]; then
        print_warning "System does not meet recommended requirements"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

check_ports() {
    print_info "Checking if required ports are available..."
    local ports=(80 443 3306 8080 2022)
    local ports_in_use=()
    
    for port in "${ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "; then
            ports_in_use+=("$port")
        fi
    done
    
    if [ ${#ports_in_use[@]} -gt 0 ]; then
        print_warning "Ports in use: ${ports_in_use[*]}"
        print_info "This may cause conflicts during installation"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_success "All required ports are available"
    fi
}

check_internet() {
    print_info "Checking internet connectivity..."
    if ping -c 1 8.8.8.8 &> /dev/null; then
        print_success "Internet connection verified"
    else
        print_error "No internet connection detected"
        exit 1
    fi
}

check_existing_installation() {
    print_info "Checking for existing Pterodactyl installation..."
    
    if [ -d "/var/www/pterodactyl" ]; then
        print_warning "Existing Pterodactyl installation detected!"
        read -p "Reinstall/Upgrade? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_success "No existing installation found"
    fi
}

check_conflicting_software() {
    print_info "Checking for conflicting software..."
    local conflicts=()
    
    if command -v apache2 &> /dev/null; then
        conflicts+=("Apache2")
    fi
    
    if [ ${#conflicts[@]} -gt 0 ]; then
        print_warning "Conflicting software detected: ${conflicts[*]}"
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_success "No conflicting software detected"
    fi
}

detect_system_resources() {
    local total_ram=$(free -m | awk '/^Mem:/{print $2}')
    
    # Adjust PHP-FPM workers based on RAM
    if [ $total_ram -ge 8192 ]; then
        PHP_FPM_MAX_CHILDREN=50
        PHP_FPM_START_SERVERS=10
    elif [ $total_ram -ge 4096 ]; then
        PHP_FPM_MAX_CHILDREN=30
        PHP_FPM_START_SERVERS=5
    else
        PHP_FPM_MAX_CHILDREN=20
        PHP_FPM_START_SERVERS=3
    fi
    
    log "Auto-configured: PHP_FPM_MAX_CHILDREN=$PHP_FPM_MAX_CHILDREN"
    print_info "System optimizations configured for ${total_ram}MB RAM"
}

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VER=$VERSION_ID
    else
        print_error "Cannot detect OS. This script supports Ubuntu 20.04/22.04/24.04 and Debian 11/12."
        exit 1
    fi

    case "$OS" in
        ubuntu)
            if [[ ! "$OS_VER" =~ ^(20.04|22.04|24.04)$ ]]; then
                print_error "Unsupported Ubuntu version: $OS_VER"
                exit 1
            fi
            ;;
        debian)
            if [[ ! "$OS_VER" =~ ^(11|12)$ ]]; then
                print_error "Unsupported Debian version: $OS_VER"
                exit 1
            fi
            ;;
        *)
            print_error "Unsupported OS: $OS"
            exit 1
            ;;
    esac

    print_success "Detected $OS $OS_VER"
}

#########################################################################
# Configuration File Support                                            #
#########################################################################

load_config_file() {
    local config=$1
    if [ ! -f "$config" ]; then
        print_error "Config file not found: $config"
        exit 1
    fi
    
    print_info "Loading configuration from: $config"
    source "$config"
    SILENT_MODE=true
    print_success "Configuration loaded"
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            --status)
                show_status
                exit 0
                ;;
            --update)
                update_panel
                exit 0
                ;;
            --self-update)
                self_update
                exit 0
                ;;
            --backup)
                create_backup
                exit 0
                ;;
            --restore)
                restore_backup "$2"
                exit 0
                ;;
            --full-backup)
                create_full_backup
                exit 0
                ;;
            --factory-reset|--wipe)
                factory_reset
                exit 0
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            --version|-v)
                echo "Pterodactyl Installer v$VERSION"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << EOF
${CYAN}${BOLD}Pterodactyl Advanced Installer v$VERSION${NC}

${WHITE}Usage:${NC}
  $0 [OPTIONS]

${WHITE}Options:${NC}
  ${GREEN}--config <file>${NC}       Use configuration file for silent install
  ${GREEN}--status${NC}             Show installation status and health check
  ${GREEN}--update${NC}             Update Pterodactyl panel to latest version
  ${GREEN}--self-update${NC}        Update this installer script
  ${GREEN}--backup${NC}             Create backup of panel and database
  ${GREEN}--full-backup${NC}        Create FULL backup (panel, database, wings, docker volumes, SSL)
  ${GREEN}--restore <file>${NC}     Restore from backup file
  ${GREEN}--factory-reset${NC}      Backup everything and wipe server to fresh state
  ${GREEN}--wipe${NC}               Alias for --factory-reset
  ${GREEN}--help, -h${NC}           Show this help message
  ${GREEN}--version, -v${NC}        Show version information

${WHITE}Examples:${NC}
  ${DIM}# Interactive installation${NC}
  sudo $0
  
  ${DIM}# Silent installation with config${NC}
  sudo $0 --config /path/to/config.conf
  
  ${DIM}# Check status${NC}
  sudo $0 --status
  
  ${DIM}# Update panel${NC}
  sudo $0 --update
  
  ${DIM}# Create full backup before major changes${NC}
  sudo $0 --full-backup
  
  ${DIM}# Factory reset (backs up everything, then wipes clean)${NC}
  sudo $0 --factory-reset

${YELLOW}${BOLD}Factory Reset:${NC}
  The --factory-reset option will:
    1. Create a complete backup of ALL data
    2. Remove Pterodactyl, Wings, Docker, databases
    3. Clean all configurations
    4. Return server to fresh Ubuntu state
  
  Your backup will be saved and can be restored later!

EOF
}

#########################################################################
# Update Mechanisms                                                     #
#########################################################################

update_panel() {
    print_header
    echo -e "${YELLOW}${BOLD}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${BOLD}║${NC}              ${WHITE}Panel Update Process${NC}                 ${YELLOW}${BOLD}║${NC}"
    echo -e "${YELLOW}${BOLD}╚═══════════════════════════════════════════════════════╝${NC}"
    echo
    
    if [ ! -d "/var/www/pterodactyl" ]; then
        print_error "Pterodactyl panel not found!"
        exit 1
    fi
    
    print_warning "Creating backup before update..."
    create_backup
    
    cd /var/www/pterodactyl
    
    print_info "Putting panel in maintenance mode..."
    php artisan down
    
    print_info "Downloading latest release..."
    curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
    tar -xzvf panel.tar.gz
    chmod -R 755 storage/* bootstrap/cache/
    
    print_info "Updating dependencies..."
    COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader -q
    
    print_info "Clearing caches..."
    php artisan view:clear
    php artisan config:clear
    
    print_info "Running migrations..."
    php artisan migrate --seed --force
    
    chown -R www-data:www-data /var/www/pterodactyl/*
    
    print_info "Restarting queue worker..."
    php artisan queue:restart
    
    print_info "Bringing panel back online..."
    php artisan up
    
    print_success "Panel updated successfully!"
}

self_update() {
    print_info "Checking for installer updates..."
    local latest_version
    latest_version=$(curl -s https://api.github.com/repos/Larpie3/zerohost/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    
    if [ "$latest_version" != "v$VERSION" ]; then
        print_info "New version available: $latest_version"
        print_info "Updating installer..."
        curl -sSL https://raw.githubusercontent.com/Larpie3/zerohost/main/install.sh -o /tmp/install.sh
        chmod +x /tmp/install.sh
        mv /tmp/install.sh "$0"
        print_success "Installer updated! Please run again."
        exit 0
    else
        print_success "Installer is up to date (v$VERSION)"
    fi
}

#########################################################################
# Backup & Restore                                                      #
#########################################################################

create_backup() {
    local backup_dir="/root/pterodactyl-backups"
    local backup_name="backup-$(date +%Y%m%d_%H%M%S)"
    local backup_path="${backup_dir}/${backup_name}"
    
    mkdir -p "$backup_dir"
    mkdir -p "$backup_path"
    
    print_info "Creating backup: $backup_name"
    
    # Backup database
    if systemctl is-active --quiet mariadb; then
        print_info "Backing up database..."
        mysqldump -u root -p"$DB_PASSWORD" panel > "${backup_path}/database.sql" 2>/dev/null || \
        mysqldump -u root panel > "${backup_path}/database.sql" 2>/dev/null
        add_rollback_action "mysql -u root panel < ${backup_path}/database.sql"
    fi
    
    # Backup panel files
    if [ -d "/var/www/pterodactyl" ]; then
        print_info "Backing up panel files..."
        tar -czf "${backup_path}/panel-files.tar.gz" -C /var/www/pterodactyl . 2>/dev/null
    fi
    
    # Backup .env
    if [ -f "/var/www/pterodactyl/.env" ]; then
        cp /var/www/pterodactyl/.env "${backup_path}/.env"
    fi
    
    # Create backup info
    cat > "${backup_path}/backup-info.txt" << EOF
Backup created: $(date)
Pterodactyl Version: $(cd /var/www/pterodactyl 2>/dev/null && php artisan --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "Unknown")
Installer Version: $VERSION
OS: $OS $OS_VER
EOF
    
    print_success "Backup created: ${backup_path}"
    echo -e "  ${CYAN}Location:${NC} ${backup_path}"
}

create_full_backup() {
    print_info "Creating FULL system backup (this may take a while)..."
    
    local backup_dir="/var/backups/pterodactyl-full"
    local backup_date=$(date +%Y%m%d_%H%M%S)
    local backup_path="${backup_dir}/full-backup-${backup_date}"
    
    mkdir -p "$backup_path"
    
    # Backup Pterodactyl database
    print_info "Backing up Pterodactyl database..."
    if systemctl is-active --quiet mariadb || systemctl is-active --quiet mysql; then
        mysqldump -u root --all-databases > "${backup_path}/all-databases.sql" 2>/dev/null || mysqldump -u root panel > "${backup_path}/panel-database.sql"
    fi
    
    # Backup panel files
    print_info "Backing up panel files and configuration..."
    if [ -d "/var/www/pterodactyl" ]; then
        tar -czf "${backup_path}/panel-files.tar.gz" -C /var/www/pterodactyl . 2>/dev/null
    fi
    
    # Backup Wings configuration
    print_info "Backing up Wings configuration..."
    if [ -d "/etc/pterodactyl" ]; then
        tar -czf "${backup_path}/wings-config.tar.gz" -C /etc/pterodactyl . 2>/dev/null
    fi
    
    # Backup Docker volumes (game server data)
    print_info "Backing up Docker volumes and containers..."
    if command -v docker &> /dev/null; then
        docker ps -a --format "{{.Names}}" > "${backup_path}/docker-containers.txt" 2>/dev/null
        mkdir -p "${backup_path}/docker-volumes"
        
        # Get all volumes
        local all_volumes=($(docker volume ls -q 2>/dev/null || true))
        local volume_count=${#all_volumes[@]}
        
        if [ $volume_count -gt 0 ]; then
            print_info "Found $volume_count Docker volume(s) to backup..."
            local current=0
            
            # Backup ALL volumes (includes all game server data)
            for volume in "${all_volumes[@]}"; do
                ((current++))
                print_info "  [$current/$volume_count] Backing up volume: $volume"
                docker run --rm -v "$volume":/volume -v "${backup_path}/docker-volumes":/backup alpine tar czf "/backup/${volume}.tar.gz" -C /volume . 2>/dev/null || true
            done
        else
            print_info "No Docker volumes found to backup"
        fi
    fi
    
    # Backup SSL certificates
    print_info "Backing up SSL certificates..."
    if [ -d "/etc/letsencrypt" ]; then
        tar -czf "${backup_path}/letsencrypt.tar.gz" -C /etc/letsencrypt . 2>/dev/null
    fi
    
    # Backup Nginx configuration
    print_info "Backing up Nginx configuration..."
    if [ -d "/etc/nginx" ]; then
        tar -czf "${backup_path}/nginx-config.tar.gz" -C /etc/nginx . 2>/dev/null
    fi
    
    # Backup cron jobs
    print_info "Backing up cron jobs..."
    crontab -l > "${backup_path}/crontab.txt" 2>/dev/null || echo "No crontab found" > "${backup_path}/crontab.txt"
    
    # Backup UFW rules
    print_info "Backing up firewall rules..."
    if command -v ufw &> /dev/null; then
        ufw status numbered > "${backup_path}/ufw-rules.txt" 2>/dev/null
    fi
    
    # Backup system info
    print_info "Saving system information..."
    cat > "${backup_path}/system-info.txt" << EOF
=== Full System Backup ===
Backup created: $(date)
Hostname: $(hostname)
OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
Kernel: $(uname -r)
Pterodactyl Version: $(cd /var/www/pterodactyl 2>/dev/null && php artisan --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "Unknown")
Installer Version: $VERSION

=== Installed Packages ===
$(dpkg -l | grep -E "(pterodactyl|docker|nginx|php|mariadb|redis)" || echo "None found")

=== Network Configuration ===
$(ip addr show)

=== Disk Usage ===
$(df -h)
EOF
    
    # Create restore script
    cat > "${backup_path}/RESTORE-INSTRUCTIONS.txt" << 'EOFR'
=== RESTORE INSTRUCTIONS ===

To restore this backup on a clean Ubuntu server:

1. Install fresh Ubuntu 20.04/22.04/24.04 or Debian 11/12
2. Download this backup to the new server
3. Run the ZeroHost installer in restore mode:
   
   sudo ./install.sh --full-restore /path/to/backup
   
Or manually restore:
   
   # 1. Install Pterodactyl (skip configuration prompts)
   sudo ./install.sh
   
   # 2. Stop services
   systemctl stop wings nginx
   cd /var/www/pterodactyl && php artisan down
   
   # 3. Restore database
   mysql -u root < all-databases.sql
   
   # 4. Restore panel files
   cd /var/www/pterodactyl
   tar -xzf /path/to/backup/panel-files.tar.gz
   chown -R www-data:www-data *
   
   # 5. Restore Wings config
   tar -xzf /path/to/backup/wings-config.tar.gz -C /etc/pterodactyl
   
   # 6. Restore SSL certificates
   tar -xzf /path/to/backup/letsencrypt.tar.gz -C /etc/letsencrypt
   
   # 7. Restore Docker volumes
   for vol in docker-volumes/*.tar.gz; do
       volname=$(basename "$vol" .tar.gz)
       docker volume create "$volname"
       docker run --rm -v "$volname":/volume -v "$(pwd)/docker-volumes":/backup alpine tar xzf "/backup/$(basename $vol)" -C /volume
   done
   
   # 8. Restart services
   php artisan up
   php artisan queue:restart
   systemctl restart wings nginx

EOFR
    
    # Create downloadable archive
    print_info "Creating downloadable archive..."
    cd "$backup_dir"
    tar -czf "full-backup-${backup_date}.tar.gz" "full-backup-${backup_date}"
    
    local archive_size=$(du -h "full-backup-${backup_date}.tar.gz" | cut -f1)
    
    print_success "Full backup created successfully!"
    echo -e "${GREEN}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║${NC}                 ${WHITE}Backup Complete${NC}                        ${GREEN}${BOLD}║${NC}"
    echo -e "${GREEN}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "  ${CYAN}Archive:${NC}  ${backup_dir}/full-backup-${backup_date}.tar.gz"
    echo -e "  ${CYAN}Size:${NC}     ${archive_size}"
    echo -e "  ${CYAN}Location:${NC} ${backup_path}"
    echo
    echo -e "${YELLOW}${BOLD}To download this backup:${NC}"
    echo -e "  scp root@$(hostname -I | awk '{print $1}'):${backup_dir}/full-backup-${backup_date}.tar.gz ."
    echo
    echo -e "${YELLOW}${BOLD}Or use panel-manager.sh to download backup${NC}"
}

factory_reset() {
    print_warning "═══════════════════════════════════════════════════════════"
    print_warning "           FACTORY RESET - COMPLETE SYSTEM WIPE"
    print_warning "═══════════════════════════════════════════════════════════"
    echo
    echo -e "${RED}${BOLD}⚠  WARNING: This will completely wipe your server!${NC}"
    echo
    echo -e "${YELLOW}This process will:${NC}"
    echo -e "  1. Create a FULL backup of all your data"
    echo -e "  2. Remove ALL Pterodactyl components"
    echo -e "  3. Remove Docker and all containers/volumes"
    echo -e "  4. Remove MariaDB and all databases"
    echo -e "  5. Clean up configuration files"
    echo -e "  6. Reset to a fresh Ubuntu state"
    echo
    echo -e "${GREEN}Your backup will be saved and can be restored later!${NC}"
    echo
    
    printf "${RED}${BOLD}Type 'WIPE SERVER' to confirm: ${NC}"
    read -r confirmation
    
    if [ "$confirmation" != "WIPE SERVER" ]; then
        print_error "Factory reset cancelled"
        exit 0
    fi
    
    echo
    printf "${YELLOW}Are you ABSOLUTELY sure? This cannot be undone! (yes/NO): ${NC}"
    read -r final_confirm
    
    if [ "$final_confirm" != "yes" ]; then
        print_error "Factory reset cancelled"
        exit 0
    fi
    
    # Step 1: Create full backup
    echo
    print_info "Step 1/6: Creating full backup before wipe..."
    create_full_backup
    
    echo
    sleep 3
    
    # Step 2: Stop all services
    print_info "Step 2/6: Stopping all services..."
    systemctl stop wings 2>/dev/null || true
    systemctl stop nginx 2>/dev/null || true
    systemctl stop redis-server 2>/dev/null || true
    if [ -d "/var/www/pterodactyl" ]; then
        cd /var/www/pterodactyl && php artisan down 2>/dev/null || true
    fi
    
    # Step 3: Remove Docker containers and volumes
    print_info "Step 3/6: Removing Docker containers and volumes..."
    if command -v docker &> /dev/null; then
        docker stop $(docker ps -aq) 2>/dev/null || true
        docker rm $(docker ps -aq) 2>/dev/null || true
        docker volume rm $(docker volume ls -q) 2>/dev/null || true
        docker network prune -f 2>/dev/null || true
        docker system prune -af 2>/dev/null || true
    fi
    
    # Step 4: Remove Pterodactyl
    print_info "Step 4/6: Removing Pterodactyl Panel and Wings..."
    systemctl disable --now wings 2>/dev/null || true
    systemctl disable --now pteroq 2>/dev/null || true
    rm -rf /var/www/pterodactyl
    rm -rf /etc/pterodactyl
    rm -rf /var/lib/pterodactyl
    rm -f /etc/systemd/system/wings.service
    rm -f /etc/systemd/system/pteroq.service
    rm -f /usr/local/bin/wings
    
    # Step 5: Remove databases
    print_info "Step 5/6: Removing databases..."
    if systemctl is-active --quiet mariadb || systemctl is-active --quiet mysql; then
        mysql -u root -e "DROP DATABASE IF EXISTS panel;" 2>/dev/null || true
        systemctl stop mariadb 2>/dev/null || systemctl stop mysql 2>/dev/null || true
    fi
    
    # Step 6: Remove packages and configs
    print_info "Step 6/6: Removing installed packages..."
    apt-get purge -y nginx nginx-common 2>/dev/null || true
    apt-get purge -y mariadb-server mariadb-client 2>/dev/null || true
    apt-get purge -y php8.* 2>/dev/null || true
    apt-get purge -y redis-server 2>/dev/null || true
    apt-get purge -y docker-ce docker-ce-cli containerd.io 2>/dev/null || true
    apt-get purge -y certbot 2>/dev/null || true
    apt-get purge -y fail2ban 2>/dev/null || true
    
    # Remove configuration directories
    rm -rf /etc/nginx
    rm -rf /etc/php
    rm -rf /etc/mysql
    rm -rf /etc/letsencrypt
    rm -rf /etc/fail2ban
    rm -rf /var/www/html
    rm -rf /var/lib/docker
    rm -rf /opt/pterodactyl
    
    # Clean up cron
    crontab -l | grep -v pterodactyl | crontab - 2>/dev/null || true
    
    # Autoremove unused packages
    apt-get autoremove -y 2>/dev/null || true
    apt-get autoclean 2>/dev/null || true
    
    # Reset firewall
    if command -v ufw &> /dev/null; then
        print_info "Resetting firewall..."
        ufw --force reset 2>/dev/null || true
    fi
    
    systemctl daemon-reload
    
    print_success "Factory reset complete!"
    echo
    echo -e "${GREEN}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║${NC}              ${WHITE}Server Wiped Successfully${NC}               ${GREEN}${BOLD}║${NC}"
    echo -e "${GREEN}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${CYAN}Your server has been reset to a clean state.${NC}"
    echo
    echo -e "${YELLOW}${BOLD}Your backup is located at:${NC}"
    echo -e "  /var/backups/pterodactyl-full/"
    echo
    echo -e "${YELLOW}${BOLD}To restore on a fresh server:${NC}"
    echo -e "  1. Reinstall Ubuntu (optional, current OS is already clean)"
    echo -e "  2. Download the ZeroHost installer"
    echo -e "  3. Run: sudo ./install.sh --full-restore /var/backups/pterodactyl-full/full-backup-*"
    echo
    echo -e "${GREEN}You can now run a fresh installation with: ${WHITE}./install.sh${NC}"
    echo
}

restore_backup() {
    local backup_path=$1
    
    if [ ! -d "$backup_path" ]; then
        print_error "Backup not found: $backup_path"
        exit 1
    fi
    
    print_warning "Restoring from backup: $backup_path"
    read -p "This will overwrite current installation. Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
    
    # Restore database
    if [ -f "${backup_path}/database.sql" ]; then
        print_info "Restoring database..."
        mysql -u root panel < "${backup_path}/database.sql"
    fi
    
    # Restore panel files
    if [ -f "${backup_path}/panel-files.tar.gz" ]; then
        print_info "Restoring panel files..."
        tar -xzf "${backup_path}/panel-files.tar.gz" -C /var/www/pterodactyl
        chown -R www-data:www-data /var/www/pterodactyl/*
    fi
    
    print_success "Backup restored successfully!"
}

#########################################################################
# Status & Health Check                                                #
#########################################################################

show_status() {
    print_header
    echo -e "${PURPLE}${BOLD}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}${BOLD}║${NC}            ${WHITE}Installation Status & Health${NC}             ${PURPLE}${BOLD}║${NC}"
    echo -e "${PURPLE}${BOLD}╚═══════════════════════════════════════════════════════╝${NC}"
    echo
    
    # Check Panel
    if [ -d "/var/www/pterodactyl" ]; then
        print_success "Pterodactyl Panel: Installed"
        local panel_version=$(cd /var/www/pterodactyl && php artisan --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "Unknown")
        echo -e "  ${CYAN}Version:${NC} $panel_version"
    else
        print_error "Pterodactyl Panel: Not Installed"
    fi
    
    echo
    
    # Check Services
    echo -e "${CYAN}${BOLD}Services Status:${NC}"
    check_service_status "nginx" "Nginx"
    check_service_status "mariadb" "MariaDB"
    check_service_status "redis-server" "Redis"
    check_service_status "pteroq" "Queue Worker"
    check_service_status "docker" "Docker"
    check_service_status "wings" "Wings"
    check_service_status "tailscaled" "Tailscale"
    
    echo
    
    # Check Ports
    echo -e "${CYAN}${BOLD}Port Status:${NC}"
    check_port_status 80 "HTTP"
    check_port_status 443 "HTTPS"
    check_port_status 3306 "MySQL"
    check_port_status 8080 "Wings API"
    
    echo
    
    # System Resources
    echo -e "${CYAN}${BOLD}System Resources:${NC}"
    local total_ram=$(free -m | awk '/^Mem:/{print $2}')
    local used_ram=$(free -m | awk '/^Mem:/{print $3}')
    local ram_percent=$((used_ram * 100 / total_ram))
    echo -e "  ${WHITE}RAM:${NC} ${used_ram}MB / ${total_ram}MB (${ram_percent}%)"
    
    local disk_used=$(df -h / | awk 'NR==2 {print $3}')
    local disk_total=$(df -h / | awk 'NR==2 {print $2}')
    local disk_percent=$(df / | awk 'NR==2 {print $5}')
    echo -e "  ${WHITE}Disk:${NC} ${disk_used} / ${disk_total} (${disk_percent})"
    
    local cpu_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
    echo -e "  ${WHITE}Load:${NC} $cpu_load"
    
    echo
    
    # Logs location
    echo -e "${CYAN}${BOLD}Logs:${NC}"
    echo -e "  ${WHITE}Installation:${NC} $LOG_FILE"
    echo -e "  ${WHITE}Errors:${NC} $ERROR_LOG"
    echo -e "  ${WHITE}Panel:${NC} /var/www/pterodactyl/storage/logs/"
}

check_service_status() {
    local service=$1
    local name=$2
    if systemctl is-active --quiet $service 2>/dev/null; then
        print_success "$name: Running"
    else
        print_error "$name: Stopped"
    fi
}

check_port_status() {
    local port=$1
    local name=$2
    if netstat -tuln 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "; then
        print_success "$name (Port $port): Open"
    else
        print_warning "$name (Port $port): Closed"
    fi
}

get_user_input() {
    print_header
    echo -e "${GREEN}${BOLD}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║${NC}  ${WHITE}Welcome to the Advanced Pterodactyl Installer!${NC}  ${GREEN}${BOLD}║${NC}"
    echo -e "${GREEN}${BOLD}╚═══════════════════════════════════════════════════════╝${NC}"
    echo
    
    # FQDN
    while [ -z "$FQDN" ]; do
        echo -e "${CYAN}┌─────────────────────────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│${NC} ${WHITE}Domain Configuration${NC}                                 ${CYAN}│${NC}"
        echo -e "${CYAN}└─────────────────────────────────────────────────────────┘${NC}"
        printf "${YELLOW}${BOLD}➤${NC} Enter your domain (e.g., panel.example.com): "
        read FQDN
        if [[ ! "$FQDN" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]] && [[ ! "$FQDN" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9](\.[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9])+$ ]]; then
            print_error "Invalid domain format!"
            FQDN=""
        fi
    done

    # Email
    echo
    while [ -z "$EMAIL" ]; do
        echo -e "${CYAN}┌─────────────────────────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│${NC} ${WHITE}Admin Email Address${NC}                                 ${CYAN}│${NC}"
        echo -e "${CYAN}└─────────────────────────────────────────────────────────┘${NC}"
        printf "${YELLOW}${BOLD}➤${NC} Enter your email address: "
        read EMAIL
        if [[ ! "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            print_error "Invalid email format!"
            EMAIL=""
        fi
    done

    # Database password
    echo
    while [ -z "$DB_PASSWORD" ]; do
        echo -e "${CYAN}┌─────────────────────────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│${NC} ${WHITE}Database Security${NC}                                   ${CYAN}│${NC}"
        echo -e "${CYAN}└─────────────────────────────────────────────────────────┘${NC}"
        printf "${YELLOW}${BOLD}➤${NC} Enter database password (or press enter for auto): "
        read -s DB_PASSWORD
        echo
        if [ -z "$DB_PASSWORD" ]; then
            DB_PASSWORD=$(openssl rand -base64 32)
            print_success "Auto-generated database password"
        fi
    done

    echo
    echo
    echo -e "${PURPLE}${BOLD}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}${BOLD}║${NC}  ${WHITE}Component Selection${NC}                              ${PURPLE}${BOLD}║${NC}"
    echo -e "${PURPLE}${BOLD}╚═══════════════════════════════════════════════════════╝${NC}"
    echo

    # MariaDB
    printf "${CYAN}${BOLD}[?]${NC} Install MariaDB? (${GREEN}Y${NC}/${RED}n${NC}): "
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        INSTALL_MARIADB=true
    fi

    # phpMyAdmin
    if [ "$INSTALL_MARIADB" = true ]; then
        printf "${CYAN}${BOLD}[?]${NC} Install phpMyAdmin? (${GREEN}Y${NC}/${RED}n${NC}): "
        read -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            INSTALL_PHPMYADMIN=true
        fi
    fi

    # Tailscale
    printf "${CYAN}${BOLD}[?]${NC} Install Tailscale VPN? (${GREEN}Y${NC}/${RED}n${NC}): "
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        INSTALL_TAILSCALE=true
    fi

    # Cloudflare
    printf "${CYAN}${BOLD}[?]${NC} Configure Cloudflare SSL/Proxy? (${GREEN}Y${NC}/${RED}n${NC}): "
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        INSTALL_CLOUDFLARE=true
    fi

    # Firewall
    printf "${CYAN}${BOLD}[?]${NC} Configure UFW firewall? (${GREEN}Y${NC}/${RED}n${NC}): "
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        CONFIGURE_FIREWALL=true
    fi

    # SSL
    printf "${CYAN}${BOLD}[?]${NC} Configure Let's Encrypt SSL? (${GREEN}Y${NC}/${RED}n${NC}): "
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        CONFIGURE_SSL=true
    fi

    # Web Hosting
    echo
    printf "${CYAN}${BOLD}[?]${NC} Enable web hosting for additional websites? (${GREEN}y${NC}/${RED}N${NC}): "
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ENABLE_WEB_HOSTING=true
        echo
        echo -e "${CYAN}┌─────────────────────────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│${NC} ${WHITE}Web Hosting Domain${NC}                                  ${CYAN}│${NC}"
        echo -e "${CYAN}└─────────────────────────────────────────────────────────┘${NC}"
        printf "${YELLOW}${BOLD}➤${NC} Enter your website domain (e.g., mysite.com) or leave blank: "
        read WEB_HOSTING_DOMAIN
    fi

    echo
    echo
    echo -e "${GREEN}${BOLD}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║${NC}  ${WHITE}✓ Configuration Complete!${NC}                         ${GREEN}${BOLD}║${NC}"
    echo -e "${GREEN}${BOLD}╚═══════════════════════════════════════════════════════╝${NC}"
    echo
    printf "${YELLOW}${BOLD}➤${NC} Press ${GREEN}ENTER${NC} to begin installation..."
    read -r
}

#########################################################################
# Validation Functions                                                  #
#########################################################################

validate_dns() {
    local domain=$1
    print_info "Validating DNS for $domain..."
    
    local server_ip=$(curl -s ifconfig.me)
    local dns_ip=$(dig +short $domain | tail -n1)
    
    if [ "$server_ip" = "$dns_ip" ]; then
        print_success "DNS correctly points to this server ($server_ip)"
        return 0
    else
        print_warning "DNS mismatch! Domain points to: $dns_ip, Server IP: $server_ip"
        print_info "SSL certificate generation may fail"
        return 1
    fi
}

validate_ssl() {
    local domain=$1
    print_info "Validating SSL certificate for $domain..."
    
    if openssl s_client -connect "$domain:443" -servername "$domain" </dev/null 2>/dev/null | openssl x509 -noout -dates &>/dev/null; then
        local expiry=$(echo | openssl s_client -connect "$domain:443" -servername "$domain" 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2)
        print_success "SSL certificate valid until: $expiry"
        return 0
    else
        print_error "SSL certificate validation failed"
        return 1
    fi
}

test_database_connection() {
    print_info "Testing database connection..."
    
    if mysql -u pterodactyl -p"$DB_PASSWORD" -h 127.0.0.1 -e "USE panel;" 2>/dev/null; then
        print_success "Database connection successful"
        return 0
    else
        print_error "Database connection failed"
        return 1
    fi
}

test_panel_accessibility() {
    local url=$1
    print_info "Testing panel accessibility..."
    
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" --max-time 10)
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "302" ]; then
        print_success "Panel is accessible (HTTP $http_code)"
        return 0
    else
        print_warning "Panel returned HTTP $http_code"
        return 1
    fi
}

#########################################################################
# Security Hardening                                                    #
#########################################################################

install_fail2ban() {
    if [ "$INSTALL_FAIL2BAN" = false ]; then
        return
    fi
    
    show_progress "Installing Fail2ban"
    
    apt-get install -y fail2ban
    
    # Configure for Pterodactyl
    cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log

[nginx-noscript]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
EOF
    
    systemctl enable --now fail2ban
    add_rollback_action "systemctl stop fail2ban; apt-get remove -y fail2ban"
    INSTALLED_COMPONENTS+=("fail2ban")
    
    print_success "Fail2ban installed and configured"
}

install_modsecurity() {
    if [ "$INSTALL_MODSECURITY" = false ]; then
        return
    fi
    
    show_progress "Installing ModSecurity"
    
    apt-get install -y libnginx-mod-security2
    
    mkdir -p /etc/nginx/modsec
    cp /usr/share/modsecurity-crs/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf
    
    sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf
    
    add_rollback_action "apt-get remove -y libnginx-mod-security2"
    INSTALLED_COMPONENTS+=("modsecurity")
    
    print_success "ModSecurity installed"
}

configure_ssh_hardening() {
    print_info "Applying SSH hardening..."
    
    # Backup original
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    # Apply hardening
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    
    add_rollback_action "mv /etc/ssh/sshd_config.backup /etc/ssh/sshd_config"
    
    print_success "SSH hardened (key-based auth recommended)"
}

enable_auto_updates() {
    print_info "Enabling automatic security updates..."
    
    apt-get install -y unattended-upgrades
    
    cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF
    
    cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
    
    print_success "Automatic security updates enabled"
}

#########################################################################
# Post-Install Validation                                               #
#########################################################################

run_post_install_checks() {
    print_header
    echo -e "${PURPLE}${BOLD}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}${BOLD}║${NC}            ${WHITE}Post-Installation Validation${NC}             ${PURPLE}${BOLD}║${NC}"
    echo -e "${PURPLE}${BOLD}╚═══════════════════════════════════════════════════════╝${NC}"
    echo
    
    local checks_passed=0
    local checks_failed=0
    
    # Check services
    echo -e "${CYAN}${BOLD}Checking Services...${NC}"
    for service in nginx mariadb redis-server pteroq; do
        if systemctl is-active --quiet $service; then
            print_success "$service is running"
            ((checks_passed++))
        else
            print_error "$service is not running"
            ((checks_failed++))
        fi
    done
    echo
    
    # Test database
    echo -e "${CYAN}${BOLD}Testing Database...${NC}"
    if test_database_connection; then
        ((checks_passed++))
    else
        ((checks_failed++))
    fi
    echo
    
    # Test panel accessibility
    echo -e "${CYAN}${BOLD}Testing Panel Accessibility...${NC}"
    if test_panel_accessibility "https://$FQDN"; then
        ((checks_passed++))
    else
        ((checks_failed++))
    fi
    echo
    
    # Summary
    echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║${NC}                 ${WHITE}Validation Summary${NC}                    ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════╝${NC}"
    echo -e "  ${GREEN}Passed:${NC} $checks_passed"
    echo -e "  ${RED}Failed:${NC} $checks_failed"
    echo
    
    if [ $checks_failed -eq 0 ]; then
        print_success "All validation checks passed!"
    else
        print_warning "Some checks failed. Please review the output above."
    fi
}

#########################################################################
# Installation Functions                                                #
#########################################################################

update_system() {
    show_progress "Updating system packages"
    apt-get update -qq
    apt-get upgrade -y -qq
    print_success "System updated"
    save_state "system_updated"
}

install_dependencies() {
    show_progress "Installing dependencies"
    
    apt-get install -y -qq \
        software-properties-common \
        curl \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        tar \
        unzip \
        git \
        redis-server \
        certbot \
        python3-certbot-nginx \
        dnsutils \
        net-tools

    add_rollback_action "apt-get remove -y software-properties-common curl"
    INSTALLED_COMPONENTS+=("dependencies")
    print_success "Dependencies installed"
    save_state "dependencies_installed"
}

install_docker() {
    show_progress "Installing Docker"
    
    # Remove old versions
    apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/$OS/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Set up repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update -qq
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    systemctl enable --now docker
    
    add_rollback_action "systemctl stop docker; apt-get remove -y docker-ce docker-ce-cli containerd.io"
    INSTALLED_COMPONENTS+=("docker")
    print_success "Docker installed"
    save_state "docker_installed"
}

install_php() {
    show_progress "Installing PHP $PHP_VERSION and extensions"
    
    if [ "$OS" = "ubuntu" ]; then
        add-apt-repository -y ppa:ondrej/php
        apt-get update -qq
    fi
    
    apt-get install -y -qq \
        php${PHP_VERSION} \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-pdo \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-tokenizer \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-redis \
        php${PHP_VERSION}-intl
    
    # Auto-configure PHP-FPM based on system RAM
    if [ -n "$PHP_FPM_MAX_CHILDREN" ]; then
        sed -i "s/pm.max_children = .*/pm.max_children = $PHP_FPM_MAX_CHILDREN/" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
        sed -i "s/pm.start_servers = .*/pm.start_servers = $PHP_FPM_START_SERVERS/" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
        print_info "PHP-FPM configured for optimal performance"
    fi
    
    add_rollback_action "apt-get remove -y php${PHP_VERSION}*"
    INSTALLED_COMPONENTS+=("php")
    print_success "PHP $PHP_VERSION installed"
    save_state "php_installed"
}

install_composer() {
    print_info "Installing Composer..."
    
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
    
    print_success "Composer installed"
}

install_mariadb() {
    if [ "$INSTALL_MARIADB" = false ]; then
        return
    fi
    
    show_progress "Installing MariaDB"
    
    apt-get install -y mariadb-server mariadb-client
    
    systemctl enable --now mariadb
    
    # Secure installation
    mysql -e "UPDATE mysql.user SET Password = PASSWORD('$DB_PASSWORD') WHERE User = 'root'"
    mysql -e "DELETE FROM mysql.user WHERE User=''"
    mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
    mysql -e "DROP DATABASE IF EXISTS test"
    mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"
    mysql -e "FLUSH PRIVILEGES"
    
    # Create Pterodactyl database
    mysql -u root -p"$DB_PASSWORD" -e "CREATE DATABASE panel"
    mysql -u root -p"$DB_PASSWORD" -e "CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '$DB_PASSWORD'"
    mysql -u root -p"$DB_PASSWORD" -e "GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION"
    mysql -u root -p"$DB_PASSWORD" -e "FLUSH PRIVILEGES"
    
    # Test connection
    if ! test_database_connection; then
        print_error "Database connection test failed!"
        return 1
    fi
    
    add_rollback_action "systemctl stop mariadb; apt-get remove -y mariadb-server mariadb-client"
    INSTALLED_COMPONENTS+=("mariadb")
    print_success "MariaDB installed and configured"
    save_state "mariadb_installed"
}

install_nginx() {
    print_info "Installing Nginx..."
    
    apt-get install -y nginx
    
    systemctl enable nginx
    
    print_success "Nginx installed"
}

install_pterodactyl() {
    print_info "Installing Pterodactyl Panel..."
    
    mkdir -p /var/www/pterodactyl
    cd /var/www/pterodactyl
    
    # Download latest release
    curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
    tar -xzvf panel.tar.gz
    chmod -R 755 storage/* bootstrap/cache/
    
    # Install dependencies
    COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader -q
    
    # Environment setup
    cp .env.example .env
    
    php artisan key:generate --force
    
    # Database configuration
    php artisan p:environment:database \
        --host=127.0.0.1 \
        --port=3306 \
        --database=panel \
        --username=pterodactyl \
        --password="$DB_PASSWORD"
    
    php artisan p:environment:setup \
        --author="$EMAIL" \
        --url="https://$FQDN" \
        --timezone=UTC \
        --cache=redis \
        --session=redis \
        --queue=redis \
        --redis-host=127.0.0.1 \
        --redis-pass= \
        --redis-port=6379
    
    # Run migrations
    php artisan migrate --seed --force
    
    # Create admin user
    php artisan p:user:make \
        --email="$EMAIL" \
        --username=admin \
        --name-first=Admin \
        --name-last=User \
        --password="$(openssl rand -base64 16)" \
        --admin=1
    
    # Set permissions
    chown -R www-data:www-data /var/www/pterodactyl/*
    
    # Setup cron
    (crontab -l 2>/dev/null; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1") | crontab -
    
    # Setup queue worker
    cat > /etc/systemd/system/pteroq.service <<EOF
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl enable --now pteroq.service
    
    print_success "Pterodactyl Panel installed"
}

configure_nginx() {
    print_info "Configuring Nginx..."
    
    cat > /etc/nginx/sites-available/pterodactyl.conf <<EOF
server {
    listen 80;
    server_name $FQDN;
    
    root /var/www/pterodactyl/public;
    index index.php;

    access_log /var/log/nginx/pterodactyl.app-access.log;
    error_log  /var/log/nginx/pterodactyl.app-error.log error;

    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
        include /etc/nginx/fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
    
    ln -sf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
    rm -f /etc/nginx/sites-enabled/default
    
    nginx -t && systemctl restart nginx
    
    print_success "Nginx configured"
}

configure_ssl() {
    if [ "$CONFIGURE_SSL" = false ]; then
        return
    fi
    
    show_progress "Configuring SSL with Let's Encrypt"
    
    # Validate DNS first
    if ! validate_dns "$FQDN"; then
        print_warning "DNS validation failed. Waiting 30 seconds for DNS propagation..."
        sleep 30
        if ! validate_dns "$FQDN"; then
            print_error "DNS still not pointing to this server. SSL setup may fail."
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                return 1
            fi
        fi
    fi
    
    if [ "$INSTALL_CLOUDFLARE" = true ]; then
        print_warning "Cloudflare SSL is enabled. Make sure DNS is pointing to this server first!"
        read -p "Press enter when ready to continue..." -r
    fi
    
    certbot --nginx -d "$FQDN" --non-interactive --agree-tos --email "$EMAIL" --redirect
    
    # Validate SSL certificate
    sleep 5
    if validate_ssl "$FQDN"; then
        print_success "SSL certificate validated successfully"
    else
        print_warning "SSL certificate validation failed, but installation will continue"
    fi
    
    systemctl restart nginx
    
    add_rollback_action "certbot delete --cert-name $FQDN --non-interactive"
    INSTALLED_COMPONENTS+=("ssl")
    print_success "SSL configured"
    save_state "ssl_configured"
}

install_tailscale() {
    if [ "$INSTALL_TAILSCALE" = false ]; then
        return
    fi
    
    print_info "Installing Tailscale..."
    
    curl -fsSL https://tailscale.com/install.sh | sh
    
    print_success "Tailscale installed"
    print_warning "Run 'tailscale up' to authenticate and connect to your tailnet"
}

configure_cloudflare() {
    if [ "$INSTALL_CLOUDFLARE" = false ]; then
        return
    fi
    
    print_info "Setting up Cloudflare integration..."
    
    # Install Cloudflare daemon for automatic IP updates
    mkdir -p /opt/cloudflare
    cat > /opt/cloudflare/restore-ips.sh <<'EOF'
#!/bin/bash
# Restore real visitor IPs from Cloudflare

# Nginx config for Cloudflare IPs
CF_NGINX="/etc/nginx/conf.d/cloudflare.conf"

# Download Cloudflare IPs
CF_IPSV4=$(curl -s https://www.cloudflare.com/ips-v4)
CF_IPSV6=$(curl -s https://www.cloudflare.com/ips-v6)

# Generate nginx config
{
    echo "# Cloudflare IP Ranges"
    echo "# Generated on $(date)"
    echo ""
    for ip in $CF_IPSV4; do
        echo "set_real_ip_from $ip;"
    done
    for ip in $CF_IPSV6; do
        echo "set_real_ip_from $ip;"
    done
    echo ""
    echo "real_ip_header CF-Connecting-IP;"
} > "$CF_NGINX"

# Reload nginx
nginx -t && systemctl reload nginx
EOF
    
    chmod +x /opt/cloudflare/restore-ips.sh
    /opt/cloudflare/restore-ips.sh
    
    # Setup cron for weekly updates
    (crontab -l 2>/dev/null; echo "0 3 * * 0 /opt/cloudflare/restore-ips.sh") | crontab -
    
    print_success "Cloudflare integration configured"
    print_info "Make sure to:"
    echo "  1. Point your domain DNS to this server's IP"
    echo "  2. Enable Cloudflare proxy (orange cloud)"
    echo "  3. Set SSL/TLS mode to 'Full (strict)' in Cloudflare"
}

configure_firewall() {
    if [ "$CONFIGURE_FIREWALL" = false ]; then
        return
    fi
    
    print_info "Configuring UFW firewall..."
    
    # Install UFW if not present
    apt-get install -y ufw
    
    # Reset UFW
    ufw --force reset
    
    # Default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow SSH
    ufw allow 22/tcp
    
    # Allow HTTP/HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Allow Pterodactyl Wings (if installing later)
    ufw allow 8080/tcp
    ufw allow 2022/tcp
    
    # Allow Tailscale
    if [ "$INSTALL_TAILSCALE" = true ]; then
        ufw allow 41641/udp
    fi
    
    # Enable firewall
    ufw --force enable
    
    print_success "Firewall configured"
}

install_phpmyadmin() {
    if [ "$INSTALL_PHPMYADMIN" = false ]; then
        return
    fi
    
    print_info "Installing phpMyAdmin..."
    
    # Download phpMyAdmin
    PHPMYADMIN_VERSION=$(curl -s https://www.phpmyadmin.net/downloads/ | grep -oE 'phpMyAdmin-[0-9]+\.[0-9]+\.[0-9]+' | head -1 | sed 's/phpMyAdmin-//')
    cd /var/www
    wget -q "https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN_VERSION}/phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.tar.gz"
    tar xzf "phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.tar.gz"
    mv "phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages" phpmyadmin
    rm "phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.tar.gz"
    
    # Configure
    mkdir -p /var/www/phpmyadmin/tmp
    chown -R www-data:www-data /var/www/phpmyadmin
    chmod 777 /var/www/phpmyadmin/tmp
    
    # Nginx config
    cat > /etc/nginx/sites-available/phpmyadmin.conf <<EOF
server {
    listen 8081;
    server_name _;
    
    root /var/www/phpmyadmin;
    index index.php;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOF
    
    ln -sf /etc/nginx/sites-available/phpmyadmin.conf /etc/nginx/sites-enabled/phpmyadmin.conf
    
    nginx -t && systemctl restart nginx
    
    print_success "phpMyAdmin installed (accessible on port 8081)"
}

setup_web_hosting() {
    if [ "$ENABLE_WEB_HOSTING" = false ]; then
        return
    fi
    
    show_progress "Setting up web hosting environment"
    
    # Create websites directory structure
    mkdir -p /var/www/websites
    mkdir -p /var/www/websites/default
    
    # Create sample index page
    cat > /var/www/websites/default/index.php << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Web Hosting Active</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
        .container {
            text-align: center;
            background: rgba(255, 255, 255, 0.1);
            padding: 3rem;
            border-radius: 15px;
            backdrop-filter: blur(10px);
        }
        h1 { font-size: 3rem; margin: 0 0 1rem 0; }
        p { font-size: 1.2rem; margin: 0.5rem 0; }
        .info { background: rgba(0,0,0,0.3); padding: 1rem; border-radius: 10px; margin-top: 2rem; }
        code { background: rgba(0,0,0,0.5); padding: 0.3rem 0.6rem; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 Web Hosting Active!</h1>
        <p>Your dynamic website hosting is ready</p>
        <div class="info">
            <p><strong>Document Root:</strong> <code>/var/www/websites/default/</code></p>
            <p><strong>PHP Version:</strong> <code><?php echo PHP_VERSION; ?></code></p>
            <p><strong>Server Time:</strong> <code><?php echo date('Y-m-d H:i:s'); ?></code></p>
        </div>
        <p style="margin-top: 2rem; font-size: 0.9rem;">Replace this file to deploy your website</p>
    </div>
</body>
</html>
EOF
    
    # Set permissions
    chown -R www-data:www-data /var/www/websites
    chmod -R 755 /var/www/websites
    
    # Create nginx configuration for websites
    if [ -n "$WEB_HOSTING_DOMAIN" ]; then
        # Specific domain provided
        cat > /etc/nginx/sites-available/website.conf <<EOFNX
server {
    listen 80;
    server_name $WEB_HOSTING_DOMAIN www.$WEB_HOSTING_DOMAIN;
    
    root /var/www/websites/default;
    index index.php index.html index.htm;

    access_log /var/log/nginx/website-access.log;
    error_log /var/log/nginx/website-error.log;

    client_max_body_size 100M;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOFNX
        
        # Setup SSL if enabled
        if [ "$CONFIGURE_SSL" = true ]; then
            print_info "Configuring SSL for website..."
            certbot --nginx -d "$WEB_HOSTING_DOMAIN" -d "www.$WEB_HOSTING_DOMAIN" --non-interactive --agree-tos --email "$EMAIL" --redirect 2>/dev/null || \
            certbot --nginx -d "$WEB_HOSTING_DOMAIN" --non-interactive --agree-tos --email "$EMAIL" --redirect
        fi
    else
        # No specific domain, create IP-based config
        cat > /etc/nginx/sites-available/website.conf <<EOFNX
server {
    listen 8080;
    server_name _;
    
    root /var/www/websites/default;
    index index.php index.html index.htm;

    access_log /var/log/nginx/website-access.log;
    error_log /var/log/nginx/website-error.log;

    client_max_body_size 100M;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOFNX
    fi
    
    ln -sf /etc/nginx/sites-available/website.conf /etc/nginx/sites-enabled/website.conf
    
    # Create helper script for adding more sites
    cat > /usr/local/bin/add-website << 'EOFSCRIPT'
#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

echo "=== Add New Website ==="
echo
read -p "Enter domain name (e.g., example.com): " DOMAIN
read -p "Enter site directory name (e.g., mysite): " SITENAME

if [ -z "$DOMAIN" ] || [ -z "$SITENAME" ]; then
    echo "Error: Domain and site name are required"
    exit 1
fi

# Create directory
mkdir -p /var/www/websites/$SITENAME

# Create basic index
cat > /var/www/websites/$SITENAME/index.html << EOFHTML
<!DOCTYPE html>
<html>
<head><title>$DOMAIN</title></head>
<body><h1>Welcome to $DOMAIN</h1><p>Website is live!</p></body>
</html>
EOFHTML

# Set permissions
chown -R www-data:www-data /var/www/websites/$SITENAME
chmod -R 755 /var/www/websites/$SITENAME

# Create nginx config
cat > /etc/nginx/sites-available/$SITENAME.conf <<EOFNGINX
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    root /var/www/websites/$SITENAME;
    index index.php index.html index.htm;

    access_log /var/log/nginx/${SITENAME}-access.log;
    error_log /var/log/nginx/${SITENAME}-error.log;

    client_max_body_size 100M;

    location / {
        try_files \\\$uri \\\$uri/ /index.php?\\\$query_string;
    }

    location ~ \\.php\\\$ {
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \\\$document_root\\\$fastcgi_script_name;
    }

    location ~ /\\.ht {
        deny all;
    }
}
EOFNGINX

# Enable site
ln -sf /etc/nginx/sites-available/$SITENAME.conf /etc/nginx/sites-enabled/$SITENAME.conf

# Test and reload nginx
nginx -t && systemctl reload nginx

echo
echo "✓ Website created successfully!"
echo "  Directory: /var/www/websites/$SITENAME"
echo "  Domain: http://$DOMAIN"
echo
echo "To add SSL certificate:"
echo "  certbot --nginx -d $DOMAIN -d www.$DOMAIN"
echo
EOFSCRIPT
    
    chmod +x /usr/local/bin/add-website
    
    # Reload nginx
    nginx -t && systemctl reload nginx
    
    add_rollback_action "rm -rf /var/www/websites; rm -f /etc/nginx/sites-enabled/website.conf"
    INSTALLED_COMPONENTS+=("web_hosting")
    
    if [ -n "$WEB_HOSTING_DOMAIN" ]; then
        print_success "Web hosting configured for $WEB_HOSTING_DOMAIN"
    else
        print_success "Web hosting configured on port 8080"
        print_info "Access at: http://$(hostname -I | awk '{print $1}'):8080"
    fi
    
    print_info "Add more websites with: sudo add-website"
    save_state "web_hosting_configured"
}

#########################################################################
# Main Installation Flow                                               #
#########################################################################

print_installation_summary() {
    clear
    echo -e "${GREEN}${BOLD}"
    cat << "EOF"
   _____ _    _  _____ _____ ______  _____ _____ 
  / ____| |  | |/ ____/ ____|  ____|/ ____/ ____|
 | (___ | |  | | |   | |    | |__  | (___| (___  
  \___ \| |  | | |   | |    |  __|  \___ \\___ \ 
  ____) | |__| | |___| |____| |____ ____) |___) |
 |_____/ \____/ \_____\_____|______|_____/_____/ 
                                                  
EOF
    echo -e "${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}                  Installation Complete!${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${PURPLE}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}${BOLD}║${NC}                 ${WHITE}Access Information${NC}                    ${PURPLE}${BOLD}║${NC}"
    echo -e "${PURPLE}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${CYAN}${BOLD}Panel URL:${NC}          ${WHITE}https://$FQDN${NC}"
    echo -e "${CYAN}${BOLD}Admin Email:${NC}        ${WHITE}$EMAIL${NC}"
    echo -e "${CYAN}${BOLD}Database Password:${NC}  ${YELLOW}$DB_PASSWORD${NC}"
    echo
    
    if [ "$INSTALL_PHPMYADMIN" = true ]; then
        echo -e "${CYAN}${BOLD}phpMyAdmin:${NC}         ${WHITE}http://$(hostname -I | awk '{print $1}'):8081${NC}"
    fi
    
    if [ "$INSTALL_TAILSCALE" = true ]; then
        echo -e "${CYAN}${BOLD}Tailscale:${NC}          ${YELLOW}Run 'tailscale up' to connect${NC}"
    fi
    
    if [ "$INSTALL_CLOUDFLARE" = true ]; then
        echo -e "${CYAN}${BOLD}Cloudflare:${NC}         ${YELLOW}Configure DNS and SSL settings${NC}"
    fi
    
    if [ "$ENABLE_WEB_HOSTING" = true ]; then
        echo -e "${CYAN}${BOLD}Web Hosting:${NC}        ${WHITE}/var/www/websites/${NC}"
        if [ -n "$WEB_HOSTING_DOMAIN" ]; then
            echo -e "${CYAN}${BOLD}Website URL:${NC}        ${WHITE}https://$WEB_HOSTING_DOMAIN${NC}"
        fi
    fi
    
    echo
    echo -e "${YELLOW}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${BOLD}║${NC}                  ${WHITE}Important Notes${NC}                       ${YELLOW}${BOLD}║${NC}"
    echo -e "${YELLOW}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "  ${YELLOW}▸${NC} Save your database password in a secure location"
    echo -e "  ${YELLOW}▸${NC} Access your panel and complete the setup wizard"
    echo -e "  ${YELLOW}▸${NC} Install Pterodactyl Wings on game server nodes"
    echo -e "  ${YELLOW}▸${NC} Review firewall rules if needed"
    echo
    echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}          Installation completed successfully! 🚀${NC}"
    echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════════${NC}"
    echo
}

main() {
    # Parse command-line arguments
    parse_arguments "$@"
    
    # Setup logging
    setup_logging
    
    # Load config if provided
    if [ -n "$CONFIG_FILE" ]; then
        load_config_file "$CONFIG_FILE"
    fi
    
    print_header
    check_root
    detect_os
    
    # Pre-flight checks
    if [ "$SILENT_MODE" = false ]; then
        echo -e "${YELLOW}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}${BOLD}║${NC}               ${WHITE}Pre-Flight Checks${NC}                     ${YELLOW}${BOLD}║${NC}"
        echo -e "${YELLOW}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
        echo
        check_system_requirements
        check_internet
        check_existing_installation
        check_ports
        check_conflicting_software
        detect_system_resources
        echo
        printf "${GREEN}All checks passed! Press ENTER to continue...${NC}"
        read -r
    fi
    
    # Get user input if not silent mode
    if [ "$SILENT_MODE" = false ]; then
        get_user_input
    fi
    
    # Calculate total steps
    TOTAL_STEPS=10
    [ "$INSTALL_MARIADB" = true ] && ((TOTAL_STEPS++))
    [ "$INSTALL_PHPMYADMIN" = true ] && ((TOTAL_STEPS++))
    [ "$INSTALL_TAILSCALE" = true ] && ((TOTAL_STEPS++))
    [ "$INSTALL_CLOUDFLARE" = true ] && ((TOTAL_STEPS++))
    [ "$CONFIGURE_SSL" = true ] && ((TOTAL_STEPS++))
    [ "$INSTALL_FAIL2BAN" = true ] && ((TOTAL_STEPS++))
    [ "$INSTALL_MODSECURITY" = true ] && ((TOTAL_STEPS++))
    [ "$ENABLE_WEB_HOSTING" = true ] && ((TOTAL_STEPS++))
    
    print_header
    echo -e "${PURPLE}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}${BOLD}║${NC}              ${WHITE}Starting Installation Process${NC}            ${PURPLE}${BOLD}║${NC}"
    echo -e "${PURPLE}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo
    sleep 1
    
    # Installation steps
    update_system
    install_dependencies
    install_docker
    install_php
    install_composer
    install_mariadb
    install_nginx
    install_pterodactyl
    configure_nginx
    configure_ssl
    setup_web_hosting
    install_tailscale
    configure_cloudflare
    configure_firewall
    install_phpmyadmin
    install_fail2ban
    install_modsecurity
    configure_ssh_hardening
    enable_auto_updates
    
    # Create initial backup
    if [ "$AUTO_BACKUP" = true ]; then
        print_info "Creating initial backup..."
        create_backup
    fi
    
    # Post-install validation
    sleep 2
    run_post_install_checks
    
    # Final summary
    sleep 2
    print_installation_summary
    
    # Save final state
    save_state "installation_complete"
    log "Installation completed successfully"
    
    echo -e "${CYAN}Full installation log: ${WHITE}$LOG_FILE${NC}"
    echo
}

# Run main function
main "$@"
