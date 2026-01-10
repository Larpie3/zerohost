#!/bin/bash

#########################################################################
# Pre-Installation System Check                                        #
# Run this before installing to verify system readiness                #
#########################################################################

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[➤]${NC} $1"
}

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}          ${WHITE}Pre-Installation System Check${NC}                ${CYAN}║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo

# Check root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root (use sudo)"
    exit 1
else
    print_success "Running as root"
fi

# Check OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_VER=$VERSION_ID
    
    case "$OS" in
        ubuntu)
            if [[ "$OS_VER" =~ ^(20.04|22.04|24.04)$ ]]; then
                print_success "OS: Ubuntu $OS_VER (Supported)"
            else
                print_warning "OS: Ubuntu $OS_VER (Not officially supported)"
            fi
            ;;
        debian)
            if [[ "$OS_VER" =~ ^(11|12)$ ]]; then
                print_success "OS: Debian $OS_VER (Supported)"
            else
                print_warning "OS: Debian $OS_VER (Not officially supported)"
            fi
            ;;
        *)
            print_error "OS: $OS (Not supported)"
            ;;
    esac
else
    print_error "Cannot detect OS"
fi

# Check RAM
total_ram=$(free -m | awk '/^Mem:/{print $2}')
if [ $total_ram -ge 4096 ]; then
    print_success "RAM: ${total_ram}MB (Excellent)"
elif [ $total_ram -ge 2048 ]; then
    print_success "RAM: ${total_ram}MB (Good)"
else
    print_warning "RAM: ${total_ram}MB (Below recommended 2048MB)"
fi

# Check CPU
cpu_cores=$(nproc)
if [ $cpu_cores -ge 2 ]; then
    print_success "CPU: $cpu_cores cores (Good)"
else
    print_warning "CPU: $cpu_cores core (Recommended: 2+)"
fi

# Check disk space
disk_space=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ $disk_space -ge 20 ]; then
    print_success "Disk: ${disk_space}GB available (Good)"
else
    print_warning "Disk: ${disk_space}GB available (Recommended: 20GB+)"
fi

# Check internet connectivity
if ping -c 1 8.8.8.8 &> /dev/null; then
    print_success "Internet: Connected"
else
    print_error "Internet: No connection"
fi

# Check DNS resolution
if nslookg apt-get &> /dev/null || command -v nslookup &> /dev/null; then
    if nslookup google.com &> /dev/null; then
        print_success "DNS: Working"
    else
        print_error "DNS: Resolution failed"
    fi
else
    print_info "DNS: Cannot test (nslookup not installed)"
fi

# Check for existing installations
echo
print_info "Checking for existing installations..."

if systemctl is-active --quiet nginx; then
    print_warning "Nginx is already running"
fi

if systemctl is-active --quiet apache2; then
    print_warning "Apache2 is already running (may conflict with Nginx)"
fi

if systemctl is-active --quiet mariadb || systemctl is-active --quiet mysql; then
    print_warning "MariaDB/MySQL is already running"
fi

if command -v docker &> /dev/null; then
    print_warning "Docker is already installed"
fi

if [ -d "/var/www/pterodactyl" ]; then
    print_warning "Pterodactyl directory exists"
fi

# Check required ports
echo
print_info "Checking required ports..."

check_port() {
    local port=$1
    local service=$2
    if netstat -tuln 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "; then
        print_warning "Port $port is in use ($service)"
        return 1
    else
        print_success "Port $port is available ($service)"
        return 0
    fi
}

check_port 80 "HTTP"
check_port 443 "HTTPS"
check_port 3306 "MySQL/MariaDB"
check_port 8080 "Wings"

echo
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}                  ${WHITE}Check Complete${NC}                        ${CYAN}║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${GREEN}Your system appears ready for installation!${NC}"
echo -e "${YELLOW}Review any warnings above before proceeding.${NC}"
echo
