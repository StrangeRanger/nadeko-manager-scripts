#!/bin/bash

read -p "We will now setup pm2. Press [Enter] to continue."

if [ "$OS" = "Ubuntu" ]; then
echo "This installer will download/update NodeJS/npm and install pm2."
echo ""
read -n 1 -s -p "Press any key to continue..."
	echo ""
	echo "Starting.."
	echo "Installing node/npm. Please wait.."
	curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
	sudo apt-get install -y nodejs
	sudo apt-get install -y build-essential
	sudo npm i -g npm
	echo "Installing pm2..."
	sudo npm install pm2 -g
fi
	
if [ "$OS" = "Debian" ]; then
echo "This installer will download/update NodeJS/npm and install pm2."
echo ""
read -n 1 -s -p "Press any key to continue..."
	echo ""
	echo "Starting.."
	echo "Installing node/npm. Please wait.."
	curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
	sudo apt-get install -y nodejs
	sudo apt-get install -y build-essential
	sudo npm i -g npm
	echo "Installing pm2..."
	sudo npm install pm2 -g
fi
	
if [ "$OS" = "LinuxMint" ]; then
echo "This installer will download/update NodeJS/npm and install pm2."
echo ""
read -n 1 -s -p "Press any key to continue..."
	echo ""
	echo "Starting.."
	echo "Installing node/npm. Please wait.."
	curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
	sudo apt-get install -y nodejs
	sudo apt-get install -y build-essential
	sudo npm i -g npm
	echo "Installing pm2..."
	sudo npm install pm2 -g
fi

if [ "$OS" = "CentOS" ]; then
echo "This installer will download/update NodeJS/npm and install pm2."
echo ""
read -n 1 -s -p "Press any key to continue..."
	echo ""
	echo "Starting.."
	echo "Installing node/npm. Please wait.."
	curl --silent --location https://rpm.nodesource.com/setup_14.x | sudo bash -
	sudo yum -y install nodejs
	sudo yum install gcc-c++ make
	sudo npm i -g npm
	echo "Installing pm2..."
	sudo npm install pm2 -g
fi


echo
echo "NadekoBot pm2 Installation completed..."
read -n 1 -s -p "Press any key to continue to the main menu..."
sleep 2

cd "$root"
rm "$root/nadekopm2setup.sh"
exit 0
