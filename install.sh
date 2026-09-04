#!/usr/bin/env bash
# ==============================================================================
# Script de Instalação do Template Brownfield para Agentes de IA
# Suporta execução local e remota (via curl | bash)
# ==============================================================================
set -euo pipefail

FORCE_YES=false
TARGET_DIR=""

# Parse de argumentos
while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--yes|-f|--force)
            FORCE_YES=true
            shift
            ;;
        -h|--help)
            echo "Uso: install.sh [-y|--yes] [DIRETORIO_DESTINO]"
            echo ""
            echo "Opções:"
            echo "  -y, --yes, -f, --force    Sobrescrever arquivos sem confirmação interativa"
            echo "  -h, --help                Exibir esta mensagem de ajuda"
            exit 0
            ;;
        *)
            if [ -z "$TARGET_DIR" ]; then
                TARGET_DIR="$1"
            else
                echo "⚠️  Argumento extra ignorado: $1"
            fi
            shift
            ;;
    esac
done

TARGET_DIR="${TARGET_DIR:-.}"
mkdir -p "$TARGET_DIR/.agent"
RESOLVED_TARGET="$(cd "$TARGET_DIR" && pwd)"

# Configuração de repositório remoto para instalação via pipe/curl
TEMPLATE_REPO_URL="${TEMPLATE_REPO_URL:-https://raw.githubusercontent.com/ye-sandbox/template-agent/brownfield}"

# Detecção do modo de execução (local vs remoto)
SCRIPT_SOURCE="${BASH_SOURCE[0]:-}"
SCRIPT_DIR=""
if [ -n "$SCRIPT_SOURCE" ] && [ -f "$SCRIPT_SOURCE" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd)"
fi

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/AGENTS.md" ] && [ -d "$SCRIPT_DIR/.agent" ]; then
    INSTALL_MODE="local"
else
    INSTALL_MODE="remote"
fi

echo "======================================================="
echo " Instalador do Template Brownfield (ADD para Legados)"
echo " Destino: $RESOLVED_TARGET"
echo " Modo:    $([ "$INSTALL_MODE" = "local" ] && echo "Local ($SCRIPT_DIR)" || echo "Remoto ($TEMPLATE_REPO_URL)")"
echo "======================================================="

# Função para copiar (local) ou baixar (remoto) arquivos
fetch_file() {
    local rel_path="$1"
    local dest_path="$2"

    if [ "$INSTALL_MODE" = "local" ]; then
        cp "$SCRIPT_DIR/$rel_path" "$dest_path"
    else
        local url="${TEMPLATE_REPO_URL}/${rel_path}"
        if command -v curl >/dev/null 2>&1; then
            curl -fsSL "$url" -o "$dest_path"
        elif command -v wget >/dev/null 2>&1; then
            wget -qO "$dest_path" "$url"
        else
            echo "❌ Erro: 'curl' ou 'wget' é obrigatório para download dos arquivos do template." >&2
            exit 1
        fi
    fi
}

# Função para confirmação do usuário (compatível com execução via pipe)
ask_confirm() {
    local prompt="$1"
    local reply=""

    if [ "$FORCE_YES" = true ]; then
        return 0
    fi

    if [ -c /dev/tty ]; then
        read -p "$prompt (s/N): " -r reply </dev/tty || reply=""
    elif [ -t 0 ]; then
        read -p "$prompt (s/N): " -r reply || reply=""
    else
        echo "⚠️  Terminal não-interativo detectado. Mantendo arquivo existente."
        return 1
    fi

    if [[ "$reply" =~ ^[sSyY]$ ]]; then
        return 0
    else
        return 1
    fi
}

# 1. Instalar AGENTS.md
if [ -f "$RESOLVED_TARGET/AGENTS.md" ]; then
    echo "⚠️  Aviso: 'AGENTS.md' já existe em $RESOLVED_TARGET."
    if ask_confirm "Deseja sobrescrever o AGENTS.md?"; then
        fetch_file "AGENTS.md" "$RESOLVED_TARGET/AGENTS.md"
        echo "✅ AGENTS.md atualizado com sucesso."
    else
        echo "ℹ️  Mantendo o AGENTS.md existente."
    fi
else
    fetch_file "AGENTS.md" "$RESOLVED_TARGET/AGENTS.md"
    echo "✅ AGENTS.md instalado com sucesso."
fi

# 2. Instalar arquivos da pasta .agent
AGENT_FILES=("INVARIANTS.md" "TASK.md" "NOTES.md" "ARCHIVE.md")

for file in "${AGENT_FILES[@]}"; do
    dest="$RESOLVED_TARGET/.agent/$file"
    if [ -f "$dest" ]; then
        if [ "$FORCE_YES" = true ]; then
            fetch_file ".agent/$file" "$dest"
            echo "✅ .agent/$file atualizado (--force)."
        else
            echo "ℹ️  $file já existe em .agent/. Mantendo o arquivo existente."
        fi
    else
        fetch_file ".agent/$file" "$dest"
        echo "✅ .agent/$file instalado."
    fi
done

echo ""
echo "======================================================="
echo "🎉 Instalação concluída com sucesso!"
echo ""
echo "👉 Próximos passos com o seu agente de IA:"
echo "1. Abra a pasta do seu projeto no editor com o agente de IA ativo."
echo "2. Envie o seguinte prompt inicial:"
echo ""
echo "   \"Leia o AGENTS.md e a Tarefa [00.1] no .agent/TASK.md. Apresente seu plano"
echo "    de implementação para a Auditoria e Discovery do projeto antes de alterar qualquer código.\""
echo "======================================================="
