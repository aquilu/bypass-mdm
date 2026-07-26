#!/bin/bash
set -o pipefail

# clear-dep-record-v2.sh
#
# Caso: un Mac que YA completo el Setup Assistant y esta en uso (tiene un admin
# local funcional), pero conserva un registro de activacion DEP/MDM residual.
# Sintoma tipico: el aviso de inscripcion (Device Enrollment) parpadea unos
# segundos al arrancar y se quita solo.
#
# Este script NO crea usuarios, NO modifica /etc/hosts y NO borra ni reinstala
# nada. Solo hace lo minimo para ese caso: en el volumen Data, elimina los
# registros de activacion reales (.cloudConfigHasActivationRecord /
# .cloudConfigRecordFound), coloca los marcadores de bypass y limpia el nag.
#
# IMPORTANTE: correr desde Recovery. Con macOS arrancado, SIP protege
# /var/db/ConfigurationProfiles y las operaciones fallan. Si hay FileVault,
# desbloquea/monta antes el volumen de datos (diskutil apfs unlockVolume ...).
#
# Companion de bypass-mdm-v2.sh (mismo repo). Basado en el trabajo de Assaf Dori.

# Define color codes
RED='\033[1;31m'
GRN='\033[1;32m'
BLU='\033[1;34m'
YEL='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

# Error handling function
error_exit() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

# Warning function
warn() {
    echo -e "${YEL}WARNING: $1${NC}"
}

# Success function
success() {
    echo -e "${GRN}\xe2\x9c\x93 $1${NC}"
}

# Info function
info() {
    echo -e "${BLU}\xe2\x84\xb9 $1${NC}"
}

# Function to detect system volumes with multiple fallback strategies
# (identica a la de bypass-mdm-v2.sh para mantener el mismo comportamiento)
detect_volumes() {
    local system_vol=""
    local data_vol=""

    info "Detecting system volumes..." >&2

    for vol in /Volumes/*; do
        if [ -d "$vol" ]; then
            vol_name=$(basename "$vol")
            if [[ ! "$vol_name" =~ "Data"$ ]] && [[ ! "$vol_name" =~ "Recovery" ]] && [ -d "$vol/System" ]; then
                system_vol="$vol_name"
                info "Found system volume: $system_vol" >&2
                break
            fi
        fi
    done

    if [ -z "$system_vol" ]; then
        for vol in /Volumes/*; do
            if [ -d "$vol/System" ]; then
                system_vol=$(basename "$vol")
                warn "Using volume with /System directory: $system_vol" >&2
                break
            fi
        done
    fi

    if [ -d "/Volumes/Data" ]; then
        data_vol="Data"
        info "Found data volume: $data_vol" >&2
    elif [ -n "$system_vol" ] && [ -d "/Volumes/$system_vol - Data" ]; then
        data_vol="$system_vol - Data"
        info "Found data volume: $data_vol" >&2
    else
        for vol in /Volumes/*Data; do
            if [ -d "$vol" ]; then
                data_vol=$(basename "$vol")
                warn "Found data volume: $data_vol" >&2
                break
            fi
        done
    fi

    if [ -z "$data_vol" ]; then
        error_exit "Could not detect data volume. Please ensure you're running this in Recovery mode with a macOS installation present."
    fi

    # Para este caso solo necesitamos el volumen Data; el System es opcional.
    echo "${system_vol:-unknown}|$data_vol"
}

# Muestra las entradas relevantes de un directorio ConfigurationProfiles/Settings
show_state() {
    local cp="$1"
    if [ -d "$cp" ]; then
        local listing
        listing=$(ls -la "$cp" 2>/dev/null | grep -E "cloudConfig|depnag|deviceConfiguration")
        if [ -n "$listing" ]; then
            echo "$listing" | sed 's/^/    /'
        else
            echo "    (sin marcadores relevantes)"
        fi
    else
        echo "    (el directorio no existe)"
    fi
}

# --- Detectar volumenes ---
volume_info=$(detect_volumes)
system_volume=$(echo "$volume_info" | cut -d'|' -f1)
data_volume=$(echo "$volume_info" | cut -d'|' -f2)

# --- Cabecera ---
echo ""
echo -e "${CYAN}Clear DEP Record (companion de bypass-mdm-v2.sh)${NC}"
echo -e "${CYAN}Caso: Mac ya configurado con registro DEP residual${NC}"
echo ""
success "System Volume: $system_volume"
success "Data Volume: $data_volume"
echo ""

data_path="/Volumes/$data_volume"
cp_path="$data_path/private/var/db/ConfigurationProfiles/Settings"

# --- Validaciones ---
[ -d "$data_path" ] || error_exit "No existe el volumen de datos: $data_path"

if [ ! -d "$cp_path" ]; then
    warn "No existe $cp_path"
    warn "Puede que este Mac no tenga registro DEP. Se creara para colocar los marcadores."
    mkdir -p "$cp_path" 2>/dev/null || error_exit "No se pudo crear $cp_path (¿estas en Recovery?)"
fi

# --- Estado actual ---
info "Estado actual de ConfigurationProfiles/Settings (volumen Data):"
show_state "$cp_path"
echo ""

# --- Confirmacion ---
read -p "¿Aplicar limpieza del registro DEP en el volumen '$data_volume'? (y/n): " ans
if ! [[ "$ans" =~ ^[Yy]$ ]]; then
    info "Cancelado. No se realizaron cambios."
    exit 0
fi
echo ""

# --- Eliminar registros de activacion reales ---
info "Eliminando registros de activacion..."
for f in .cloudConfigHasActivationRecord .cloudConfigRecordFound; do
    if [ -e "$cp_path/$f" ]; then
        rm -f "$cp_path/$f" 2>/dev/null && success "Eliminado $f" || warn "No se pudo eliminar $f (¿SIP? corre desde Recovery)"
    else
        info "$f no estaba presente"
    fi
done

# --- Eliminar el nag de DEP (lo regenera el sistema; es el aviso que parpadea) ---
if [ -e "$cp_path/com.apple.mdm.depnag.plist" ]; then
    rm -f "$cp_path/com.apple.mdm.depnag.plist" 2>/dev/null && success "Eliminado com.apple.mdm.depnag.plist" || warn "No se pudo eliminar el nag de DEP"
fi

# --- Colocar marcadores de bypass ---
info "Colocando marcadores de bypass..."
for f in .cloudConfigProfileInstalled .cloudConfigRecordNotFound; do
    touch "$cp_path/$f" 2>/dev/null && success "Creado $f" || warn "No se pudo crear $f"
done

# --- Asegurar que el setup quede marcado como hecho (inofensivo si ya lo estaba) ---
touch "$data_path/private/var/db/.AppleSetupDone" 2>/dev/null && success "Marcado .AppleSetupDone" || warn "No se pudo marcar .AppleSetupDone"

echo ""
info "Estado final:"
show_state "$cp_path"
echo ""

echo -e "${GRN}Limpieza completada. Cierra Terminal y reinicia el Mac.${NC}"
echo -e "${NC}Nota: esto solo afecta el registro LOCAL; el equipo sigue en el inventario"
echo -e "${NC}DEP de la organizacion (Apple Business/School Manager)."
echo ""
