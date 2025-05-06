#!/bin/bash
# 900584, Puertolas Merenciano, David

if [[ $EUID -ne 0 ]]; then
    echo "Este script necesita privilegios de administracion" >&2
    exit 1
fi

if [[ $# -ne 2 ]]; then
    echo "Numero incorrecto de parametros"
    exit 1
fi

if [[ $1 != "-a" && $1 != "-s" ]]; then
    echo "Opcion invalida" >&2
    exit 1
fi

if [[ "$1" == "-s" ]]; then
    mkdir -p /extra/backup
fi

while IFS=, read -r usuario password nombre_completo; do
    usuario=$(echo "$usuario" | xargs)
    password=$(echo "$password" | xargs)
    nombre_completo=$(echo "$nombre_completo" | xargs)
    
    if [[ "$1" == "-a" ]]; then
        if [[ -z "$usuario" || -z "$password" || -z "$nombre_completo" ]]; then
            echo "Campo invalido"
            exit 1
        fi
        
        if id "$usuario" &>/dev/null; then
            echo "El usuario $usuario ya existe"
        else
            useradd -K UID_MIN=1815 -U -c "$nombre_completo" -m -k /etc/skel "$usuario"
            echo "$usuario:$password" | chpasswd
            usermod -e $(date -d "+30 days" +%Y-%m-%d) "$usuario"
            echo "$nombre_completo ha sido creado"
        fi
    else
        if [[ -z "$usuario" ]]; then
            echo "Campo invalido"
            exit 1
        fi
        
        if id "$usuario" &>/dev/null; then
            home_dir=$(eval echo ~$usuario)
            if [ -d "$home_dir" ]; then
                tar -cf "/extra/backup/$usuario.tar" "$home_dir" &>/dev/null
                if [[ $? -eq 0 ]]; then
                    userdel -r "$usuario"
                fi
            else
                userdel "$usuario"
            fi
        fi
    fi
done < "$2"

exit 0
