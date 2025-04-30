#!/bin/bash

#################
### VARIABLES ###
#################
GNOMECOMPADD="gnome-extensions-app gnome-shell-extension-appindicator qgnomeplatform-qt5"
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
# Vérifie si un paquet Debian est installé
check_pkg() {
    rpm -q "$1" > /dev/null
}

add_pkg()
{
	dnf install -y "$1"
}

del_pkg()
{
	dnf remove -y "$1"
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

upgrade_dnf()
{
	dnf upgrade -y
}

update_flatpak()
{
	flatpak update --noninteractive
}

# Télécharge le paquet .deb depuis une URL et l'installe
add_deb_pkg() {
    wget -O /tmp/tmp.deb "$1"
    dpkg -i /tmp/tmp.deb
    apt install -f -y
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

	echo -e "01 - Mises à jour DNF : "
	upgrade_dnf
	check_cmd

	echo -e "02 - Mises à jour FLATPAK : "
	update_flatpak
	check_cmd

	exit;
fi

# Autres cas
## Update du système
echo -e "\033[1;34m00- - Update du système : \033[0m"
upgrade_dnf
check_cmd

## Activer flathub
echo -e "\033[1;34m01- - Activation du dépôt Flathub : \033[0m"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
check_cmd

## MAJ FLATPACK
echo -e "\033[1;34m02- - Mises à jour FLATPAK : \033[0m"
update_flatpak
check_cmd

## Installation de rpm fusion
echo -e "\033[1;34m03- - Installation de RPM Fusion : \033[0m"
dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
check_cmd

## Install/Suppr RPM selon liste
echo -e "\033[1;34m04- Gestion des paquets via RPM\033[0m"
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
done < "$ICI/rpm.list"

## Install/Suppr FLATPAK selon liste
echo -e "\033[1;34m07- Gestion des paquets via FLATPAK\033[0m"
while read -r line
do
	if [[ "$line" == add:* ]]
	then
		p=${line#add:}
		if ! check_flatpak "$p"
		then
			echo -n "- - - Installation paquet $p : "
			add_flatpak "$p"
			check_cmd
		fi
	fi
	
	if [[ "$line" == del:* ]]
	then
		p=${line#del:}
		if check_flatpak "$p"
		then
			echo -n "- - - Suppression paquet $p : "
			del_flatpak "$p"
			check_cmd
		fi
	fi
done < "$ICI/flatpak.list"

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

echo -e "Insaller manuellement l'extension Dash2Doc, ArcMenu et Blurmyshell"


## Ajout Twingate
echo -e "\033[1;34m10- Installation de Twingate\033[0m"
if ! check_pkg twingate
then
	dnf install -y 'dnf-command(config-manager)'
    dnf config-manager addrepo --set=baseurl="https://packages.twingate.com/rpm/"
    dnf config-manager setopt "packages.twingate.com_rpm_.gpgcheck=0"
    dnf install -y twingate  # or twingate-latest
    # After installation, configure the client by running: sudo twingate setup
fi