#!/bin/bash
# ==============================================================
#  Pruebas básicas del proyecto
#  Revisa que cada script de src/ tenga sintaxis válida y permiso
#  de ejecución, y que la lista de hosts exista y no esté vacía.
#  Uso:  ./tests/test_scripts.sh   (desde la raíz del repositorio)
# ==============================================================

DIR_RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
DIR_SRC="$DIR_RAIZ/src"
FALLOS=0

ok()    { echo -e "\e[32m[OK]\e[0m    $1"; }
fallo() { echo -e "\e[31m[FALLO]\e[0m $1"; ((FALLOS++)); }

for script in "$DIR_SRC"/*.sh; do
    nombre=$(basename "$script")

    if bash -n "$script" 2>/dev/null; then
        ok "$nombre: sintaxis válida"
    else
        fallo "$nombre: error de sintaxis"
    fi

    if [[ -x "$script" ]]; then
        ok "$nombre: tiene permiso de ejecución"
    else
        fallo "$nombre: sin permiso de ejecución (usa chmod +x)"
    fi
done

HOSTS="$DIR_SRC/hosts.txt"
if [[ -s "$HOSTS" ]] && grep -qv '^\s*\(#\|$\)' "$HOSTS"; then
    ok "hosts.txt: contiene $(grep -cv '^\s*\(#\|$\)' "$HOSTS") hosts"
else
    fallo "hosts.txt: no existe o no tiene hosts"
fi

echo
if (( FALLOS == 0 )); then
    echo "Todas las pruebas pasaron."
else
    echo "Pruebas con fallos: $FALLOS"
    exit 1
fi
