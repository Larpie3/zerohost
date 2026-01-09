#!/bin/bash

#########################################################################
# Pterodactyl Panel Uninstaller                                       #
# Removes Pterodactyl Panel and associated components                 #
#########################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

print_warning() {
    echo -e "${YELLOW}${BOLD}[⚠]${NC} ${YELLOW}$1${NC}"
}

print_error() {
    echo -e "${RED}${BOLD}[✗]${NC} ${RED}$1${NC}"
}

print_success() {
    echo -e "${GREEN}${BOLD}[✓]${NC} ${GREEN}$1${NC}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root!"
        exit 1
    fi
}

confirm_uninstall() {
    clear
    echo -e "${RED}${BOLD}"
    cat << "EOF"
  _   _       _           _        _ _ 
 | | | |_ __ (_)_ __  ___| |_ __ _| | |
 | | | | '_ \| | '_ \/ __| __/ _` | | |
 | |_| | | | | | | | \__ \ || (_| | | |
  \___/|_| |_|_|_| |_|___/\__\__,_|_|_|
EOF
    echo -e "${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${RED}${BOLD}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}${BOLD}║${NC}                     ${WHITE}WARNING${NC}                           ${RED}${BOLD}║${NC}"
    echo -e "${RED}${BOLD}╚═══════════════════════════════════════════════════════╝${NC}"
    echo
    print_warning "This will remove:"
    echo "  • Pterodactyl Panel"
    echo "  • All databases and data"
    echo "  • Nginx configuration"
    echo "  • phpMyAdmin (if installed)"
    echo
    print_warning "This action CANNOT be undone!"
    echo
    read -p "Type 'UNINSTALL' to confirm: " confirmation
    
    if [ "$confirmation" != "UNINSTALL" ]; then
        echo "Uninstall cancelled."
        exit 0
    fi
}

remove_panel() {
    print_warning "Removing Pterodactyl Panel..."
    
    systemctl stop pteroq 2>/dev/null || true
    systemctl disable pteroq 2>/dev/null || true
    rm -f /etc/systemd/system/pteroq.service
    
    rm -rf /var/www/pterodactyl
    rm -rf /var/www/phpmyadmin
    
    print_success "Panel removed"
}

remove_database() {
    print_warning "Removing databases..."
    
    systemctl stop mariadb 2>/dev/null || true
    apt-get remove --purge -y mariadb-server mariadb-client 2>/dev/null || true
    rm -rf /var/lib/mysql
    rm -rf /etc/mysql
    
    print_success "Database removed"
}

remove_nginx() {
    print_warning "Removing Nginx configuration..."
    
    rm -f /etc/nginx/sites-enabled/pterodactyl.conf
    rm -f /etc/nginx/sites-available/pterodactyl.conf
    rm -f /etc/nginx/sites-enabled/phpmyadmin.conf
    rm -f /etc/nginx/sites-available/phpmyadmin.conf
    rm -f /etc/nginx/conf.d/cloudflare.conf
    
    systemctl restart nginx 2>/dev/null || true
    
    print_success "Nginx configuration cleaned"
}

remove_cron() {
    print_warning "Removing cron jobs..."
    
    crontab -l | grep -v "pterodactyl" | grep -v "cloudflare" | crontab - 2>/dev/null || true
    
    print_success "Cron jobs removed"
}

remove_ssl() {
    print_warning "Removing SSL certificates..."
    
    certbot delete --noninteractive 2>/dev/null || true
    
    print_success "SSL certificates removed"
}

main() {
    check_root
    confirm_uninstall
    
    echo
    print_warning "Starting uninstallation..."
    echo
    
    remove_panel
    remove_database
    remove_nginx
    remove_cron
    remove_ssl
    
    echo
    print_success "Uninstallation complete!"
    echo
    print_warning "Note: Docker, Tailscale, and base packages were NOT removed."
    print_warning "To remove them manually, run:"
    echo "  • Docker: apt-get remove --purge docker-ce docker-ce-cli containerd.io"
    echo "  • Tailscale: apt-get remove --purge tailscale"
    echo
}

main
