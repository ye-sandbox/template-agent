#!/usr/bin/env bash
# ==============================================================================
# Script de Instalação do Template Brownfield para Agentes de IA
# ==============================================================================
set -euo pipefail

TARGET_DIR="${1:-.}"

echo "======================================================="
echo " Instalador do Template Brownfield (ADD para Legados)"
echo " Destino: $(realpath "$TARGET_DIR")"
echo "======================================================="

# Diretório de origem do script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Verificar se AGENTS.md já existe no destino
if [ -f "$TARGET_DIR/AGENTS.md" ]; then
    echo "⚠️  Aviso: 'AGENTS.md' já existe em $TARGET_DIR."
    read -p "Deseja sobrescrever o AGENTS.md? (s/N): " -r CONFIRM
    if [[ ! "$CONFIRM" =~ ^[sS]$ ]]; then
        echo "Operação cancelada para AGENTS.md. Mantendo o existente."
    else
        cp "$SCRIPT_DIR/AGENTS.md" "$TARGET_DIR/AGENTS.md"
        echo "✅ AGENTS.md atualizado com sucesso."
    fi
else
    cp "$SCRIPT_DIR/AGENTS.md" "$TARGET_DIR/AGENTS.md"
    echo "✅ AGENTS.md instalado com sucesso."
fi

# Criar pasta .agent e copiar arquivos base
mkdir -p "$TARGET_DIR/.agent"

for file in INVARIANTS.md TASK.md NOTES.md ARCHIVE.md; do
    if [ -f "$TARGET_DIR/.agent/$file" ]; then
        echo "ℹ️  $file já existe em .agent/. Mantendo o arquivo existente."
    else
        cp "$SCRIPT_DIR/.agent/$file" "$TARGET_DIR/.agent/$file"
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
