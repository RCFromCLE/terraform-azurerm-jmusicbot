ssh-keyscan ${public_ip_address} >> ~/.ssh/known_hosts
scp -r -i ~/.ssh/id_rsa jdiscordmusicbot rc@${public_ip_address}:~/
sudo apt-get update
sudo apt-get install -y openjdk-8-jdk
${var.run_jdb}
