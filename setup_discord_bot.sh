#!/bin/bash

# Update and install Java
sudo add-apt-repository -y ppa:openjdk-r/ppa
sudo apt-get update
sudo apt-get install -y openjdk-8-jdk

# Prepare the jdiscordmusicbot directory
if [ -d "/home/rc/tf-jdiscord" ]; then
  sudo rm -rf /home/rc/tf-jdiscord
fi
sudo mkdir -p /home/rc/tf-jdiscord/jdiscordmusicbot
cd /home/rc/tf-jdiscord/jdiscordmusicbot

# Clone the Discord bot repository
git clone https://github.com/RCFromCLE/tf-jdiscord.git /home/rc/tf-jdiscord

# Assuming config.txt is part of the repo, no action needed

# Create the start_jdiscordbot.sh script
cat <<EOF | sudo tee /home/rc/tf-jdiscord/start_jdiscordbot.sh
#!/bin/bash

cd /home/rc/tf-jdiscord/jdiscordmusicbot
git pull
/usr/bin/java -jar JMusicBot-0.3.9.jar
EOF

# Make the script executable
sudo chmod +x /home/rc/tf-jdiscord/start_jdiscordbot.sh

# Create a systemd service file for the Discord bot
cat <<EOF | sudo tee /etc/systemd/system/jdiscordbot.service
[Unit]
Description=JDiscord Music Bot
After=network.target

[Service]
Type=simple
User=rc
WorkingDirectory=/home/rc/tf-jdiscord/jdiscordmusicbot
ExecStart=/home/rc/tf-jdiscord/start_jdiscordbot.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the jdiscordbot service
sudo systemctl daemon-reload
sudo systemctl enable jdiscordbot
sudo systemctl start jdiscordbot
