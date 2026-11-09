#!/usr/bin/env bash
# ==============================================================================
# Create Aeronautics Server - Unified Native Launcher (Linux / macOS / WSL / Git Bash)
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

ACTION="${1:-}"

if [ "$ACTION" = "help" ] || [ "$ACTION" = "-h" ] || [ "$ACTION" = "--help" ]; then
    echo "=============================================================================="
    echo " Create Aeronautics Skybound - Native Server Launcher"
    echo "=============================================================================="
    echo "Usage: ./start.sh [command] [options]"
    echo ""
    echo "Commands:"
    echo "  (no arguments)     Start the Minecraft server (Default)"
    echo "  backup             Safely compress the world folder into ./backups/"
    echo "  help               Show this help message"
    echo ""
    echo "Configuration files:"
    echo "  user_jvm_args.txt  Set RAM allocation (-Xmx8G) and garbage collection flags"
    echo "  server.properties  Server settings, difficulty, view distance, port"
    echo "=============================================================================="
    exit 0
fi

if [ "$ACTION" = "backup" ]; then
    echo "[INFO] Creating timestamped backup of world directory..."
    if [ ! -d "world" ]; then
        echo "[ERROR] No world folder found to backup."
        exit 1
    fi
    mkdir -p backups
    TIMESTAMP="$(date +%Y-%m-%d_%H-%M)"
    BACKUP_FILE="backups/world-${TIMESTAMP}.tar.gz"
    tar -czf "$BACKUP_FILE" world
    echo "[SUCCESS] Backup created at: $BACKUP_FILE"
    exit 0
fi


echo "=============================================================================="
echo "      Create Aeronautics Skybound - Native Server Launcher"
echo "=============================================================================="
echo ""

# 1. Java 21 Pre-flight Detection
check_java() {
    if command -v java >/dev/null 2>&1; then
        RAW_VER=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
        MAJOR_VER=$(echo "$RAW_VER" | awk -F '.' '{print $1}')
        if [ "$MAJOR_VER" -ge 21 ] 2>/dev/null; then
            echo "[OK] Detected Java $MAJOR_VER ($RAW_VER)"
            return 0
        fi
    fi
    return 1
}

if ! check_java; then
    echo "[WARN] Java 21 or higher not found in PATH."
    OS="$(uname -s)"
    if [ "$OS" = "Linux" ]; then
        if command -v apt-get >/dev/null 2>&1; then
            echo "[INFO] Installing OpenJDK 21 via apt..."
            sudo apt-get update && sudo apt-get install -y openjdk-21-jre-headless
        elif command -v dnf >/dev/null 2>&1; then
            echo "[INFO] Installing OpenJDK 21 via dnf..."
            sudo dnf install -y java-21-openjdk-headless
        elif command -v pacman >/dev/null 2>&1; then
            echo "[INFO] Installing OpenJDK 21 via pacman..."
            sudo pacman -S --noconfirm jre21-openjdk-headless
        else
            echo "[ERROR] Could not detect package manager. Please install Java 21 manually:"
            echo "https://adoptium.net/temurin/releases/?version=21"
            exit 1
        fi
    elif [ "$OS" = "Darwin" ]; then
        if command -v brew >/dev/null 2>&1; then
            echo "[INFO] Installing OpenJDK 21 via Homebrew..."
            brew install openjdk@21
            sudo ln -sfn /usr/local/opt/openjdk@21/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-21.jdk || true
        else
            echo "[ERROR] Homebrew not found. Please install Java 21 from: https://adoptium.net/"
            exit 1
        fi
    else
        # Under Windows Git Bash / MSYS
        echo "[INFO] Checking for local Windows java runtime..."
        if [ -f "./java-runtime/jdk-21.0.13+9/bin/java.exe" ]; then
            JAVA_CMD="./java-runtime/jdk-21.0.13+9/bin/java.exe"
            echo "[OK] Found local Java runtime: $JAVA_CMD"
        fi
    fi
fi

# 2. EULA acceptance
if [ -f "eula.txt" ]; then
    if ! grep -q "eula=true" eula.txt; then
        echo "eula=true" > eula.txt
        echo "[OK] Minecraft EULA accepted in eula.txt"
    fi
else
    echo "eula=true" > eula.txt
    echo "[OK] Created eula.txt with eula=true"
fi

# 3. Boot NeoForge Server
echo "[INFO] Booting NeoForge Minecraft Server..."
echo "[INFO] Memory and JVM flags: user_jvm_args.txt"
echo "=============================================================================="
echo ""

if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" || "$OSTYPE" == "cygwin" ]]; then
    ${JAVA_CMD:-java} @user_jvm_args.txt @libraries/net/neoforged/neoforge/21.1.264/win_args.txt nogui "$@"
else
    java @user_jvm_args.txt @libraries/net/neoforged/neoforge/21.1.264/unix_args.txt nogui "$@"
fi
