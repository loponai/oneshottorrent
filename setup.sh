#!/bin/bash
# ============================================================
# SAFE TORRENT BOX - Simple VPN + qBittorrent Setup
# Created by Tom Spark | https://youtube.com/@TomSparkReviews
#
# LICENSE: MIT with Attribution - You MUST credit Tom Spark
#          if you share, modify, or create content based on this.
#
# VPN Options:
#   NordVPN:   nordvpn.tomspark.tech   (4 extra months FREE!)
#   ProtonVPN: protonvpn.tomspark.tech (3 months FREE!)
#   Surfshark: surfshark.tomspark.tech (3 extra months FREE!)
# ============================================================

VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
DARKGRAY='\033[1;30m'
NC='\033[0m' # No Color

# --- Helper Functions ---
write_banner() {
    clear
    echo ""
    echo -e "  ${CYAN}=====================================================${NC}"
    echo -e "       ${WHITE}SAFE TORRENT BOX - VPN Protected Downloads${NC}"
    echo -e "  ${CYAN}=====================================================${NC}"
    echo -e "         ${DARKGRAY}Created by ${YELLOW}TOM SPARK${DARKGRAY} | v${VERSION}${NC}"
    echo -e "      ${DARKGRAY}YouTube: youtube.com/@TomSparkReviews${NC}"
    echo -e "  ${CYAN}=====================================================${NC}"
    echo -e "   ${DARKGRAY}(c) 2026 Tom Spark. Licensed under MIT+Attribution.${NC}"
    echo -e "   ${RED}Unauthorized copying without credit = DMCA takedown.${NC}"
    echo -e "  ${CYAN}=====================================================${NC}"
    echo ""
}

write_step() {
    echo -e "  ${YELLOW}[$1]${NC} ${WHITE}$2${NC}"
}

write_success() {
    echo -e "  ${GREEN}[OK]${NC} ${WHITE}$1${NC}"
}

write_error() {
    echo -e "  ${RED}[X]${NC} ${WHITE}$1${NC}"
}

write_info() {
    echo -e "  ${CYAN}[i]${NC} ${GRAY}$1${NC}"
}

write_warning() {
    echo -e "  ${YELLOW}[!]${NC} ${WHITE}$1${NC}"
}

press_enter() {
    echo ""
    echo -e "  ${DARKGRAY}Press ENTER to continue...${NC}"
    read -r
}

ask_yes_no() {
    echo ""
    echo -ne "  ${YELLOW}$1 (Y/N): ${NC}"
    read -r response
    [[ "$response" =~ ^[Yy]$ ]]
}

# --- Pre-Flight Checks ---
test_docker_installed() {
    write_step "1" "Checking if Docker is installed..."

    if ! command -v docker &> /dev/null; then
        write_error "Docker is NOT installed!"
        echo ""
        echo -e "  ${WHITE}Please install Docker first:${NC}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo -e "  ${CYAN}https://www.docker.com/products/docker-desktop/${NC}"
            echo -e "  ${WHITE}Download Docker Desktop for Mac${NC}"
        else
            echo -e "  ${CYAN}https://docs.docker.com/engine/install/${NC}"
            echo -e "  ${WHITE}Or run: curl -fsSL https://get.docker.com | sh${NC}"
        fi
        return 1
    fi
    write_success "Docker is installed"
    return 0
}

test_docker_running() {
    write_step "2" "Checking if Docker is running..."

    if ! docker info &> /dev/null; then
        write_error "Docker is NOT running!"
        echo ""
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo -e "  ${WHITE}Please start Docker Desktop and wait for it to be ready.${NC}"
        else
            echo -e "  ${WHITE}Please start Docker: ${CYAN}sudo systemctl start docker${NC}"
        fi
        return 1
    fi
    write_success "Docker is running"
    return 0
}

