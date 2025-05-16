#!/bin/bash
# prac5_part3_vg.sh
# Autor: David Puertolas Merenciano
# Fecha: 2025-05-16
# Descripción: Añade una o más particiones a un grupo de volúmenes.

if [ "$#" -lt 2 ]; then
  echo "Uso: $0 <nombre_volumen_grupo> <part1> [<part2> ...]"
  exit 1
fi

VG_NAME="$1"
shift

for PART in "$@"; do
  if ! sudo pvdisplay "$PART" &>/dev/null; then
    echo "Creando volumen físico en $PART..."
    sudo pvcreate "$PART"
  fi

  echo "Añadiendo $PART a $VG_NAME..."
  sudo vgextend "$VG_NAME" "$PART"
done

echo "Resumen del grupo de volúmenes:"
sudo vgdisplay "$VG_NAME"
