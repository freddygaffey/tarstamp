# tarstamp — timestamped tar snapshots
# https://github.com/freddygaffey/tarstamp

_tarstamp_usage() {
    cat <<'EOF'
usage: tarstamp [-n NAME] <path> [<path> ...]
       tarstamp -h | --help

  -n, --name NAME   archive name (required when passing multiple paths or a glob)
  -h, --help        show this help

examples:
  tarstamp src/                          # → src_<timestamp>.tar
  tarstamp -n pyfiles *.py               # → pyfiles_<timestamp>.tar
  tarstamp --name configs ~/.zshrc ~/.vimrc
EOF
}

tarstamp() {
    local name="" archive start elapsed size
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help) _tarstamp_usage; return 0 ;;
            -n|--name)
                [ -z "$2" ] && { echo "tarstamp: $1 requires a value" >&2; return 1; }
                name=$2; shift 2 ;;
            --name=*) name=${1#--name=}; shift ;;
            -n*)      name=${1#-n};      shift ;;
            --) shift; break ;;
            -*) echo "tarstamp: unknown option '$1'" >&2; return 1 ;;
            *)  break ;;
        esac
    done
    [ $# -eq 0 ] && { _tarstamp_usage >&2; return 1; }
    if [ $# -gt 1 ] && [ -z "$name" ]; then
        echo "tarstamp: multiple paths require -n NAME" >&2; return 1
    fi
    local p
    for p in "$@"; do
        [ ! -e "$p" ] && { echo "tarstamp: '$p' does not exist" >&2; return 1; }
    done
    [ -z "$name" ] && name=$(basename "${1%/}")
    archive="${name}_$(date +%Y%m%d_%H%M%S).tar"
    start=$(perl -MTime::HiRes=time -e 'printf "%.3f", time' 2>/dev/null || date +%s)
    tar cf "$archive" "$@" || return 1
    elapsed=$(perl -MTime::HiRes=time -e "printf \"%.1f\", time - $start" 2>/dev/null \
              || echo "$(($(date +%s) - start))")
    size=$(du -h "$archive" | cut -f1)
    echo "→ $archive | ${elapsed}s | $size"
}

untarstamp() {
    [ -z "$1" ] && { echo "usage: untarstamp <archive>" >&2; return 1; }
    [ ! -f "$1" ] && { echo "untarstamp: '$1' not found" >&2; return 1; }
    local dest
    dest="$(dirname "$1")/$(basename "$1" .tar).extracted"
    mkdir -p "$dest"
    tar xf "$1" -C "$dest" && echo "→ $dest"
}

if [ -n "$BASH_VERSION" ]; then
    complete -f -d tarstamp
    complete -f untarstamp
elif [ -n "$ZSH_VERSION" ]; then
    autoload -Uz compinit && compinit -i 2>/dev/null
    compdef _files tarstamp 2>/dev/null
    compdef _files untarstamp 2>/dev/null
fi
