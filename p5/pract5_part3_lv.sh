#!/bin/bash
# Autor David Puertolas Merenciano (900584)


# Comprobamos que se ha pasado la IP como parametro
if  [ "$#" -ne 1 ]; then
	echo "Uso: $0 <IP_maquina_remota>"
	exit 1
fi

IP_REMOTE=$1


# Ejecutamos comandos remotos por SSH y mostramos los resultados


echo "Discos y tamanos (en bloques):"
ssh "$IP_REMOTE" "sudo sfdisk -s"

echo "------------------------------"


echo "Particiones y tamanos:"
ssh "$IP_REMOTE" "sudo sfdisk -l"

echo "------------------------------"


echo "Sistemos de archivos montados (excluyendo tmpfs):"
ssh "$IP_REMOTE" "sudo df -hT | grep -v tmpfs"