# --- VPN Provider Selection ---
get_vpn_provider() {
    write_banner
    echo -e "  ${MAGENTA}STEP 1: CHOOSE YOUR VPN${NC}"
    echo -e "  ${DARKGRAY}-----------------------${NC}"
    echo ""
    echo -e "  ${WHITE}Which VPN provider do you use?${NC}"
    echo ""
    echo -e "    ${GREEN}1. NordVPN${NC}     ${GRAY}- nordvpn.tomspark.tech${NC} ${GREEN}(4 extra months FREE!)${NC}"
    echo -e "    ${CYAN}2. ProtonVPN${NC}   ${GRAY}- protonvpn.tomspark.tech${NC} ${CYAN}(3 months FREE!)${NC}"
    echo -e "    ${YELLOW}3. Surfshark${NC}   ${GRAY}- surfshark.tomspark.tech${NC} ${YELLOW}(3 extra months FREE!)${NC}"
    echo ""
    echo -ne "  ${YELLOW}Select (1-3) [default: 1]: ${NC}"
    read -r choice

    case "$choice" in
        2)
            VPN_PROVIDER="protonvpn"
            VPN_NAME="ProtonVPN"
            VPN_URL="https://account.proton.me/u/0/vpn/OpenVpnIKEv2"
            VPN_AFFILIATE="https://protonvpn.tomspark.tech/"
            VPN_BONUS="3 months FREE"
            SUPPORTS_WIREGUARD=true
            ;;
        3)
            VPN_PROVIDER="surfshark"
            VPN_NAME="Surfshark"
            VPN_URL="https://my.surfshark.com/vpn/manual-setup/main/openvpn"
            VPN_AFFILIATE="https://surfshark.tomspark.tech/"
            VPN_BONUS="3 extra months FREE"
            SUPPORTS_WIREGUARD=true
            ;;
        *)
            VPN_PROVIDER="nordvpn"
            VPN_NAME="NordVPN"
            VPN_URL="https://my.nordaccount.com/dashboard/nordvpn/manual-configuration/"
            VPN_AFFILIATE="https://nordvpn.tomspark.tech/"
            VPN_BONUS="4 extra months FREE"
            SUPPORTS_WIREGUARD=false
            VPN_TYPE="openvpn"
            ;;
    esac

    echo ""
    write_success "Selected: $VPN_NAME"
}

# --- VPN Protocol Selection (ProtonVPN/Surfshark only) ---
get_vpn_protocol() {
    if [[ "$SUPPORTS_WIREGUARD" != "true" ]]; then
        VPN_TYPE="openvpn"
        return
    fi

    write_banner
    echo -e "  ${MAGENTA}STEP 2: CHOOSE PROTOCOL${NC}"
    echo -e "  ${DARKGRAY}-----------------------${NC}"
    echo ""
    echo -e "  ${WHITE}Which protocol would you like to use?${NC}"
    echo ""
    echo -e "    ${GREEN}1. OpenVPN${NC}     ${GRAY}- Traditional, widely compatible${NC}"
    echo -e "    ${CYAN}2. WireGuard${NC}   ${GRAY}- Faster, more modern (Recommended)${NC}"
    echo ""
    echo -ne "  ${YELLOW}Select (1-2) [default: 1]: ${NC}"
    read -r protocol_choice

    case "$protocol_choice" in
        2)
            VPN_TYPE="wireguard"
            if [[ "$VPN_PROVIDER" == "protonvpn" ]]; then
                VPN_URL="https://account.proton.me/u/0/vpn/WireGuard"
            else
                VPN_URL="https://my.surfshark.com/vpn/manual-setup/main/wireguard"
            fi
            ;;
        *)
            VPN_TYPE="openvpn"
            if [[ "$VPN_PROVIDER" == "protonvpn" ]]; then
                VPN_URL="https://account.proton.me/u/0/vpn/OpenVpnIKEv2"
            else
                VPN_URL="https://my.surfshark.com/vpn/manual-setup/main/openvpn"
            fi
            ;;
    esac

    echo ""
    write_success "Selected: $VPN_TYPE"
}

