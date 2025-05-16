#!/bin/bash
# Autor David Puertolas Merenciano (900584)

while IFS=',' read -r VG_NAME LV_NAME SIZE FS_TYPE MOUNT_DIR; do
  LV_PATH="/dev/$VG_NAME/$LV_NAME"

  # Comprobar si el volumen lógico ya existe
  if lvdisplay "$LV_PATH" &>/dev/null; then
    echo "El volumen lógico $LV_PATH existe, extendiendo en $SIZE..."

    # Extender LV
    sudo lvextend -L+"$SIZE" "$LV_PATH"

    # Redimensionar sistema de archivos según FS
    case "$FS_TYPE" in
      ext4)
        sudo resize2fs "$LV_PATH"
        ;;
      xfs)
        sudo xfs_growfs "$MOUNT_DIR"
        ;;
      *)
        echo "Sistema de archivos $FS_TYPE no soportado para redimensionar."
        ;;
    esac
  else
    echo "Creando volumen lógico $LV_PATH de tamaño $SIZE..."

    # Crear LV
    sudo lvcreate -L "$SIZE" -n "$LV_NAME" "$VG_NAME"

    # Formatear el nuevo LV
    sudo mkfs -t "$FS_TYPE" "$LV_PATH"

    # Crear directorio de montaje si no existe
    sudo mkdir -p "$MOUNT_DIR"

    # Montar el LV
    sudo mount "$LV_PATH" "$MOUNT_DIR"

    # Añadir entrada a /etc/fstab copiando opciones de otro LV existente

    # Extraer una línea de ejemplo de LV en /etc/fstab para copiar opciones (excluye comentarios)
    EXAMPLE_LINE=$(grep "^/dev/mapper/" /etc/fstab | head -n1)

    if [[ -z "$EXAMPLE_LINE" ]]; then
      # No hay otras entradas, usa valores por defecto
      OPTIONS="defaults"
      DUMP=0
      PASS=2
    else
      # Extraemos las opciones, dump y pass de la línea de ejemplo
      OPTIONS=$(echo "$EXAMPLE_LINE" | awk '{print $4}')
      DUMP=$(echo "$EXAMPLE_LINE" | awk '{print $5}')
      PASS=$(echo "$EXAMPLE_LINE" | awk '{print $6}')
    fi

    # Componer la nueva línea para /etc/fstab
    NEW_ENTRY="$LV_PATH $MOUNT_DIR $FS_TYPE $OPTIONS $DUMP $PASS"

    # Añadir la entrada al final de /etc/fstab
    echo "$NEW_ENTRY" | sudo tee -a /etc/fstab

    echo "Entrada añadida a /etc/fstab:"
    echo "$NEW_ENTRY"
  fi

done
