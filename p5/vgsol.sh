#!/bin/bash
# Autor David Puertolas Merenciano (900584)


# Comprobamos que hay al menos 2 argumentos (VG + una particion)
if  [ "$#" -lt 2 ]; then
	echo "Uso: $0 <nombre_vg> <particion1> [particion2...]"
	exit 1
fi


VG_NAME=$1
shift


# Inicializamos la 1a particion
echo "Inicializando $1 como volumen fisico"
sudo pvcreate -ff "$1" -y
sudo vgreduce --removemissing "$VG_NAME"
sleep 3

#Si ya existe, anadimos la particion al grupo
if  vgdisplay "$VG_NAME" 2>&1; then
	echo "Agregando $1 al grupo de volumenes $VG_NAME"
	#sudo vgreduce --removemissing "$VG_NAME"
	sudo vgextend "$VG_NAME" "$1"
else
	# Si el grupo no existe, lo creamos con la primera particion
	echo "Creando grupo de volumenes $VG_NAME con $1"
	#sudo vgreduce --removemissing "$VG_NAME"
	sudo vgcreate "$VG_NAME" "$1"
fi



shift


# Para particiones restantes
for PART in "$@"; do
	echo "Inicializando $PART como volumen fisico"
	sudo pvcreate -ff "$PART" -y
	echo "Agregando $PART al grupo de volumenes $VG_NAME"
	#sudo vgreduce --removemissing "$VG_NAME"
	sudo vgextend "$VG_NAME" "$PART"
done


# Mostrar estado final del grupo
echo "Estado actual del grupo de volumenes"
sudo vgdisplay "$VG_NAME" 
