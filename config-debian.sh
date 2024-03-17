#!/bin/bash

#################
### VARIABLES ###
#################
CODEC="libavcodec-extra"
GNOMECOMPADD="gnome-extensions-app gnome-shell-extension-dashtodock gnome-shell-extension-appindicator gnome-shell-extension-arc-menu adwaita-qt6 qgnomeplatform-qt5"
GNOMECOMPDEL="gnome-2048 gnome-klotski gnome-mahjongg gnome-mines gnome-nibbles gnome-robots gnome-sudoku gnome-taquin gnome-games gnome-music totem five-or-more hitori iagno four-in-a-row quadrapassel lightsoff tali gnome-tetravex swell-foop rhythmbox"
ICI=$(dirname "$0")


#################
### FONCTIONS ###
#################
check_cmd()
{
if [[ $? -eq 0 ]]
then
    	echo -e "\033[32mOK\033[0m"
else
    	echo -e "\033[31mERREUR\033[0m"
fi
}

check_pkg()
{
	dpkg -s "$1" &> /dev/null
}

add_pkg()
{
	apt install -y "$1"
}

del_pkg()
{
	apt autoremove -y "$1"
}

add_codec()
{
	for p in $CODEC
	do
		if ! check_pkg "$p"
		then
			echo -n "- - - Installation CoDec $p : "
			add_pkg "$p"
			check_cmd
		fi
	done
}

add_gnome_pkg()
{
	for p in $GNOMECOMPADD
	do
		if ! check_pkg "$p"
		then
			echo -n "- - - Installation composant GNOME $p : "
			add_pkg "$p"
			check_cmd
		fi
	done
}

del_gnome_pkg()
{
	for p in $GNOMECOMPDEL
	do
		if check_pkg "$p"
		then
			echo -n "- - - Suppression composant GNOME $p : "
			del_pkg "$p"
			check_cmd
		fi
	done
}


check_flatpak()
{
	flatpak info "$1"
}

add_flatpak()
{
	flatpak install flathub --noninteractive -y "$1"
}

del_flatpak()
{
	flatpak uninstall --noninteractive -y "$1" && flatpak uninstall --unused  --noninteractive -y
}

refresh_cache()
{
	apt update
}

update_apt()
{
	apt full-upgrade -y
}

update_flatpak()
{
	flatpak update --noninteractive
}


####################
### DEBUT SCRIPT ###
####################
# Tester si root
if [ "$(id -u)" -ne 0 ]
then
 	echo -e "\033[31mERREUR\033[0m Lancer le script avec les droits root"
	exit 1;
fi 

# Cas CHECK-UPDATES
if [[ "$1" = "check" ]]
then
	echo -n "01- - Refresh du cache : "
	refresh_cache
	check_cmd

	echo "02- - Mises à jour APT : "
	update_apt
	check_cmd

	echo "03- - Mises à jour FLATPAK : "
	update_flatpak
	check_cmd

	exit;
fi

# Autres cas
## MAJ APT
echo -n "01- - Refresh du cache : "
refresh_cache
check_cmd
echo -n "02- - Mises à jour APT : "
update_apt
check_cmd

## MAJ FLATPACK
echo -n "03- - Mises à jour FLATPAK : "
update_flatpak
check_cmd

## Installation codec
echo -n "04- Vérification Codec"
add_codec

## Personnalisation GNOME
echo -n "05- Personnalisation composants GNOME"
gsettings set org.gnome.desktop.wm.preferences button-layout ":minimize,maximize,close"
del_gnome_pkg
add_gnome_pkg 

## Install/Suppr APT selon liste
echo "06- Gestion des paquets"
while read -r line
do
	if [[ "$line" == add:* ]]
	then
		p=${line#add:}
		if ! check_pkg "$p"
		then
			echo -n "- - - Installation paquet $p : "
			add_pkg "$p"
			check_cmd
		fi
	fi
	
	if [[ "$line" == del:* ]]
	then
		p=${line#del:}
		if check_pkg "$p"
		then
			echo -n "- - - Suppression paquet $p : "
			del_pkg "$p"
			check_cmd
		fi
	fi
done < "$ICI/packages.list"

## Ajout discord
echo "07- Installation de Discord"
if ! check_pkg discord
then
    wget -O- "https://discord.com/api/download?platform=linux&format=deb" > /tmp/discord.deb
	sudo dpkg -i /tmp/discord.deb
    apt-get install -f -y
fi