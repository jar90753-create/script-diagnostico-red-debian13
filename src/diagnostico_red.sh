#!/bin/bash
# ==============================================================
#  Script de diagnóstico de red - Debian 13 (Trixie)
#  Ejecuta ping, traceroute y netstat sobre una lista de hosts
#  y genera un informe de conectividad.
#  Uso:  ./diagnostico_red.sh                (usa la lista interna)
#        ./diagnostico_red.sh hosts.txt      (lee hosts desde archivo)
# ==============================================================

# ---------- 1. Configuración ----------
PAQUETES_PING=4                       # cuántos paquetes enviar con ping
MAX_SALTOS=15                         # saltos máximos de traceroute
FECHA=$(date +"%Y-%m-%d_%H-%M-%S")
DIR_INFORMES="$HOME/informes_red"
INFORME="$DIR_INFORMES/informe_$FECHA.txt"

# Colores para la terminal
VERDE="\e[32m"; ROJO="\e[31m"; AMARILLO="\e[33m"; AZUL="\e[34m"; NC="\e[0m"

# ---------- 2. Array de hosts ----------
if [[ -n "$1" && -f "$1" ]]; then
    mapfile -t HOSTS < <(grep -v '^\s*#' "$1" | grep -v '^\s*$')   # desde archivo
else
    HOSTS=("google.com" "debian.org" "8.8.8.8" "1.1.1.1" "github.com" "host-inexistente.local")
fi

# Arrays asociativos para guardar resultados por host
declare -A ESTADO
declare -A LATENCIA
declare -A PERDIDA
declare -A SALTOS

# ---------- 3. Funciones ----------
verificar_dependencias() {
    local faltantes=()
    for cmd in ping traceroute netstat; do
        command -v "$cmd" &>/dev/null || faltantes+=("$cmd")
    done
    if (( ${#faltantes[@]} > 0 )); then
        echo -e "${ROJO}Faltan comandos: ${faltantes[*]}${NC}"
        echo "Instálalos con:  sudo apt install iputils-ping traceroute net-tools"
        exit 1
    fi
}

escribir() {                      # muestra en pantalla y guarda en el informe
    echo -e "$1"
    echo -e "$1" | sed 's/\x1b\[[0-9;]*m//g' >> "$INFORME"
}

encabezado() {
    escribir "${AZUL}==============================================================${NC}"
    escribir "${AZUL} $1${NC}"
    escribir "${AZUL}==============================================================${NC}"
}

probar_ping() {
    local host=$1
    local salida
    salida=$(ping -c "$PAQUETES_PING" -W 2 "$host" 2>&1)
    if [[ $? -eq 0 ]]; then
        ESTADO[$host]="ACTIVO"
        PERDIDA[$host]=$(echo "$salida" | grep -oP '\d+(?=% packet loss)')
        LATENCIA[$host]=$(echo "$salida" | awk -F'/' '/rtt|round-trip/ {print $5}')
        escribir "  ${VERDE}[OK]${NC} Responde - Latencia promedio: ${LATENCIA[$host]} ms - Pérdida: ${PERDIDA[$host]}%"
    else
        ESTADO[$host]="INACTIVO"
        PERDIDA[$host]="100"
        LATENCIA[$host]="-"
        escribir "  ${ROJO}[FALLA]${NC} No responde al ping"
    fi
}

probar_traceroute() {
    local host=$1
    local salida
    salida=$(traceroute -m "$MAX_SALTOS" -w 2 "$host" 2>&1)
    SALTOS[$host]=$(echo "$salida" | tail -n +2 | wc -l)
    escribir "  Ruta (${SALTOS[$host]} saltos):"
    while IFS= read -r linea; do
        escribir "    $linea"
    done <<< "$(echo "$salida" | tail -n +2)"
}

mostrar_netstat() {
    encabezado "CONEXIONES ACTIVAS DEL EQUIPO (netstat)"
    escribir "Puertos en escucha (TCP/UDP):"
    netstat -tuln 2>/dev/null | tail -n +3 | while IFS= read -r l; do escribir "  $l"; done
    escribir ""
    escribir "Conexiones TCP establecidas: $(netstat -tn 2>/dev/null | grep -c ESTABLISHED)"
    escribir ""
    escribir "Tabla de enrutamiento:"
    netstat -rn 2>/dev/null | while IFS= read -r l; do escribir "  $l"; done
}

resumen() {
    local activos=0 inactivos=0
    encabezado "RESUMEN DE CONECTIVIDAD"
    escribir "$(printf '%-25s %-10s %-14s %-10s %-6s' HOST ESTADO LATENCIA PERDIDA SALTOS)"
    escribir "--------------------------------------------------------------------"
    for host in "${HOSTS[@]}"; do
        local color=$VERDE
        if [[ ${ESTADO[$host]} == "ACTIVO" ]]; then ((activos++)); else ((inactivos++)); color=$ROJO; fi
        escribir "$(printf '%-25s' "$host") ${color}$(printf '%-10s' "${ESTADO[$host]}")${NC} $(printf '%-14s %-10s %-6s' "${LATENCIA[$host]} ms" "${PERDIDA[$host]}%" "${SALTOS[$host]}")"
    done
    escribir "--------------------------------------------------------------------"
    escribir "Total: ${#HOSTS[@]} hosts | ${VERDE}Activos: $activos${NC} | ${ROJO}Inactivos: $inactivos${NC}"
}

# ---------- 4. Programa principal ----------
verificar_dependencias
mkdir -p "$DIR_INFORMES"
: > "$INFORME"

encabezado "INFORME DE DIAGNÓSTICO DE RED"
escribir "Fecha:   $(date)"
escribir "Equipo:  $(hostname)"
escribir "Usuario: $USER"
escribir "IP local: $(hostname -I | awk '{print $1}')"
escribir "Hosts a analizar (${#HOSTS[@]}): ${HOSTS[*]}"
escribir ""

for i in "${!HOSTS[@]}"; do
    host=${HOSTS[$i]}
    encabezado "[$((i+1))/${#HOSTS[@]}] Analizando: $host"
    escribir "${AMARILLO}> PING${NC}"
    probar_ping "$host"
    escribir "${AMARILLO}> TRACEROUTE${NC}"
    if [[ ${ESTADO[$host]} == "ACTIVO" ]]; then
        probar_traceroute "$host"
    else
        SALTOS[$host]="-"
        escribir "  Omitido (el host no responde)"
    fi
    escribir ""
done

mostrar_netstat
escribir ""
resumen
escribir ""
escribir "Informe guardado en: $INFORME"
