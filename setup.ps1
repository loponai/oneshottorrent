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

param(
    [switch]$SkipDockerCheck,
    [string]$InstallPath = "$env:USERPROFILE\Desktop\SafeTorrent"
)

# --- Configuration ---
$script:Version = "1.0.0"

# --- Helper Functions ---
function Write-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  =====================================================" -ForegroundColor Cyan
    Write-Host "       SAFE TORRENT BOX - VPN Protected Downloads" -ForegroundColor White
    Write-Host "  =====================================================" -ForegroundColor Cyan
    Write-Host "         Created by " -ForegroundColor DarkGray -NoNewline
    Write-Host "TOM SPARK" -ForegroundColor Yellow -NoNewline
    Write-Host " | v$script:Version" -ForegroundColor DarkGray
    Write-Host "      YouTube: youtube.com/@TomSparkReviews" -ForegroundColor DarkGray
    Write-Host "  =====================================================" -ForegroundColor Cyan
    Write-Host "   (c) 2026 Tom Spark. Licensed under MIT+Attribution." -ForegroundColor DarkGray
    Write-Host "   Unauthorized copying without credit = DMCA takedown." -ForegroundColor DarkRed
    Write-Host "  =====================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Number, [string]$Text)
    Write-Host "  [$Number] " -ForegroundColor Yellow -NoNewline
    Write-Host $Text -ForegroundColor White
}

function Write-Success {
    param([string]$Text)
    Write-Host "  [OK] " -ForegroundColor Green -NoNewline
    Write-Host $Text -ForegroundColor White
}

function Write-Error-Custom {
    param([string]$Text)
    Write-Host "  [X] " -ForegroundColor Red -NoNewline
    Write-Host $Text -ForegroundColor White
}

function Write-Info {
    param([string]$Text)
    Write-Host "  [i] " -ForegroundColor Cyan -NoNewline
    Write-Host $Text -ForegroundColor Gray
}

function Write-Warning-Custom {
    param([string]$Text)
    Write-Host "  [!] " -ForegroundColor Yellow -NoNewline
    Write-Host $Text -ForegroundColor White
}

function Press-Enter {
    Write-Host ""
    Write-Host "  Press ENTER to continue..." -ForegroundColor DarkGray
    Read-Host | Out-Null
}

function Ask-YesNo {
    param([string]$Question)
    Write-Host ""
    Write-Host "  $Question (Y/N): " -ForegroundColor Yellow -NoNewline
    $response = Read-Host
    return $response -match "^[Yy]"
}

# --- Pre-Flight Checks ---
function Test-DockerInstalled {
    Write-Step "1" "Checking if Docker Desktop is installed..."

    $dockerPath = Get-Command docker -ErrorAction SilentlyContinue
    if (-not $dockerPath) {
        Write-Error-Custom "Docker is NOT installed!"
        Write-Host ""
        Write-Host "  Please install Docker Desktop first:" -ForegroundColor White
        Write-Host "  https://www.docker.com/products/docker-desktop/" -ForegroundColor Cyan
        Write-Host ""
        Write-Warning-Custom "During installation, make sure 'Use WSL 2' is CHECKED!"
        return $false
    }
    Write-Success "Docker is installed"
    return $true
}

function Test-DockerRunning {
    Write-Step "2" "Checking if Docker is running..."

    try {
        $result = docker info 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Docker not running"
        }
        Write-Success "Docker is running"
        return $true
    }
    catch {
        Write-Error-Custom "Docker is NOT running!"
        Write-Host ""
        Write-Host "  Please start Docker Desktop and wait for the whale icon" -ForegroundColor White
        Write-Host "  in the system tray to turn GREEN before continuing." -ForegroundColor White
        return $false
    }
}

