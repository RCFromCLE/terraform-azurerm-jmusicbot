#!/bin/bash

# Define variables
USER_HOME=$(eval echo ~$SUDO_USER)
BOT_DIRECTORY="$USER_HOME/tf-jdiscord"
JDISCORD_GIT_REPO="https://github.com/RCFromCLE/tf-jdiscord.git"
JAR_NAME="JMusicBot-0.3.9.jar"
CONFIG_FILE_NAME="config.txt"
SERVICE_NAME="jdiscordbot"

# Ensure the script is run with elevated privileges
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Update and install Java
add-apt-repository -y ppa:openjdk-r/ppa
apt-get update
apt-get install -y openjdk-8-jdk

# Remove the existing bot directory if it exists, then recreate it
rm -rf $BOT_DIRECTORY || true
mkdir -p $BOT_DIRECTORY/jdiscordmusicbot

# Adjust ownership and permissions before cloning
chown $SUDO_USER:$SUDO_USER $BOT_DIRECTORY
chmod 755 $BOT_DIRECTORY

# Clone the Discord bot repository
sudo -u $SUDO_USER git clone $JDISCORD_GIT_REPO $BOT_DIRECTORY/jdiscordmusicbot

# Create config.txt within the jdiscordmusicbot directory using placeholder values
sudo -u $SUDO_USER bash -c "cat <<EOF > $BOT_DIRECTORY/jdiscordmusicbot/$CONFIG_FILE_NAME
# Your config content here
EOF"

# Adjust permissions of config.txt
chmod 644 $BOT_DIRECTORY/jdiscordmusicbot/$CONFIG_FILE_NAME

# Create a systemd service file for the Discord bot
cat <<EOF | sudo tee /etc/systemd/system/$SERVICE_NAME.service
[Unit]
Description=JDiscord Music Bot
After=network.target

[Service]
Type=simple
User=$SUDO_USER
WorkingDirectory=$BOT_DIRECTORY/jdiscordmusicbot
ExecStart=/usr/bin/java -jar $BOT_DIRECTORY/jdiscordmusicbot/$JAR_NAME
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to recognize the new service
systemctl daemon-reload

# Enable and start the Discord bot service
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME
