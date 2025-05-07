#!/bin/bash
# 900584, Puertolas Merenciano, David, M, 3, A

if [ $# -ne 3 ]; then
    echo "Numero incorrecto de parametros" >&2
    exit 1
fi

opcion="$1"
usuarios="$2"
maquinas="$3"
clave=~/.ssh/id_ed25519
script_practica3="../practica_3/practica_3.sh"

if [[ "$opcion" != "-a" && "$opcion" != "-s" ]]; then
    echo "Opcion invalida. Usa -a o -s" >&2
    exit 1
fi

if [[ ! -f "$usuarios" || ! -f "$maquinas" || ! -f "$script_practica3" ]]; then
    echo "Fichero de usuarios, maquinas o script no encontrado" >&2
    exit 1
fi

while read -r ip; do
    if ping -c 1 "$ip" &>/dev/null; then
        echo "Conectando con $ip..."
        scp -q -i "$clave" "$script_practica3" "$usuarios" "as@$ip:~"
        ssh -q -i "$clave" "as@$ip" "sudo ~/practica_3.sh \"$opcion\" \"$usuarios\"; rm ~/practica_3.sh ~/$usuarios"
    else
        echo "No se ha podido conectar a la maquina $ip" >&2
    fi
done < "$maquinas"

exit 0
