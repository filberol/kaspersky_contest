ssh-keygen -f "/home/filberol/.ssh/known_hosts" -R "192.168.56.10"
echo 'PubkeyAcceptedKeyTypes +ssh-rsa' | sudo tee -a /etc/ssh/ssh_config
ssh-keyscan -H "192.168.56.10" >> ~/.ssh/known_hosts