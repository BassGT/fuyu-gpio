#!/usr/bin/env bash
# Script para compilar y copiar binarios en el contenedor de desarrollo
set -eo pipefail

# Verificar si se pasó el nombre del ejecutable
if [ -z "$1" ]; then
    echo "Uso: ./build-and-copy.sh <nombre-del-ejecutable>"
    echo "Ejemplos:"
    echo "  ./build-and-copy.sh test1"
    echo "  ./build-and-copy.sh test2-74HC595"
    exit 1
fi

TARGET="$1"

echo "=========================================="
echo "⚙️  Compilando '$TARGET'..."
echo "=========================================="
cabal build "$TARGET"

echo "=========================================="
echo "🔍 Localizando binario..."
echo "=========================================="

# Intentamos obtener la ruta con cabal list-bin (filtrando la última línea limpia)
BINARY_PATH=$(cabal list-bin "$TARGET" 2>/dev/null | tail -n 1 || true)

if [ -z "$BINARY_PATH" ] || [ ! -f "$BINARY_PATH" ]; then
    # Intento 2: Buscar especificando el prefijo exe:
    BINARY_PATH=$(cabal list-bin "exe:$TARGET" 2>/dev/null | tail -n 1 || true)
fi

if [ -z "$BINARY_PATH" ] || [ ! -f "$BINARY_PATH" ]; then
    # Fallback: Buscar en dist-newstyle
    BINARY_PATH=$(find dist-newstyle/build -type f \( -name "$TARGET" -o -path "*/x/$TARGET/build/$TARGET/$TARGET" \) 2>/dev/null | head -n 1 || true)
fi

# Verificar si el binario existe
if [ -n "$BINARY_PATH" ] && [ -f "$BINARY_PATH" ]; then
    echo "Ruta del binario: $BINARY_PATH"
    echo "💾 Copiando '$TARGET' al directorio actual..."
    cp "$BINARY_PATH" "./$TARGET"
    chmod +x "./$TARGET"
    echo "🚀 ¡Hecho! El ejecutable '$TARGET' está listo en el directorio actual."
else
    echo "❌ Error: No se pudo encontrar el binario de '$TARGET'."
    echo "Verifica que el nombre coincida con una sección 'executable' en tu archivo .cabal."
    exit 1
fi
