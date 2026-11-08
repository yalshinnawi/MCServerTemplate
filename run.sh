#!/usr/bin/env bash
# NeoForge Server Direct Launcher (Linux / macOS / WSL)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" || "$OSTYPE" == "cygwin" ]]; then
    exec java @user_jvm_args.txt @libraries/net/neoforged/neoforge/21.1.264/win_args.txt "$@"
else
    exec java @user_jvm_args.txt @libraries/net/neoforged/neoforge/21.1.264/unix_args.txt "$@"
fi

