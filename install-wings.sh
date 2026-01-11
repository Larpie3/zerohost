#!/bin/bash

#########################################################################
# Pterodactyl Wings Advanced Installer                                #
# For game server nodes with Tailscale support                        #
#########################################################################

set -e

# Color codes
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
NC='\033[0m'

VERSION="1.0.0"

# Variables
INSTALL_TAILSCALE=false
CONFIGURE_FIREWALL=false
PANEL_URL=""
TOKEN=""
AUTO_MODE=false

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --auto)
                AUTO_MODE=true
                shift 1
                ;;
            --tailscale)
                INSTALL_TAILSCALE=true
                shift 1
                ;;
            --no-firewall)
                CONFIGURE_FIREWALL=false
                shift 1
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            --version|-v)
                echo "Pterodactyl Wings Installer v$VERSION"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << EOF
${CYAN}${BOLD}Pterodactyl Wings Installer v$VERSION${NC}

${WHITE}Usage:${NC}
  $0 [OPTIONS]

${WHITE}Options:${NC}
  ${GREEN}--auto${NC}              Skip all prompts, use default settings (non-interactive)
  ${GREEN}--tailscale${NC}         Automatically install Tailscale VPN
  ${GREEN}--no-firewall${NC}       Skip UFW firewall configuration
  ${GREEN}--help, -h${NC}          Show this help message
  ${GREEN}--version, -v${NC}       Show version information

${WHITE}Examples:${NC}
  ${DIM}# Interactive installation${NC}
  sudo $0
  
  ${DIM}# Fully automated install with Tailscale, no firewall${NC}
  sudo $0 --auto --tailscale --no-firewall
  
  ${DIM}# Auto install with firewall but no Tailscale${NC}
  sudo $0 --auto

