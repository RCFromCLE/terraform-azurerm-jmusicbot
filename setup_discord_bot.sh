#!/bin/bash

# Update and install Java
sudo add-apt-repository -y ppa:openjdk-r/ppa
sudo apt-get update
sudo apt-get install -y openjdk-8-jdk

# Prepare the jdiscord_musicbot directory
if [ -d "~/tf-jdiscord" ]; then
  rm -rf ~/tf-jdiscord
fi
mkdir -p ~/tf-jdiscord/jdiscord_musicbot
cd ~/tf-jdiscord/jdiscord_musicbot

# Clone the Discord bot repository
git clone https://github.com/RCFromCLE/tf-jdiscord.git ~/tf-jdiscord

# No need to manually create config.txt as it's assumed to be part of the repo

# Create a systemd service file for the Discord bot
cat <<EOF | sudo tee /etc/systemd/system/jdiscordbot.service
[Unit]
Description=JDiscord Music Bot
After=network.target

[Service]
User=rc
# Adjust the WorkingDirectory if necessary
WorkingDirectory=/home/rc/tf-jdiscord/jdiscord_musicbot
# Update the ExecStart path according to where the JAR file is located
ExecStart=/usr/bin/java -jar /home/rc/tf-jdiscord/jdiscord_musicbot/JMusicBot-0.3.9.jar
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the jdiscordbot service
sudo systemctl daemon-reload
sudo systemctl enable jdiscordbot
sudo systemctl start jdiscordbot