# --- VPN Provider Selection ---
function Get-VPNProvider {
    Write-Banner
    Write-Host "  STEP 1: CHOOSE YOUR VPN" -ForegroundColor Magenta
    Write-Host "  -----------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Which VPN provider do you use?" -ForegroundColor White
    Write-Host ""
    Write-Host "    1. NordVPN" -ForegroundColor Green -NoNewline
    Write-Host "     - nordvpn.tomspark.tech " -ForegroundColor Gray -NoNewline
    Write-Host "(4 extra months FREE!)" -ForegroundColor Green
    Write-Host "    2. ProtonVPN" -ForegroundColor Cyan -NoNewline
    Write-Host "   - protonvpn.tomspark.tech " -ForegroundColor Gray -NoNewline
    Write-Host "(3 months FREE!)" -ForegroundColor Cyan
    Write-Host "    3. Surfshark" -ForegroundColor Yellow -NoNewline
    Write-Host "   - surfshark.tomspark.tech " -ForegroundColor Gray -NoNewline
    Write-Host "(3 extra months FREE!)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Select (1-3) [default: 1]: " -ForegroundColor Yellow -NoNewline
    $choice = Read-Host

    switch ($choice) {
        "2" {
            return @{
                Provider = "protonvpn"
                Name = "ProtonVPN"
                URL = "https://account.proton.me/u/0/vpn/OpenVpnIKEv2"
                Affiliate = "https://protonvpn.tomspark.tech/"
                Bonus = "3 months FREE"
            }
        }
        "3" {
            return @{
                Provider = "surfshark"
                Name = "Surfshark"
                URL = "https://my.surfshark.com/vpn/manual-setup/main/openvpn"
                Affiliate = "https://surfshark.tomspark.tech/"
                Bonus = "3 extra months FREE"
            }
        }
        default {
            return @{
                Provider = "nordvpn"
                Name = "NordVPN"
                URL = "https://my.nordaccount.com/dashboard/nordvpn/manual-configuration/"
                Affiliate = "https://nordvpn.tomspark.tech/"
                Bonus = "4 extra months FREE"
            }
        }
    }
}

# --- Credential Collection ---
function Get-VPNCredentials {
    param([hashtable]$VPN)

    Write-Banner
    Write-Host "  STEP 2: VPN CREDENTIALS" -ForegroundColor Magenta
    Write-Host "  -----------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Warning-Custom "You need $($VPN.Name) 'Service Credentials' (NOT your email/password!)"
    Write-Host ""
    Write-Host "  How to get them:" -ForegroundColor White
    Write-Host "  1. Go to: " -ForegroundColor Gray -NoNewline
    Write-Host $VPN.URL -ForegroundColor Cyan
    Write-Host "  2. Look for 'Manual Setup' or 'OpenVPN' credentials" -ForegroundColor Gray
    Write-Host "  3. Copy the Username and Password shown there" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Don't have $($VPN.Name)? Get $($VPN.Bonus)!" -ForegroundColor Green
    Write-Host "  $($VPN.Affiliate)" -ForegroundColor Cyan
    Write-Host ""

    if (Ask-YesNo "Open $($VPN.Name) credential page in your browser now?") {
        Start-Process $VPN.URL
        Write-Host ""
        Write-Info "Browser opened. Copy your credentials, then come back here."
        Press-Enter
    }

    Write-Host ""
    Write-Host "  Enter your Service Username: " -ForegroundColor Yellow -NoNewline
    $username = Read-Host

    Write-Host "  Enter your Service Password: " -ForegroundColor Yellow -NoNewline
    $password = Read-Host

    if ([string]::IsNullOrWhiteSpace($username) -or [string]::IsNullOrWhiteSpace($password)) {
        Write-Error-Custom "Username and password cannot be empty!"
        return $null
    }

    return @{
        Username = $username.Trim()
        Password = $password.Trim()
    }
}

function Get-ServerCountry {
    Write-Banner
    Write-Host "  STEP 3: SERVER LOCATION" -ForegroundColor Magenta
    Write-Host "  -----------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Pick the closest country to you for best speeds!" -ForegroundColor Yellow
    Write-Host "  (Your VPN's no-logs policy protects you on ANY server)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Popular choices:" -ForegroundColor White
    Write-Host "    1. United States" -ForegroundColor Gray
    Write-Host "    2. United Kingdom" -ForegroundColor Gray
    Write-Host "    3. Canada" -ForegroundColor Gray
    Write-Host "    4. Netherlands" -ForegroundColor Gray
    Write-Host "    5. Custom" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Select (1-5) [default: 1]: " -ForegroundColor Yellow -NoNewline
    $choice = Read-Host

    switch ($choice) {
        "2" { return "United Kingdom" }
        "3" { return "Canada" }
        "4" { return "Netherlands" }
        "5" {
            Write-Host "  Enter country name (capitalize first letter): " -ForegroundColor Yellow -NoNewline
            return Read-Host
        }
        default { return "United States" }
    }
}