${YELLOW}${BOLD}Installation Modes:${NC}
  ${WHITE}Interactive (default):${NC}
    Prompts for Tailscale and firewall configuration.
  
  ${WHITE}Automated (--auto):${NC}
    Non-interactive mode for scripting.
    Combine with --tailscale and --no-firewall as needed.
    Perfect for use with \`install.sh --essentials\`.

${YELLOW}${BOLD}Post-Installation:${NC}
  1. Create a node in your Pterodactyl panel
  2. Copy the auto-deploy command from the panel
  3. Run it on this server to configure Wings
  4. Start Wings: systemctl start wings

EOF
}

#########################################################################
# Helper Functions                                                      #
#########################################################################

print_header() {
    clear
    echo -e "${CYAN}"
    echo "═══════════════════════════════════════════════════════════════════════"
    echo -e "${PURPLE}${BOLD}"
    cat << "EOF"
  _      ___                 
 | | /| / (_)__  ___ ____
 | |/ |/ / / _ \/ _ `(_-<
 |__/|__/_/_//_/\_, /___/
               /___/      
    ____  __                          __           __
   / __ \/ /____  _________  ____/ /___ ______/ /___  __
  / /_/ / __/ _ \/ ___/ __ \/ __  / __ `/ ___/ __/ / / /
 / ____/ /_/  __/ /  / /_/ / /_/ / /_/ / /__/ /_/ /_/ /
/_/    \__/\___/_/   \____/\__,_/\__,_/\___/\__/\__, /
                                                /____/
EOF
    echo -e "${CYAN}"
    echo "═══════════════════════════════════════════════════════════════════════"
    echo -e "${GREEN}${BOLD}           Game Server Node Installer ${WHITE}v${VERSION}${NC}"
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

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root!"
        exit 1
    fi
}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VER=$VERSION_ID
    else
        print_error "Cannot detect OS"
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
# User Input                                                            #
#########################################################################

get_user_input() {
    print_header
    echo -e "${GREEN}${BOLD}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║${NC}   ${WHITE}Wings Node Installation Configuration${NC}     ${GREEN}${BOLD}║${NC}"
    echo -e "${GREEN}${BOLD}╚═══════════════════════════════════════════════════════╝${NC}"
    echo
    
    # Tailscale
    read -p "$(echo -e ${CYAN}${BOLD}[?]${NC} Install Tailscale VPN? \(${GREEN}Y${NC}/${RED}n${NC}\): )" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        INSTALL_TAILSCALE=true
    fi

    # Firewall
    read -p "$(echo -e ${CYAN}${BOLD}[?]${NC} Configure UFW firewall? \(${GREEN}Y${NC}/${RED}n${NC}\): )" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        CONFIGURE_FIREWALL=true
    fi

    echo
    echo -e "${GREEN}${BOLD}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║${NC}  ${WHITE}✓ Configuration Complete!${NC}                         ${GREEN}${BOLD}║${NC}"
    echo -e "${GREEN}${BOLD}╚═══════════════════════════════════════════════════════╝${NC}"
    echo
    read -p "$(echo -e ${YELLOW}${BOLD}➤${NC} Press ${GREEN}ENTER${NC} to begin installation...)" -r
}

#########################################################################
# Installation Functions                                               #
#########################################################################

update_system() {
    print_info "Updating system..."
    apt-get update -qq
    apt-get upgrade -y -qq
    print_success "System updated"
}

install_dependencies() {
    print_info "Installing dependencies..."
    
    apt-get install -y -qq \
        curl \
        tar \
        unzip \
        git \
        ca-certificates \
        gnupg \
        lsb-release

    print_success "Dependencies installed"
}

install_docker() {
    print_info "Installing Docker..."
    
    apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/$OS/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update -qq
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    systemctl enable --now docker
    
    print_success "Docker installed"
}

configure_docker_network() {
    print_info "Configuring Docker network..."
    
    cat > /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
    
    systemctl restart docker
    
    print_success "Docker network configured"
}

install_wings() {
    print_info "Installing Pterodactyl Wings..."
    
    mkdir -p /etc/pterodactyl
    curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
    
    chmod u+x /usr/local/bin/wings
    
    # Create systemd service
    cat > /etc/systemd/system/wings.service <<EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl enable wings
    
    print_success "Wings installed"
    print_warning "Configure /etc/pterodactyl/config.yml from your panel before starting Wings"
}

install_tailscale() {
    if [ "$INSTALL_TAILSCALE" = false ]; then
        return
    fi
    
    print_info "Installing Tailscale..."
    
    curl -fsSL https://tailscale.com/install.sh | sh
    
    print_success "Tailscale installed"
    print_warning "Run 'tailscale up' to connect to your tailnet"
}

configure_firewall() {
    if [ "$CONFIGURE_FIREWALL" = false ]; then
        return
    fi
    
    print_info "Configuring firewall..."
    
    apt-get install -y ufw
    
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    
    # SSH
    ufw allow 22/tcp
    
    # Wings
    ufw allow 8080/tcp
    ufw allow 2022/tcp
    
    # SFTP
    ufw allow 2022/tcp
    
    # Game server ports (you may need to adjust these)
    ufw allow 25565/tcp  # Minecraft
    ufw allow 25565/udp
    ufw allow 27015/tcp  # Source games
    ufw allow 27015/udp
    ufw allow 7777/tcp   # ARK/Unreal
    ufw allow 7777/udp
    
    # Tailscale
    if [ "$INSTALL_TAILSCALE" = true ]; then
        ufw allow 41641/udp
    fi
    
    ufw --force enable
    
    print_success "Firewall configured"
}

kernel_modifications() {
    print_info "Applying kernel modifications for game servers..."
    
    cat >> /etc/sysctl.conf <<EOF

# Pterodactyl Wings optimizations
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
vm.swappiness=10
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
EOF
    
    sysctl -p
    
    print_success "Kernel modifications applied"
}

#########################################################################
# Main                                                                  #
#########################################################################

print_summary() {
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
    echo -e "${GREEN}${BOLD}             Wings Node Installation Complete!${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${PURPLE}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}${BOLD}║${NC}                     ${WHITE}Next Steps${NC}                         ${PURPLE}${BOLD}║${NC}"
    echo -e "${PURPLE}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "  ${YELLOW}▸${NC} Create a new node in your Pterodactyl panel"
    echo -e "  ${YELLOW}▸${NC} Copy the auto-deploy command from the panel"
    echo -e "  ${YELLOW}▸${NC} Run the command on this server to configure Wings"
    echo -e "  ${YELLOW}▸${NC} Start Wings: ${CYAN}systemctl start wings${NC}"
    echo
    
    if [ "$INSTALL_TAILSCALE" = true ]; then
        echo
        echo -e "${YELLOW}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}${BOLD}║${NC}                    ${WHITE}Tailscale Setup${NC}                       ${YELLOW}${BOLD}║${NC}"
        echo -e "${YELLOW}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
        echo
        echo -e "  ${YELLOW}▸${NC} Run: ${CYAN}tailscale up${NC}"
        echo -e "  ${YELLOW}▸${NC} Your panel can connect via Tailscale IP"
    fi
    
    echo
    echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}        Wings is ready to be configured! 🚀${NC}"
    echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════════${NC}"
    echo
}

main() {
    parse_arguments "$@"
    print_header
    check_root
    detect_os
    if [ "$AUTO_MODE" = false ]; then
        get_user_input
    else
        print_info "Auto mode enabled: skipping prompts"
    fi
    
    print_header
    echo -e "${PURPLE}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}${BOLD}║${NC}              ${WHITE}Starting Installation Process${NC}            ${PURPLE}${BOLD}║${NC}"
    echo -e "${PURPLE}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo
    sleep 1
    
    update_system
    install_dependencies
    install_docker
    configure_docker_network
    install_wings
    install_tailscale
    configure_firewall
    kernel_modifications
    
    print_summary
}
main "$@"