# --- Credential Collection ---
get_vpn_credentials() {
    write_banner

    if [[ "$VPN_TYPE" == "wireguard" ]]; then
        echo -e "  ${MAGENTA}STEP 3: WIREGUARD CREDENTIALS${NC}"
        echo -e "  ${DARKGRAY}-----------------------------${NC}"
        echo ""
        write_warning "You need your WireGuard configuration from $VPN_NAME"
        echo ""
        echo -e "  ${WHITE}How to get them:${NC}"
        echo -e "  ${GRAY}1. Go to: ${CYAN}${VPN_URL}${NC}"
        echo -e "  ${GRAY}2. Generate a new WireGuard configuration${NC}"
        echo -e "  ${GRAY}3. You'll need the ${WHITE}Private Key${GRAY} and ${WHITE}Address${GRAY} (IP)${NC}"
        echo ""
        echo -e "  ${WHITE}Example values:${NC}"
        echo -e "  ${GRAY}  Private Key: ${WHITE}yAnz5TF+lXXJte14tji3zlMNq+hd2rYUIgJBgB3fBmk=${NC}"
        echo -e "  ${GRAY}  Address:     ${WHITE}10.2.0.2/32${NC}"
        echo ""
        echo -e "  ${GREEN}Don't have ${VPN_NAME}? Get ${VPN_BONUS}!${NC}"
        echo -e "  ${CYAN}${VPN_AFFILIATE}${NC}"
        echo ""

        if ask_yes_no "Open $VPN_NAME WireGuard page in your browser now?"; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                open "$VPN_URL"
            else
                xdg-open "$VPN_URL" 2>/dev/null || \
                echo -e "  ${CYAN}${VPN_URL}${NC}"
            fi
            echo ""
            write_info "Browser opened. Copy your credentials, then come back here."
            press_enter
        fi

        echo ""
        echo -ne "  ${YELLOW}Enter your WireGuard Private Key: ${NC}"
        read -r WIREGUARD_PRIVATE_KEY

        echo -ne "  ${YELLOW}Enter your WireGuard Address (e.g., 10.2.0.2/32): ${NC}"
        read -r WIREGUARD_ADDRESSES

        if [[ -z "$WIREGUARD_PRIVATE_KEY" || -z "$WIREGUARD_ADDRESSES" ]]; then
            write_error "Private Key and Address cannot be empty!"
            return 1
        fi

        # Clear OpenVPN vars since we're using WireGuard
        VPN_USERNAME=""
        VPN_PASSWORD=""
    else
        echo -e "  ${MAGENTA}STEP 3: VPN CREDENTIALS${NC}"
        echo -e "  ${DARKGRAY}-----------------------${NC}"
        echo ""
        write_warning "You need $VPN_NAME 'Service Credentials' (NOT your email/password!)"
        echo ""
        echo -e "  ${WHITE}How to get them:${NC}"
        echo -e "  ${GRAY}1. Go to: ${CYAN}${VPN_URL}${NC}"
        echo -e "  ${GRAY}2. Look for 'Manual Setup' or 'OpenVPN' credentials${NC}"
        echo -e "  ${GRAY}3. Copy the Username and Password shown there${NC}"
        echo ""
        echo -e "  ${GREEN}Don't have ${VPN_NAME}? Get ${VPN_BONUS}!${NC}"
        echo -e "  ${CYAN}${VPN_AFFILIATE}${NC}"
        echo ""

        if ask_yes_no "Open $VPN_NAME credential page in your browser now?"; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                open "$VPN_URL"
            else
                xdg-open "$VPN_URL" 2>/dev/null || \
                echo -e "  ${CYAN}${VPN_URL}${NC}"
            fi
            echo ""
            write_info "Browser opened. Copy your credentials, then come back here."
            press_enter
        fi

        echo ""
        echo -ne "  ${YELLOW}Enter your Service Username: ${NC}"
        read -r VPN_USERNAME

        echo -ne "  ${YELLOW}Enter your Service Password: ${NC}"
        read -r VPN_PASSWORD

        if [[ -z "$VPN_USERNAME" || -z "$VPN_PASSWORD" ]]; then
            write_error "Username and password cannot be empty!"
            return 1
        fi

        # Clear WireGuard vars since we're using OpenVPN
        WIREGUARD_PRIVATE_KEY=""
        WIREGUARD_ADDRESSES=""
    fi

    return 0
}

get_server_country() {
    write_banner
    echo -e "  ${MAGENTA}STEP 4: SERVER LOCATION${NC}"
    echo -e "  ${DARKGRAY}-----------------------${NC}"
    echo ""
    echo -e "  ${YELLOW}Pick the closest country to you for best speeds!${NC}"
    echo -e "  ${GRAY}(Your VPN's no-logs policy protects you on ANY server)${NC}"
    echo ""
    echo -e "  ${WHITE}Popular choices:${NC}"
    echo -e "    ${GRAY}1. United States${NC}"
    echo -e "    ${GRAY}2. United Kingdom${NC}"
    echo -e "    ${GRAY}3. Canada${NC}"
    echo -e "    ${GRAY}4. Netherlands${NC}"
    echo -e "    ${GRAY}5. Custom${NC}"
    echo ""
    echo -ne "  ${YELLOW}Select (1-5) [default: 1]: ${NC}"
    read -r choice

    case "$choice" in
        2) SERVER_COUNTRY="United Kingdom" ;;
        3) SERVER_COUNTRY="Canada" ;;
        4) SERVER_COUNTRY="Netherlands" ;;
        5)
            echo -ne "  ${YELLOW}Enter country name (capitalize first letter): ${NC}"
            read -r SERVER_COUNTRY
            ;;
        *) SERVER_COUNTRY="United States" ;;
    esac
}

