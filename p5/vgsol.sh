#!/bin/bash
# prac5_part3_vg.sh
# Autor: [Tu nombre o NIP]
# Fecha: [Fecha actual]
# Descripción: Añade particiones a un grupo de volúmenes (VG), si no están ya añadidas.

# Comprobación de uso
if [ "$#" -lt 2 ]; then
  echo "Uso: $0 <nombre_del_grupo> <partición1> [partición2 ...]"
  exit 1
fi

# Variables
vgname="$1"
shift

# Añadir cada partición
for part in "$@"; do
  echo "Procesando $part..."

  # Verificar si el dispositivo es un Physical Volume válido
  if ! pvs "$part" &>/dev/null; then
    echo "$part no está inicializado como volumen físico. Inicializando con pvcreate..."
    if ! sudo pvcreate "$part"; then
      echo "Error: no se pudo inicializar $part como volumen físico."
      continue
    fi
  else
    echo "$part ya es un volumen físico."
  fi

  # Verificar si ya está en el VG
  if sudo vgdisplay "$vgname" | grep -q "$part"; then
    echo "$part ya está en el grupo de volúmenes $vgname, omitiendo."
  else
    echo "Añadiendo $part a $vgname..."
    if sudo vgextend "$vgname" "$part"; then
      echo "$part añadido correctamente."
    else
      echo "Error: no se pudo añadir $part a $vgname."
    fi
  fi
done

# Mostrar resumen final del VG
echo -e "\nResumen del grupo de volúmenes:"
sudo vgdisplay "$vgname"
