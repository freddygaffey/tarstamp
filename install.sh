#!/usr/bin/env sh
# tarstamp installer (Linux / macOS / Git Bash / WSL)
# Usage: curl -fsSL https://raw.githubusercontent.com/freddygaffey/tarstamp/main/install.sh | sh
set -e

REPO_RAW="https://raw.githubusercontent.com/freddygaffey/tarstamp/main"
DEST="${HOME}/.tarstamp.sh"
LINE='[ -f "$HOME/.tarstamp.sh" ] && . "$HOME/.tarstamp.sh"'

echo "tarstamp: downloading -> $DEST"
if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$REPO_RAW/tarstamp.sh" -o "$DEST"
elif command -v wget >/dev/null 2>&1; then
    wget -qO "$DEST" "$REPO_RAW/tarstamp.sh"
else
    echo "tarstamp: need curl or wget" >&2
    exit 1
fi
chmod +r "$DEST"

added=0
for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.bash_profile"; do
    [ -f "$rc" ] || continue
    if ! grep -qF ".tarstamp.sh" "$rc"; then
        printf '\n# tarstamp\n%s\n' "$LINE" >> "$rc"
        echo "tarstamp: added source line to $rc"
        added=1
    fi
done

if [ $added -eq 0 ]; then
    echo "tarstamp: no rc file modified (already installed or none found)"
fi

echo "tarstamp: done. restart shell or run:  . $DEST"
