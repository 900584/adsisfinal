#!/bin/bash

# Comprobación de argumentos
if [ "$#" -ne 0 ]; then
  echo "Este script no acepta argumentos. Debes redirigirle un archivo con la especificación (specs.txt)."
  exit 1
fi

VG_NAME="vg_p5"

# Crear directorios si no existen
sudo mkdir -p /mnt/data /mnt/logs

# Leer specs.txt desde stdin
while read -r LINE; do
  # Ignorar líneas vacías o comentarios
  [[ -z "$LINE" || "$LINE" =~ ^# ]] && continue

  # Separar campos: nombre LV, tamaño, punto de montaje, sistema de archivos
  LV_NAME=$(echo "$LINE" | awk '{print $1}')
  SIZE=$(echo "$LINE" | awk '{print $2}')
  MOUNT_DIR=$(echo "$LINE" | awk '{print $3}')
  FS_TYPE=$(echo "$LINE" | awk '{print $4}')

  LV_PATH="/dev/$VG_NAME/$LV_NAME"

  echo "Creando volumen lógico $LV_PATH de tamaño $SIZE..."

  # Verificar si el volumen lógico ya existe
  if sudo lvdisplay "$LV_PATH" &>/dev/null; then
    echo "Volumen lógico $LV_NAME ya existe. No se recreará."
  else
    sudo lvcreate -L "$SIZE" -n "$LV_NAME" "$VG_NAME"
  fi

  # Comprobar si el dispositivo ya tiene sistema de archivos montado
  if mountpoint -q "$MOUNT_DIR"; then
    echo "$MOUNT_DIR ya está montado. Saltando formato y montaje."
  else
    # Crear sistema de archivos si aún no existe
    if [ "$FS_TYPE" = "ext4" ]; then
      if ! sudo blkid "$LV_PATH" | grep -q ext4; then
        sudo mkfs.ext4 "$LV_PATH"
      fi
    elif [ "$FS_TYPE" = "xfs" ]; then
      # Asegurar que el tamaño sea suficiente (mínimo 16M para evitar errores)
      MIN_XFS_SIZE_MB=16
      SIZE_MB=$(echo "$SIZE" | grep -o '[0-9]*')

      if [ "$SIZE_MB" -lt "$MIN_XFS_SIZE_MB" ]; then
        echo "ERROR: $LV_NAME con XFS necesita al menos ${MIN_XFS_SIZE_MB}M. Saltando."
        continue
      fi

      if ! sudo blkid "$LV_PATH" | grep -q xfs; then
        sudo mkfs.xfs "$LV_PATH"
      fi
    else
      echo "Tipo de sistema de archivos no soportado: $FS_TYPE"
      continue
    fi

    # Añadir al fstab si no está
    if ! grep -qs "$LV_PATH" /etc/fstab; then
      echo "$LV_PATH $MOUNT_DIR $FS_TYPE defaults 0 2" | sudo tee -a /etc/fstab
      echo "Entrada añadida a /etc/fstab:"
      echo "$LV_PATH $MOUNT_DIR $FS_TYPE defaults 0 2"
    else
      echo "Entrada ya presente en /etc/fstab para $LV_PATH"
    fi

    # Montar el volumen
    sudo mount "$LV_PATH" "$MOUNT_DIR"
  fi

  echo

done