function Get-Timezone {
    Write-Banner
    Write-Host "  STEP 4: TIMEZONE" -ForegroundColor Magenta
    Write-Host "  ----------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Common timezones:" -ForegroundColor White
    Write-Host "    1. America/Los_Angeles (Pacific)" -ForegroundColor Gray
    Write-Host "    2. America/Denver (Mountain)" -ForegroundColor Gray
    Write-Host "    3. America/Chicago (Central)" -ForegroundColor Gray
    Write-Host "    4. America/New_York (Eastern)" -ForegroundColor Gray
    Write-Host "    5. Europe/London" -ForegroundColor Gray
    Write-Host "    6. Europe/Berlin" -ForegroundColor Gray
    Write-Host "    7. Custom" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Select (1-7) [default: 1]: " -ForegroundColor Yellow -NoNewline
    $choice = Read-Host

    switch ($choice) {
        "2" { return "America/Denver" }
        "3" { return "America/Chicago" }
        "4" { return "America/New_York" }
        "5" { return "Europe/London" }
        "6" { return "Europe/Berlin" }
        "7" {
            Write-Host "  Enter timezone (e.g., Australia/Sydney): " -ForegroundColor Yellow -NoNewline
            return Read-Host
        }
        default { return "America/Los_Angeles" }
    }
}

# --- File Generation ---
function New-EnvFile {
    param(
        [string]$Path,
        [hashtable]$VPN,
        [hashtable]$Credentials,
        [string]$Country,
        [string]$Timezone
    )

    $content = @"
# ==========================================
# TOM SPARK'S SAFE TORRENT BOX CONFIG
# Created by Tom Spark | youtube.com/@TomSparkReviews
#
# VPN: $($VPN.Name) ($($VPN.Affiliate))
# ==========================================

# --- VPN PROVIDER ---
VPN_PROVIDER=$($VPN.Provider)

# --- VPN CREDENTIALS ---
# Service Credentials from: $($VPN.URL)
VPN_USER="$($Credentials.Username)"
VPN_PASSWORD="$($Credentials.Password)"

# --- SERVER LOCATION ---
SERVER_COUNTRIES=$Country

# --- SYSTEM SETTINGS ---
TZ=$Timezone
ROOT_DIR=.
"@

    $content | Out-File -FilePath "$Path\.env" -Encoding UTF8 -NoNewline
}

function New-DockerComposeFile {
    param([string]$Path)

    $content = @'
# ==========================================
# TOM SPARK'S SAFE TORRENT BOX
# Created by Tom Spark | youtube.com/@TomSparkReviews
#
# VPN Options:
#   NordVPN:   nordvpn.tomspark.tech   (4 extra months FREE!)
#   ProtonVPN: protonvpn.tomspark.tech (3 months FREE!)
#   Surfshark: surfshark.tomspark.tech (3 extra months FREE!)
# ==========================================

services:
  gluetun:
    image: qmcgaw/gluetun
    container_name: gluetun
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    ports:
      - 8080:8080   # qBittorrent Web UI
    environment:
      - VPN_SERVICE_PROVIDER=${VPN_PROVIDER}
      - VPN_TYPE=openvpn
      - OPENVPN_USER=${VPN_USER}
      - OPENVPN_PASSWORD=${VPN_PASSWORD}
      - SERVER_COUNTRIES=${SERVER_COUNTRIES}
      - FIREWALL_OUTBOUND_SUBNETS=192.168.0.0/16,10.0.0.0/8,172.16.0.0/12
    volumes:
      - ${ROOT_DIR}/config/gluetun:/gluetun
    restart: always

  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=${TZ}
      - WEBUI_PORT=8080
    volumes:
      - ${ROOT_DIR}/config/qbittorrent:/config
      - ${ROOT_DIR}/downloads:/data/downloads
    network_mode: service:gluetun
    depends_on:
      - gluetun
    restart: always
'@

    $content | Out-File -FilePath "$Path\docker-compose.yml" -Encoding UTF8 -NoNewline
}

