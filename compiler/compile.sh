#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

AMXXPC="./amxxpc"
chmod +x "$AMXXPC" 2>/dev/null

INCLUDES="-i$SCRIPT_DIR/../include -i$SCRIPT_DIR/../plugins/antispam/scripting/include -i$SCRIPT_DIR/../plugins/server_mute/scripting/include"

if [ -n "$1" ]; then
    SOURCE_FILE="$1"
    OUTPUT_FILE="${SOURCE_FILE%.*}.amxx"
    echo "Compilando: $SOURCE_FILE"
    $AMXXPC "$SOURCE_FILE" $INCLUDES -o"$OUTPUT_FILE"
    if [ $? -eq 0 ]; then
        echo "[EXITO] Compilación finalizada: $OUTPUT_FILE"
    else
        echo "[ERROR] Falló la compilación."
        exit 1
    fi
else
    echo "========================================================"
    echo "  Compilador AMX Mod X 1.10 - Compilando todos los plugins"
    echo "========================================================"
    echo ""

    find "$SCRIPT_DIR/../plugins" -type f -name "*.sma" | while read -r file; do
        out="${file%.*}.amxx"
        echo "----------------------------------------------------"
        echo "Compilando: $(basename "$file")"
        $AMXXPC "$file" $INCLUDES -o"$out"
        if [ $? -eq 0 ]; then
            echo "[OK] Generado: $out"
        else
            echo "[ERROR] Error al compilar $(basename "$file")"
        fi
    done
fi
