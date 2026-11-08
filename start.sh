#!/usr/bin/env bash
# ==============================================================================
# Create Aeronautics Minecraft Server — Single Unified Script (Linux / macOS / WSL)
# Usage:
#   ./start.sh                (Checks deps, boots server in background, tails logs)
#   ./start.sh -tunnel        (Boots server + Playit tunnel for internet play)
#   ./start.sh stop           (Safely shuts down server)
#   ./start.sh logs           (Stream live server logs)
#   ./start.sh rcon [cmd]     (Open interactive console or run a Minecraft command)
#   ./start.sh backup         (Zero-downtime world flush and compressed backup)
#   ./start.sh setup          (Verify/install Docker and system packages)
# ==============================================================================
set -euo pipefail

CONTAINER_NAME="mc-create-server"
DATA_DIR="./data"
BACKUP_DIR="./backups"

print_help() {
  echo "=============================================================================="
  echo " Create Aeronautics Server Management (Linux / macOS / WSL)"
  echo "=============================================================================="
  echo "Usage: ./start.sh [command] [options]"
  echo ""
  echo "Commands:"
  echo "  (no args)       Check environment, start server, and stream console logs"
  echo "  -tunnel         Start server AND Playit tunnel for WAN / internet play"
  echo "  stop / down     Gracefully stop the server container"
  echo "  restart         Restart server container"
  echo "  logs            Follow real-time server console output"
  echo "  rcon [cmd]      Open interactive RCON shell or run single command (e.g. ./start.sh rcon list)"
  echo "  backup          Safely freeze saving, flush chunks, archive world to ./backups/"
  echo "  setup / doctor  Verify/install dependencies (Docker, Docker Compose, curl, tar)"
  echo "  help            Display this help message"
  echo ""
}