# --- Docker Operations ---
function Start-SafeTorrent {
    param([string]$Path)

    Write-Banner
    Write-Host "  LAUNCHING SAFE TORRENT BOX" -ForegroundColor Magenta
    Write-Host "  -------------------------" -ForegroundColor DarkGray
    Write-Host ""

    Push-Location $Path

    Write-Step "1" "Pulling Docker images (this may take a few minutes on first run)..."
    Write-Host ""

    docker compose pull 2>&1 | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }

    Write-Host ""
    Write-Step "2" "Starting containers..."
    Write-Host ""

    docker compose up -d 2>&1 | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }

    Pop-Location

    Write-Host ""
    Write-Step "3" "Waiting for VPN to connect..."

    $maxAttempts = 30
    $attempt = 0
    $connected = $false

    while ($attempt -lt $maxAttempts -and -not $connected) {
        Start-Sleep -Seconds 2
        $attempt++

        $health = docker inspect --format='{{.State.Health.Status}}' gluetun 2>$null
        if ($health -eq "healthy") {
            $connected = $true
        }

        Write-Host "." -NoNewline -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host ""

    if ($connected) {
        # Get VPN IP
        $logs = docker logs gluetun 2>&1 | Select-String "Public IP address is"
        if ($logs) {
            $ip = $logs[-1] -replace '.*Public IP address is (\S+).*', '$1'
            Write-Success "VPN Connected! Your IP: $ip"
        } else {
            Write-Success "VPN Connected!"
        }
        return $true
    } else {
        Write-Error-Custom "VPN connection timed out. Checking logs..."
        Write-Host ""
        docker logs gluetun 2>&1 | Select-String "AUTH_FAILED|error|Error" | Select-Object -Last 5 | ForEach-Object {
            Write-Host "      $_" -ForegroundColor Red
        }
        return $false
    }
}

# --- Guided Setup ---
function Show-SetupGuide {
    param([hashtable]$VPN)

    Write-Banner
    Write-Host "  SETUP GUIDE: qBittorrent" -ForegroundColor Magenta
    Write-Host "  -----------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Press ENTER to open qBittorrent in your browser..." -ForegroundColor Yellow
    Read-Host | Out-Null
    Start-Process "http://localhost:8080"
    Write-Host ""
    Write-Host "  Login:" -ForegroundColor Yellow
    Write-Host "    Username: " -ForegroundColor White -NoNewline
    Write-Host "admin" -ForegroundColor Cyan
    Write-Host "    Password: " -ForegroundColor White -NoNewline
    Write-Host "(check the command below)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host " IMPORTANT " -BackgroundColor DarkRed -ForegroundColor White
    Write-Host "  qBittorrent generates a random password on first run." -ForegroundColor White
    Write-Host ""
    Write-Host "  To find your password:" -ForegroundColor Yellow
    Write-Host "    1. Press " -ForegroundColor White -NoNewline
    Write-Host "Windows + R" -ForegroundColor Cyan -NoNewline
    Write-Host ", type " -ForegroundColor White -NoNewline
    Write-Host "cmd" -ForegroundColor Cyan -NoNewline
    Write-Host ", press Enter" -ForegroundColor White
    Write-Host "    2. In the black window, paste this command:" -ForegroundColor White
    Write-Host ""
    Write-Host "       docker logs qbittorrent 2>&1 | findstr password" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    3. Press Enter - your password will appear" -ForegroundColor White
    Write-Host "    4. Copy the password and use it to log in above" -ForegroundColor White
    Write-Host ""
    Write-Host "  After logging in, change your password:" -ForegroundColor Yellow
    Write-Host "    Tools > Options > Web UI > Password" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host " VPN VERIFICATION " -BackgroundColor DarkGreen -ForegroundColor White
    Write-Host "  Go to: Tools > Options > Advanced" -ForegroundColor White
    Write-Host "  Look for 'Network Interface' - it should say: " -ForegroundColor White -NoNewline
    Write-Host "tun0" -ForegroundColor Green
    Write-Host "  This proves your traffic is going through the VPN tunnel!" -ForegroundColor Gray

    Press-Enter

    # --- Complete ---
    Write-Banner
    Write-Host ""
    Write-Host "  =============================================" -ForegroundColor Green
    Write-Host "       SAFE TORRENT BOX SETUP COMPLETE!" -ForegroundColor White
    Write-Host "  =============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Your Service:" -ForegroundColor Yellow
    Write-Host "    qBittorrent:  http://localhost:8080" -ForegroundColor White
    Write-Host ""
    Write-Host "  Your downloads folder:" -ForegroundColor Yellow
    Write-Host "    $env:USERPROFILE\Desktop\SafeTorrent\downloads\" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Your traffic is now secured through $($VPN.Name)!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  =============================================" -ForegroundColor DarkGray
    Write-Host "  USEFUL COMMANDS" -ForegroundColor Yellow
    Write-Host "  =============================================" -ForegroundColor DarkGray
    Write-Host "    Start:   docker compose up -d" -ForegroundColor Gray
    Write-Host "    Stop:    docker compose down" -ForegroundColor Gray
    Write-Host "    Restart: docker compose restart" -ForegroundColor Gray
    Write-Host "    Status:  docker ps" -ForegroundColor Gray
    Write-Host "    VPN IP:  docker logs gluetun | findstr 'Public IP'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  =============================================" -ForegroundColor Cyan
    Write-Host "  Created by TOM SPARK" -ForegroundColor Yellow
    Write-Host "  Subscribe: youtube.com/@TomSparkReviews" -ForegroundColor White
    Write-Host ""
    Write-Host "  VPN Deals:" -ForegroundColor White
    Write-Host "    NordVPN:   nordvpn.tomspark.tech   " -ForegroundColor Green -NoNewline
    Write-Host "(4 extra months FREE!)" -ForegroundColor Green
    Write-Host "    ProtonVPN: protonvpn.tomspark.tech " -ForegroundColor Cyan -NoNewline
    Write-Host "(3 months FREE!)" -ForegroundColor Cyan
    Write-Host "    Surfshark: surfshark.tomspark.tech " -ForegroundColor Yellow -NoNewline
    Write-Host "(3 extra months FREE!)" -ForegroundColor Yellow
    Write-Host "  =============================================" -ForegroundColor Cyan
    Write-Host ""
}

