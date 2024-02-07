#!/bin/bash

setting_hostname_for_server () 
{
    # One-liner summary for the user
    echo "Please set the Hostname for the server"

    # Prompt the user for the desired hostname
    read -p "Enter a hostname: " new_hostname

    # Check if the hostname length is less than 15 characters
    if [ ${#new_hostname} -le 15 ]; then
        # Set the hostname
        hostnamectl set-hostname $new_hostname

        # Inform the user about the hostname change
        echo "Hostname has been set to: $new_hostname"
    else
        # Inform the user if the hostname is too long
        echo "Hostname is too long. Please choose a hostname with less than 15 characters."
    fi

    #checking hostname
    echo "Checking hostname : "
    hostname -f
}

install_dependencies ()
{
	# Updating the OS
	apt-get update && apt-get -y upgrade
	# Installing required packages
	apt-get install -y vim net-tools chrony gcc make git curl wget libnewt-dev libssl-dev libncurses5-dev subversion autoconf automake libtool libsqlite3-dev build-essential libjansson-dev libxml2-dev uuid-dev
}

setup_timezone ()
{
  timedatectl set-timezone Asia/Karachi
  # restart chronyd service
  systemctl restart chronyd
  # verify chronyd service status
  systemctl status chronyd
}

install_asterisk ()
{
	# Installing the asteric tarball package from the official website, Currently working with 20.6.0 LTS
	wget -P /usr/src https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-20.6.0.tar.gz
	# Extracting the package to /usr/src
	tar -zxvf /usr/src/asterisk-20.6.0.tar.gz -C /usr/src
	# Removing the tarball package
	rm -rf asterisk-20.6.0.tar.gz
}

making_asterisk ()
{
	# Install the MP3 source module
	bash /usr/src/asterisk-20.6.0/contrib/scripts/get_mp3_source.sh || { echo "Failed to install MP3 source module"; exit 1; }

	# Install the prerequisites
	bash /usr/src/asterisk-20.6.0/contrib/scripts/install_prereq install || { echo "Failed to install prerequisites"; exit 1; }

	# Configure Asterisk checking if we have the required dependencies
	cd /usr/src/asterisk-20.6.0/ || { echo "Failed to change directory"; exit 1; }
	./configure NOISY_BUILD=yes || { echo "Failed to configure Asterisk"; exit 1; }

	# Run Menuselect to select which modules to add
	make menuselect || { echo "Failed to run menuselect"; exit 1; }

	# Build Asterisk
	make || { echo "Failed to build Asterisk"; exit 1; }

	# Install Asterisk
	make install || { echo "Failed to install Asterisk"; exit 1; }

	# Generate sample configuration files
	make samples || { echo "Failed to generate sample configuration files"; exit 1; }

	# Run the Asterisk init script
	make config || { echo "Failed to run Asterisk init script"; exit 1; }

	# Update the shared libraries cache
	ldconfig || { echo "Failed to update shared libraries cache"; exit 1; }

	echo "Asterisk installation and configuration completed successfully"
}

post_installation ()
{
	# Adding the Asterisk user as right now Asterisk is running on root user
	adduser --system --group --home /var/lib/asterisk --no-create-home --gecos "Asterisk PBX" asterisk
	# Changing the asterisk user 
	sed -i 's/^#AST_USER="asterisk"/AST_USER="asterisk"/' /etc/default/asterisk
	# Changing the asterisk group
	sed -i 's/^#AST_GROUP="asterisk"/AST_GROUP="asterisk"/' /etc/default/asterisk
	# Adding the asterisk user in the dialout and audio group
	usermod -a -G dialout,audio asterisk
	# Changing the ownership recurresively for all the asterisk related folders
	chown -R asterisk: /var/{lib,log,run,spool}/asterisk /usr/lib/asterisk /etc/asterisk
	# Changing the permissions for all the asterisk related folders
	chmod -R 750 /var/{lib,log,run,spool}/asterisk /usr/lib/asterisk /etc/asterisk
	# Starting astersik
	systemctl start asterisk
	# Enable Asterisk so that it persists on reboot
	systemctl enable asterisk
	# Enable port 5060 as SIP uses this port
	ufw allow 5060/udp
}

main ()
{
  setting_hostname_for_server
  install_dependencies
  setup_timezone
  install_asterisk
  making_asterisk
  post_installation
}

main
bash
