#!/bin/bash

# Pterodactyl Panel Helper Script
# Quick access to common management commands

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PANEL_DIR="/var/www/pterodactyl"

show_menu() {
    clear
    echo "═════════════════════════════════════════════════"
    echo "     Pterodactyl Panel Management Menu"
    echo "═════════════════════════════════════════════════"
    echo
    echo "1)  Check Installation Status"
    echo "2)  View Service Status"
    echo "3)  View Installation Logs"
    echo "4)  Restart All Services"
    echo "5)  Create Backup"
    echo "6)  Create FULL Backup (Everything)"
    echo "7)  Update Panel"
    echo "8)  Create Admin User"
    echo "9)  Restart Queue Worker"
    echo "10) View Error Logs"
    echo "11) Check SSL Certificate"
    echo "12) Firewall Status"
    echo "13) System Resources"
    echo "14) Database Console"
    echo "15) Download Backup"
    echo "16) Factory Reset (Wipe & Backup)"
    echo "0)  Exit"
    echo
    echo "═════════════════════════════════════════════════"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root"
        exit 1
    fi
}

while true; do
    show_menu
    read -p "Enter your choice [0-16]: " choice
    
    case $choice in
        1)
            "$SCRIPT_DIR/install.sh" --status
            read -p "Press enter to continue..."
            ;;
        2)
            echo
            echo "Service Status:"
            echo "───────────────"
            systemctl status nginx --no-pager -l
            systemctl status mariadb --no-pager -l
            systemctl status redis-server --no-pager -l
            systemctl status pteroq --no-pager -l
            systemctl status docker --no-pager -l
            read -p "Press enter to continue..."
            ;;
        3)
            echo
            echo "Recent installation logs:"
            tail -50 /var/log/pterodactyl-installer/install-*.log 2>/dev/null || echo "No logs found"
            read -p "Press enter to continue..."
            ;;
        4)
            echo
            echo "Restarting services..."
            systemctl restart nginx
            systemctl restart mariadb
            systemctl restart redis-server
            systemctl restart pteroq
            echo "Services restarted!"
            sleep 2
            ;;
        5)
            "$SCRIPT_DIR/install.sh" --backup
            read -p "Press enter to continue..."
            ;;
        6)
            "$SCRIPT_DIR/install.sh" --full-backup
            read -p "Press enter to continue..."
            ;;
        7)
            "$SCRIPT_DIR/install.sh" --update
            read -p "Press enter to continue..."
            ;;
        8)
            echo
            cd "$PANEL_DIR"
            php artisan p:user:make
            read -p "Press enter to continue..."
            ;;
        9)
            echo
            systemctl restart pteroq
            echo "Queue worker restarted!"
            sleep 2
            ;;
        10)
            echo
            echo "Recent error logs:"
            tail -50 /var/log/pterodactyl-installer/error.log 2>/dev/null || echo "No errors logged"
            read -p "Press enter to continue..."
            ;;
        11)
            echo
            certbot certificates
            read -p "Press enter to continue..."
            ;;
        12)
            echo
            ufw status verbose
            read -p "Press enter to continue..."
            ;;
        13)
            echo
            echo "System Resources:"
            echo "─────────────────"
            free -h
            echo
            df -h /
            echo
            uptime
            read -p "Press enter to continue..."
            ;;
        14)
            echo
            mysql -u root -p
            ;;
        15)
            echo
            echo "Available Backups:"
            echo "──────────────────"
            ls -lh /var/backups/pterodactyl*/*.tar.gz 2>/dev/null || echo "No backups found"
            echo
            echo "To download a backup, use SCP:"
            echo "  scp root@$(hostname -I | awk '{print $1}'):/var/backups/pterodactyl*/backup-file.tar.gz ."
            echo
            read -p "Press enter to continue..."
            ;;
        16)
            clear
            echo "═══════════════════════════════════════════════════"
            echo "            FACTORY RESET WARNING"
            echo "═══════════════════════════════════════════════════"
            echo
            echo "This will:"
            echo "  • Create a full backup of ALL data"
            echo "  • Wipe your server clean"
            echo "  • Remove all Pterodactyl components"
            echo
            read -p "Continue to factory reset? (yes/NO): " confirm
            if [ "$confirm" = "yes" ]; then
                "$SCRIPT_DIR/install.sh" --factory-reset
            else
                echo "Cancelled."
                sleep 2
            fi
            ;;
        0)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid option!"
            sleep 2
            ;;
    esac
done