# --- Main Execution ---
function Main {
    Write-Banner

    # Pre-flight checks
    if (-not $SkipDockerCheck) {
        if (-not (Test-DockerInstalled)) {
            Press-Enter
            exit 1
        }

        if (-not (Test-DockerRunning)) {
            Press-Enter
            exit 1
        }
    }

    Write-Success "Pre-flight checks passed!"
    Press-Enter

    # Collect configuration
    $vpn = Get-VPNProvider
    Write-Host ""
    Write-Success "Selected: $($vpn.Name)"
    Press-Enter

    $credentials = Get-VPNCredentials -VPN $vpn
    if (-not $credentials) {
        exit 1
    }

    $country = Get-ServerCountry
    $timezone = Get-Timezone

    # Confirmation
    Write-Banner
    Write-Host "  CONFIGURATION SUMMARY" -ForegroundColor Magenta
    Write-Host "  ---------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Install Path:    $InstallPath" -ForegroundColor White
    Write-Host "  VPN Provider:    $($vpn.Name)" -ForegroundColor White
    Write-Host "  VPN Username:    $($credentials.Username)" -ForegroundColor White
    Write-Host "  VPN Password:    $("*" * $credentials.Password.Length)" -ForegroundColor White
    Write-Host "  Server Country:  $country" -ForegroundColor White
    Write-Host "  Timezone:        $timezone" -ForegroundColor White
    Write-Host ""

    if (-not (Ask-YesNo "Proceed with installation?")) {
        Write-Host ""
        Write-Info "Installation cancelled."
        exit 0
    }

    # Create directory structure
    Write-Banner
    Write-Host "  CREATING FILES" -ForegroundColor Magenta
    Write-Host "  --------------" -ForegroundColor DarkGray
    Write-Host ""

    Write-Step "1" "Creating directory: $InstallPath"
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
    New-Item -ItemType Directory -Path "$InstallPath\config" -Force | Out-Null
    New-Item -ItemType Directory -Path "$InstallPath\downloads" -Force | Out-Null
    Write-Success "Directories created"

    Write-Step "2" "Generating .env file..."
    New-EnvFile -Path $InstallPath -VPN $vpn -Credentials $credentials -Country $country -Timezone $timezone
    Write-Success ".env file created"

    Write-Step "3" "Generating docker-compose.yml..."
    New-DockerComposeFile -Path $InstallPath
    Write-Success "docker-compose.yml created"

    Press-Enter

    # Launch
    $success = Start-SafeTorrent -Path $InstallPath

    if ($success) {
        Press-Enter
        Show-SetupGuide -VPN $vpn
    } else {
        Write-Host ""
        Write-Error-Custom "Setup failed. Please check your VPN credentials."
        Write-Host ""
        Write-Host "  Common fixes:" -ForegroundColor Yellow
        Write-Host "    1. Make sure you're using 'Service Credentials' from $($vpn.Name)" -ForegroundColor White
        Write-Host "    2. NOT your email/password login" -ForegroundColor White
        Write-Host "    3. Get credentials from: " -ForegroundColor White -NoNewline
        Write-Host $vpn.URL -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  To retry, run this script again." -ForegroundColor Gray
    }
}

# Run
Main