get_timezone() {
    write_banner
    echo -e "  ${MAGENTA}STEP 5: TIMEZONE${NC}"
    echo -e "  ${DARKGRAY}----------------${NC}"
    echo ""
    echo -e "  ${WHITE}Common timezones:${NC}"
    echo -e "    ${GRAY}1. America/Los_Angeles (Pacific)${NC}"
    echo -e "    ${GRAY}2. America/Denver (Mountain)${NC}"
    echo -e "    ${GRAY}3. America/Chicago (Central)${NC}"
    echo -e "    ${GRAY}4. America/New_York (Eastern)${NC}"
    echo -e "    ${GRAY}5. Europe/London${NC}"
    echo -e "    ${GRAY}6. Europe/Berlin${NC}"
    echo -e "    ${GRAY}7. Custom${NC}"
    echo ""
    echo -ne "  ${YELLOW}Select (1-7) [default: 1]: ${NC}"
    read -r choice

    case "$choice" in
        2) TIMEZONE="America/Denver" ;;
        3) TIMEZONE="America/Chicago" ;;
        4) TIMEZONE="America/New_York" ;;
        5) TIMEZONE="Europe/London" ;;
        6) TIMEZONE="Europe/Berlin" ;;
        7)
            echo -ne "  ${YELLOW}Enter timezone (e.g., Australia/Sydney): ${NC}"
            read -r TIMEZONE
            ;;
        *) TIMEZONE="America/Los_Angeles" ;;
    esac
}

# --- File Generation ---
create_env_file() {
    cat > "$SCRIPT_DIR/.env" << EOF
# ==========================================
# TOM SPARK'S SAFE TORRENT BOX CONFIG
# Created by Tom Spark | youtube.com/@TomSparkReviews
#
# VPN: ${VPN_NAME} (${VPN_AFFILIATE})
# Protocol: ${VPN_TYPE}
# ==========================================

# --- VPN PROVIDER ---
VPN_PROVIDER=${VPN_PROVIDER}

# --- VPN PROTOCOL ---
# Options: openvpn, wireguard
VPN_TYPE=${VPN_TYPE}

# --- VPN CREDENTIALS ---
# Credentials from: ${VPN_URL}
EOF

    if [[ "$VPN_TYPE" == "wireguard" ]]; then
        cat >> "$SCRIPT_DIR/.env" << EOF
# WireGuard Configuration
WIREGUARD_PRIVATE_KEY="${WIREGUARD_PRIVATE_KEY}"
WIREGUARD_ADDRESSES="${WIREGUARD_ADDRESSES}"
EOF
    else
        cat >> "$SCRIPT_DIR/.env" << EOF
# OpenVPN Service Credentials
VPN_USER="${VPN_USERNAME}"
VPN_PASSWORD="${VPN_PASSWORD}"
EOF
    fi

    cat >> "$SCRIPT_DIR/.env" << EOF

# --- SERVER LOCATION ---
SERVER_COUNTRIES=${SERVER_COUNTRY}

# --- SYSTEM SETTINGS ---
TZ=${TIMEZONE}
ROOT_DIR=.
EOF
}