check_prereqs() {
  echo "=========================================================="
  echo " Create Aeronautics Server Environment Pre-flight Checks"
  echo "=========================================================="

  # 1. Check Docker installed
  if ! command -v docker >/dev/null 2>&1; then
    echo "[WARN] Docker is not installed."
    echo "[INFO] Running automated Docker installation..."
    OS="$(uname -s)"
    if [ "$OS" = "Linux" ]; then
      curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
      sudo sh /tmp/get-docker.sh
      rm -f /tmp/get-docker.sh
      if [ -n "${USER:-}" ] && [ "$USER" != "root" ]; then
        sudo usermod -aG docker "$USER" || true
      fi
      if command -v systemctl >/dev/null 2>&1; then
        sudo systemctl enable --now docker || true
      fi
    elif [ "$OS" = "Darwin" ]; then
      if command -v brew >/dev/null 2>&1; then
        brew install --cask docker
      else
        echo "[ERROR] Please install Docker Desktop for Mac: https://www.docker.com/products/docker-desktop/"
        exit 1
      fi
    fi
  fi

  # 2. Check Docker daemon running
  if ! docker info >/dev/null 2>&1; then
    echo "[INFO] Docker daemon is not active. Attempting to start..."
    if command -v systemctl >/dev/null 2>&1; then
      sudo systemctl start docker || true
    elif [ "$(uname -s)" = "Darwin" ]; then
      open -a Docker || true
    fi
    sleep 3
    if ! docker info >/dev/null 2>&1; then
      echo "[ERROR] Could not connect to Docker daemon. Please verify Docker is running."
      exit 1
    fi
  fi
  echo "[OK] Docker daemon is healthy."

  # 3. Check .env configuration
  if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
      echo "[INFO] Creating .env from .env.example..."
      cp .env.example .env
    fi
  fi

  # 4. Ensure data & backup directories exist
  mkdir -p "$DATA_DIR" "$BACKUP_DIR"

  # 5. Seed ./data volume with template configs if mods directory is fresh
  if [ ! -d "$DATA_DIR/mods" ] && [ -d "./mods" ]; then
    echo "[INFO] Initializing ./data volume with server mods and configurations..."
    mkdir -p "$DATA_DIR/mods" "$DATA_DIR/config" "$DATA_DIR/defaultconfigs" "$DATA_DIR/kubejs"
    cp -rn ./mods/* "$DATA_DIR/mods/" 2>/dev/null || true
    [ -d "./config" ] && cp -rn ./config/* "$DATA_DIR/config/" 2>/dev/null || true
    [ -d "./defaultconfigs" ] && cp -rn ./defaultconfigs/* "$DATA_DIR/defaultconfigs/" 2>/dev/null || true
    [ -d "./kubejs" ] && cp -rn ./kubejs/* "$DATA_DIR/kubejs/" 2>/dev/null || true
    [ -f "./server.properties" ] && cp -n ./server.properties "$DATA_DIR/server.properties" 2>/dev/null || true
    [ -f "./eula.txt" ] && cp -n ./eula.txt "$DATA_DIR/eula.txt" 2>/dev/null || true
    echo "[OK] Data directory initialized."
  fi
}

cmd_up() {
  check_prereqs
  TUNNEL=false
  for arg in "$@"; do
    if [ "$arg" = "-tunnel" ] || [ "$arg" = "--tunnel" ] || [ "$arg" = "-t" ]; then
      TUNNEL=true
    fi
  done

  echo ""
  if [ "$TUNNEL" = true ]; then
    echo "[INFO] Launching Minecraft server with Playit tunnel enabled..."
    docker compose --profile tunnel up -d
  else
    echo "[INFO] Launching Minecraft server in background..."
    docker compose up -d
  fi

  echo ""
  echo "=============================================================================="
  echo " [SUCCESS] Server is online!"
  echo " - Local connection:   localhost:25565"
  echo " - Interactive console: ./start.sh rcon"
  echo " - Graceful shutdown:   ./start.sh stop"
  echo " - Create safe backup:  ./start.sh backup"
  echo "=============================================================================="
  echo ""
  echo "Attaching to live server logs (Press Ctrl+C to detach; server will keep running):"
  echo "------------------------------------------------------------------------------"
  docker compose logs -f --tail=100 minecraft
}

cmd_down() {
  echo "[INFO] Gracefully stopping server and tunnel containers..."
  docker compose --profile tunnel down
  echo "[SUCCESS] All containers stopped cleanly."
}

cmd_restart() {
  cmd_down
  cmd_up "$@"
}

cmd_logs() {
  echo "[INFO] Streaming logs for $CONTAINER_NAME (Press Ctrl+C to exit)..."
  docker compose logs -f --tail=100 minecraft
}

cmd_rcon() {
  if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "[ERROR] Container $CONTAINER_NAME is not running. Start it first with: ./start.sh"
    exit 1
  fi

  if [ $# -gt 0 ]; then
    docker exec -i "$CONTAINER_NAME" rcon-cli "$@"
  else
    echo "[INFO] Connecting to interactive RCON CLI..."
    echo "[INFO] Type 'help' for Minecraft commands, Ctrl+C to exit."
    echo ""
    docker exec -it "$CONTAINER_NAME" rcon-cli
  fi
}

cmd_backup() {
  if [ ! -d "$DATA_DIR/world" ]; then
    echo "[WARN] World folder '$DATA_DIR/world' not found. Start server first to generate world."
    exit 1
  fi

  mkdir -p "$BACKUP_DIR"
  TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
  BACKUP_FILE="${BACKUP_DIR}/world_backup_${TIMESTAMP}.tar.gz"

  IS_RUNNING=false
  if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    IS_RUNNING=true
  fi

  if [ "$IS_RUNNING" = true ]; then
    echo "[INFO] Freezing world save operations via RCON..."
    docker exec "$CONTAINER_NAME" rcon-cli save-off
    echo "[INFO] Flushing chunk writes to disk..."
    docker exec "$CONTAINER_NAME" rcon-cli save-all flush
    sleep 2
  else
    echo "[INFO] Server container is stopped; archiving world directly..."
  fi

  echo "[INFO] Creating compressed backup archive: $BACKUP_FILE ..."
  tar -czf "$BACKUP_FILE" -C "$DATA_DIR" world

  if [ "$IS_RUNNING" = true ]; then
    echo "[INFO] Re-enabling world auto-save via RCON..."
    docker exec "$CONTAINER_NAME" rcon-cli save-on
  fi

  SIZE=$(du -h "$BACKUP_FILE" | awk '{print $1}')
  echo "[SUCCESS] World backup completed!"
  echo " - Destination: $BACKUP_FILE (Size: $SIZE)"
}

cmd_setup() {
  check_prereqs
  echo ""
  echo "[SUCCESS] Host environment setup and verification complete."
}

# Command Router
ACTION="${1:-up}"
if [ "$ACTION" = "-tunnel" ] || [ "$ACTION" = "--tunnel" ]; then
  ACTION="up"
  set -- "up" "$@"
fi
shift || true

case "$ACTION" in
  up|start)
    cmd_up "$@"
    ;;
  down|stop)
    cmd_down
    ;;
  restart)
    cmd_restart "$@"
    ;;
  logs)
    cmd_logs
    ;;
  rcon|console)
    cmd_rcon "$@"
    ;;
  backup)
    cmd_backup
    ;;
  setup|doctor)
    cmd_setup
    ;;
  help|-h|--help)
    print_help
    ;;
  *)
    echo "[ERROR] Unknown command '$ACTION'"
    print_help
    exit 1
    ;;
esac
