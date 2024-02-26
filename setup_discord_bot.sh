#!/bin/bash

# Update and install Java
sudo add-apt-repository -y ppa:openjdk-r/ppa
sudo apt-get update
sudo apt-get install -y openjdk-8-jdk


# Assuming config.txt is part of the repo, no action needed

# Create a systemd service file for the Discord bot
cat <<EOF | sudo tee /etc/systemd/system/jdiscordbot.service
[Unit]
Description=JDiscord Music Bot
After=network.target

[Service]
Type=simple
User=rc
# Ensure the WorkingDirectory points to where the bot actually resides
WorkingDirectory=/home/rc/tf-jdiscord/jdiscordmusicbot
# Ensure the ExecStart command points to the correct jar file location
ExecStart=/usr/bin/java -jar /home/rc/tf-jdiscord/jdiscordmusicbot/JMusicBot-0.3.9.jar
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the jdiscordbot service
sudo systemctl daemon-reload
sudo systemctl enable jdiscordbot
sudo systemctl start jdiscordbot