# --- Docker Operations ---
start_safe_torrent() {
    write_banner
    echo -e "  ${MAGENTA}LAUNCHING SAFE TORRENT BOX${NC}"
    echo -e "  ${DARKGRAY}-------------------------${NC}"
    echo ""

    cd "$SCRIPT_DIR" || exit 1

    write_step "1" "Pulling Docker images (this may take a few minutes on first run)..."
    echo ""
    docker compose pull 2>&1 | sed 's/^/      /'

    echo ""
    write_step "2" "Starting containers..."
    echo ""
    docker compose up -d 2>&1 | sed 's/^/      /'

    echo ""
    write_step "3" "Waiting for VPN to connect..."

    max_attempts=30
    attempt=0
    connected=false

    while [[ $attempt -lt $max_attempts ]] && [[ "$connected" == "false" ]]; do
        sleep 2
        ((attempt++))

        health=$(docker inspect --format='{{.State.Health.Status}}' gluetun 2>/dev/null)
        if [[ "$health" == "healthy" ]]; then
            connected=true
        fi

        echo -ne "${YELLOW}.${NC}"
    done

    echo ""
    echo ""

    if [[ "$connected" == "true" ]]; then
        ip=$(docker logs gluetun 2>&1 | grep "Public IP address is" | tail -1 | sed 's/.*Public IP address is //' | cut -d' ' -f1)
        if [[ -n "$ip" ]]; then
            write_success "VPN Connected! Your IP: $ip"
        else
            write_success "VPN Connected!"
        fi
        return 0
    else
        write_error "VPN connection timed out. Checking logs..."
        echo ""
        docker logs gluetun 2>&1 | grep -E "AUTH_FAILED|error|Error" | tail -5 | sed 's/^/      /'
        return 1
    fi
}

# --- Setup Guide ---
show_setup_guide() {
    write_banner
    echo -e "  ${MAGENTA}SETUP GUIDE: qBittorrent${NC}"
    echo -e "  ${DARKGRAY}-----------------------${NC}"
    echo ""
    echo -e "  ${YELLOW}Press ENTER to open qBittorrent in your browser...${NC}"
    read -r
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open "http://localhost:8080"
    else
        xdg-open "http://localhost:8080" 2>/dev/null || echo -e "  ${CYAN}Open: http://localhost:8080${NC}"
    fi
    echo ""
    echo -e "  ${YELLOW}Login:${NC}"
    echo -e "    ${WHITE}Username: ${CYAN}admin${NC}"
    echo -e "    ${WHITE}Password: ${CYAN}(check the command below)${NC}"
    echo ""
    echo -e "  ${WHITE} IMPORTANT ${NC}"
    echo -e "  ${WHITE}qBittorrent generates a random password on first run.${NC}"
    echo ""
    echo -e "  ${YELLOW}To find your password:${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "    ${WHITE}1. Open a new Terminal window (Cmd + T)${NC}"
    else
        echo -e "    ${WHITE}1. Open a new terminal window${NC}"
    fi
    echo -e "    ${WHITE}2. Paste this command:${NC}"
    echo ""
    echo -e "       ${CYAN}docker logs qbittorrent 2>&1 | grep password${NC}"
    echo ""
    echo -e "    ${WHITE}3. Press Enter - your password will appear${NC}"
    echo -e "    ${WHITE}4. Copy the password and use it to log in above${NC}"
    echo ""
    echo -e "  ${YELLOW}After logging in, change your password:${NC}"
    echo -e "    ${GRAY}Tools > Options > Web UI > Password${NC}"
    echo ""
    echo -e "  ${WHITE} VPN VERIFICATION ${NC}"
    echo -e "  ${WHITE}Go to: Tools > Options > Advanced${NC}"
    echo -e "  ${WHITE}Look for 'Network Interface' - it should say: ${GREEN}tun0${NC}"
    echo -e "  ${GRAY}This proves your traffic is going through the VPN tunnel!${NC}"

    press_enter

    # --- Complete ---
    write_banner
    echo ""
    echo -e "  ${GREEN}=============================================${NC}"
    echo -e "       ${WHITE}SAFE TORRENT BOX SETUP COMPLETE!${NC}"
    echo -e "  ${GREEN}=============================================${NC}"
    echo ""
    echo -e "  ${YELLOW}Your Service:${NC}"
    echo -e "    ${WHITE}qBittorrent:  http://localhost:8080${NC}"
    echo ""
    echo -e "  ${YELLOW}Your downloads folder:${NC}"
    echo -e "    ${GRAY}${SCRIPT_DIR}/downloads/${NC}"
    echo ""
    echo -e "  ${GREEN}Your traffic is now secured through ${VPN_NAME}!${NC}"
    echo ""
    echo -e "  ${DARKGRAY}=============================================${NC}"
    echo -e "  ${YELLOW}USEFUL COMMANDS${NC}"
    echo -e "  ${DARKGRAY}=============================================${NC}"
    echo -e "    ${GRAY}Start:   docker compose up -d${NC}"
    echo -e "    ${GRAY}Stop:    docker compose down${NC}"
    echo -e "    ${GRAY}Restart: docker compose restart${NC}"
    echo -e "    ${GRAY}Status:  docker ps${NC}"
    echo -e "    ${GRAY}VPN IP:  docker logs gluetun | grep 'Public IP'${NC}"
    echo ""
    echo -e "  ${CYAN}=============================================${NC}"
    echo -e "  ${YELLOW}Created by TOM SPARK${NC}"
    echo -e "  ${WHITE}Subscribe: youtube.com/@TomSparkReviews${NC}"
    echo ""
    echo -e "  ${WHITE}VPN Deals:${NC}"
    echo -e "    ${GREEN}NordVPN:   nordvpn.tomspark.tech   (4 extra months FREE!)${NC}"
    echo -e "    ${CYAN}ProtonVPN: protonvpn.tomspark.tech (3 months FREE!)${NC}"
    echo -e "    ${YELLOW}Surfshark: surfshark.tomspark.tech (3 extra months FREE!)${NC}"
    echo -e "  ${CYAN}=============================================${NC}"
    echo ""
}

