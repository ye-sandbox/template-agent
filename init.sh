#!/usr/bin/env bash
# ==============================================================================
# Script de Inicialização Rápida de Projetos Infra (ADD - Serviços & Homelab)
# Cria um novo projeto a partir do template infra com repositório Git limpo
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
            echo "Uso: init.sh [-y|--yes] [NOME_OU_DIRETORIO_DO_PROJETO]"
            echo ""
            echo "Opções:"
            echo "  -y, --yes, -f, --force    Executar sem confirmações interativas"
            echo "  -h, --help                Exibir esta mensagem de ajuda"
            echo ""
            echo "Exemplo:"
            echo "  curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/infra/init.sh | bash -s -- meu-homelab"
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

# Solicitar nome do projeto caso não tenha sido fornecido via argumento
if [ -z "$TARGET_DIR" ]; then
    if [ -c /dev/tty ]; then
        read -p "Digite o nome da pasta para o novo projeto de infra (ex: meu-homelab): " -r TARGET_DIR </dev/tty || true
    elif [ -t 0 ]; then
        read -p "Digite o nome da pasta para o novo projeto de infra (ex: meu-homelab): " -r TARGET_DIR || true
    fi
fi

if [ -z "$TARGET_DIR" ]; then
    echo "❌ Erro: O nome da pasta/projeto não foi especificado." >&2
    echo "Uso: init.sh [NOME_DO_PROJETO]" >&2
    exit 1
fi

TEMPLATE_REPO_URL="${TEMPLATE_REPO_URL:-https://github.com/ye-sandbox/template-agent.git}"

echo "======================================================="
echo " Inicializador de Projeto Infra (ADD Serviços & Homelab)"
echo " Destino: $(mkdir -p "$TARGET_DIR" && cd "$TARGET_DIR" && pwd)"
echo " Origem:  $TEMPLATE_REPO_URL (branch infra)"
echo "======================================================="

# Verificar se a pasta já existe e possui arquivos
if [ -d "$TARGET_DIR" ] && [ "$(ls -A "$TARGET_DIR" 2>/dev/null)" ]; then
    echo "⚠️  Aviso: O diretório '$TARGET_DIR' já existe e não está vazio."
    if [ "$FORCE_YES" != true ]; then
        CONFIRM=""
        if [ -c /dev/tty ]; then
            read -p "Deseja continuar mesmo assim? Arquivos existentes podem ser sobrescritos. (s/N): " -r CONFIRM </dev/tty || true
        elif [ -t 0 ]; then
            read -p "Deseja continuar mesmo assim? Arquivos existentes podem ser sobrescritos. (s/N): " -r CONFIRM || true
        fi
        if [[ ! "$CONFIRM" =~ ^[sSyY]$ ]]; then
            echo "Operação cancelada pelo usuário."
            exit 1
        fi
    fi
fi

# Criar pasta de destino temporária para o clone
TEMP_CLONE_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_CLONE_DIR"' EXIT

echo "⏳ Clonando o template Infra..."
git clone --depth 1 -b infra "$TEMPLATE_REPO_URL" "$TEMP_CLONE_DIR" >/dev/null 2>&1

# Copiar arquivos para o diretório de destino
mkdir -p "$TARGET_DIR"
cp -r "$TEMP_CLONE_DIR/." "$TARGET_DIR/"

# Remover o script de inicialização do projeto de destino
rm -f "$TARGET_DIR/init.sh"

# Entrar no diretório do projeto e reinicializar um histórico Git limpo
cd "$TARGET_DIR"
rm -rf .git
git init -b main >/dev/null 2>&1

# Configurar git commit com fallback de autor caso não configurado globalmente
GIT_AUTHOR_NAME="$(git config user.name 2>/dev/null || echo "Developer")"
GIT_AUTHOR_EMAIL="$(git config user.email 2>/dev/null || echo "dev@local")"

git add .
GIT_AUTHOR_NAME="$GIT_AUTHOR_NAME" \
GIT_AUTHOR_EMAIL="$GIT_AUTHOR_EMAIL" \
GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME" \
GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL" \
git commit -m "chore: initial infra and service orchestration setup" >/dev/null 2>&1

RESOLVED_PATH="$(pwd)"

echo ""
echo "======================================================="
echo "🎉 Projeto de Infraestrutura criado com sucesso em:"
echo "   $RESOLVED_PATH"
echo ""
echo "👉 Próximos passos:"
echo "1. Entre na pasta do seu projeto:"
echo "   cd $TARGET_DIR"
echo ""
echo "2. Configure suas variáveis de ambiente:"
echo "   cp .env.example .env"
echo ""
echo "3. Crie seu compose.yaml a partir do exemplo:"
echo "   cp compose.yaml.example compose.yaml"
echo ""
echo "4. Abra no seu editor com agente de IA (Cursor, Windsurf, VS Code, Antigravity):"
echo "   code ."
echo ""
echo "5. Envie o primeiro prompt para o agente de IA:"
echo ""
echo "   \"Leia o AGENTS.md, .agent/SERVICES.md, .agent/TASK.md e a skill em .agent/skills/compose-service/SKILL.md."
echo "    Apresente seu plano de implementação para a Tarefa [00.1] antes de alterar qualquer arquivo de configuração.\""
echo "======================================================="
