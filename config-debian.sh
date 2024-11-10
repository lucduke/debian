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

// Check if a package is installed by querying dpkg status.
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
	echo -e "01- - Refresh du cache : "
	refresh_cache
	check_cmd

	echo -e "02- - Mises à jour APT : "
	update_apt
	check_cmd

	echo -e "03- - Mises à jour FLATPAK : "
	update_flatpak
	check_cmd

	exit;
fi

# Autres cas
## MAJ APT
echo -e "\033[1;34m01- - Refresh du cache : \033[0m"
refresh_cache
check_cmd
echo -e "\033[1;34m02- - Mises à jour APT : \033[0m"
update_apt
check_cmd

## MAJ FLATPACK
echo -e "\033[1;34m03- - Mises à jour FLATPAK : \033[0m"
update_flatpak
check_cmd

## Installation codec
echo -e "\033[1;34m04- Vérification Codec\033[0m"
add_codec

## Personnalisation GNOME
echo -e "\033[1;34m05- Personnalisation composants GNOME\033[0m"
echo -e " - Personalisation Nautilus"
gsettings set org.gnome.nautilus.list-view default-visible-columns "['name', 'size', 'detailed_type', 'permissions', 'owner', 'group', 'date_modified_with_time']"
gsettings set org.gnome.nautilus.list-view default-column-order "['name', 'size', 'detailed_type', 'permissions', 'owner', 'group', 'date_modified_with_time', 'starred']"
gsettings set org.gnome.nautilus.preferences click-policy 'double'
gsettings set org.gtk.Settings.FileChooser sort-directories-first true
gsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first true
echo -e " - Boutons de fenêtre"
gsettings set org.gnome.desktop.wm.preferences button-layout ":minimize,maximize,close"
echo -e " - Suramplification"
gsettings set org.gnome.desktop.sound allow-volume-above-100-percent true
echo -e " - Détacher les popups des fenêtres"
gsettings set org.gnome.mutter attach-modal-dialogs false
echo -e " - Affichage du calendrier dans le panneau supérieur"
gsettings set org.gnome.desktop.calendar show-weekdate true
echo -e " - Modification du format de la date et heure"
gsettings set org.gnome.desktop.interface clock-show-date true
gsettings set org.gnome.desktop.interface clock-show-weekday true
gsettings set org.gnome.desktop.interface clock-format 24h
echo -e " - Activation du mode nuit"
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
echo -e " - Epuration des fichiers temporaires et de la corbeille de plus de 30 jours"
gsettings set org.gnome.desktop.privacy remove-old-temp-files true
gsettings set org.gnome.desktop.privacy remove-old-trash-files true
gsettings set org.gnome.desktop.privacy old-files-age "30"
echo -e "- Configuration de GNOME Logiciels"
gsettings set org.gnome.software show-ratings true
del_gnome_pkg
add_gnome_pkg 
echo -e "- Personalisation DashToDock"
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position "BOTTOM"
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
gsettings set org.gnome.shell.extensions.dash-to-dock autohide-in-fullscreen true

## Install/Suppr APT selon liste
echo -e "\033[1;34m06- Gestion des paquets via APT\033[0m"
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
echo -e "\033[1;34m07- Installation de Discord\033[0m"
if ! check_pkg discord
then
    wget -O- "https://discord.com/api/download?platform=linux&format=deb" > /tmp/discord.deb
	dpkg -i /tmp/discord.deb
    apt-get install -f -y
fi

## Ajout Vivaldi Browser
echo -e "\033[1;34m08- Installation de Vivaldi\033[0m"
if ! check_pkg vivaldi-stable
then
	wget -O- "https://repo.vivaldi.com/stable/linux_signing_key.pub" > /tmp/vivaldi_linux_signing_key.pub
	gpg --import /tmp/vivaldi_linux_signing_key.pub
	echo "deb [arch=amd64] https://repo.vivaldi.com/stable/deb/ stable main" | tee /etc/apt/sources.list.d/vivaldi.list
	apt update
	apt install -y vivaldi-stable
fi

## Ajout Tailscale
echo -e "\033[1;34m09- Installation de Tailscale\033[0m"
if ! check_pkg tailscale
then
	curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
	curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list
	apt update
	apt install -y tailscale
fi

## Ajout FastFetch
echo -e "\033[1;34m10- Installation de FastFetch\033[0m"
if ! check_pkg fastfetch
then
	curl -L https://github.com/fastfetch-cli/fastfetch/releases/download/2.8.9/fastfetch-linux-amd64.deb -o /tmp/fastfetch-linux-amd64.deb
	dpkg -i /tmp/fastfetch-linux-amd64.deb
	apt-get install -f -y
fi

# Ajout gThumb
echo -e "\033[1;34m10- Installation de gThumb\033[0m"
if ! check_pkg gThumb
then
	flatpak install flathub org.gnome.gThumb
fi