# --- Main Execution ---
main() {
    write_banner

    # Pre-flight checks
    if ! test_docker_installed; then
        press_enter
        exit 1
    fi

    if ! test_docker_running; then
        press_enter
        exit 1
    fi

    write_success "Pre-flight checks passed!"
    press_enter

    # Collect configuration
    get_vpn_provider
    get_vpn_protocol

    if ! get_vpn_credentials; then
        exit 1
    fi

    get_server_country
    get_timezone

    # Confirmation
    write_banner
    echo -e "  ${MAGENTA}CONFIGURATION SUMMARY${NC}"
    echo -e "  ${DARKGRAY}---------------------${NC}"
    echo ""
    echo -e "  ${WHITE}Install Path:    ${SCRIPT_DIR}${NC}"
    echo -e "  ${WHITE}VPN Provider:    ${VPN_NAME}${NC}"
    echo -e "  ${WHITE}VPN Protocol:    ${VPN_TYPE}${NC}"
    if [[ "$VPN_TYPE" == "wireguard" ]]; then
        echo -e "  ${WHITE}WG Private Key:  $(echo "$WIREGUARD_PRIVATE_KEY" | head -c 10)...${NC}"
        echo -e "  ${WHITE}WG Address:      ${WIREGUARD_ADDRESSES}${NC}"
    else
        echo -e "  ${WHITE}VPN Username:    ${VPN_USERNAME}${NC}"
        echo -e "  ${WHITE}VPN Password:    $(printf '*%.0s' $(seq 1 ${#VPN_PASSWORD}))${NC}"
    fi
    echo -e "  ${WHITE}Server Country:  ${SERVER_COUNTRY}${NC}"
    echo -e "  ${WHITE}Timezone:        ${TIMEZONE}${NC}"
    echo ""

    if ! ask_yes_no "Proceed with installation?"; then
        echo ""
        write_info "Installation cancelled."
        exit 0
    fi

    # Create directory structure
    write_banner
    echo -e "  ${MAGENTA}CREATING FILES${NC}"
    echo -e "  ${DARKGRAY}--------------${NC}"
    echo ""

    write_step "1" "Creating directories..."
    mkdir -p "$SCRIPT_DIR/config"
    mkdir -p "$SCRIPT_DIR/downloads"
    write_success "Directories created"

    write_step "2" "Generating .env file..."
    create_env_file
    write_success ".env file created"

    press_enter

    # Launch
    if start_safe_torrent; then
        press_enter
        show_setup_guide
    else
        echo ""
        write_error "Setup failed. Please check your VPN credentials."
        echo ""
        echo -e "  ${YELLOW}Common fixes:${NC}"
        if [[ "$VPN_TYPE" == "wireguard" ]]; then
            echo -e "    ${WHITE}1. Make sure your WireGuard Private Key is correct${NC}"
            echo -e "    ${WHITE}2. Verify your WireGuard Address matches the config${NC}"
            echo -e "    ${WHITE}3. Generate a new config from: ${CYAN}${VPN_URL}${NC}"
        else
            echo -e "    ${WHITE}1. Make sure you're using 'Service Credentials' from ${VPN_NAME}${NC}"
            echo -e "    ${WHITE}2. NOT your email/password login${NC}"
            echo -e "    ${WHITE}3. Get credentials from: ${CYAN}${VPN_URL}${NC}"
        fi
        echo ""
        echo -e "  ${GRAY}To retry, run this script again.${NC}"
    fi
}

# Run
main
