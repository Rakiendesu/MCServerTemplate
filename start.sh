#!/bin/bash

set -e
root=$PWD
mkdir -p server
cd server

download() {
    read -p "Is your server Purpur, Paper or Magma (purpur/paper/magma): " SERVER
    read -p "Enter your server version: " VERSION
    read -p "Enter the build number: " BUILD
    echo By executing this script you agree to the JRE License, the PaperMC license,
    echo the Mojang Minecraft EULA,
    echo the NPM license, the MIT license,
    echo and the licenses of all packages used \in this project.
    echo Press Ctrl+C \if you \do not agree to any of these licenses.
    echo Press Enter to agree.
    read -s agree_text
    echo Thank you \for agreeing, the download will now begin.
    if [ "$SERVER" = "purpur" ]; then
        wget -O server.jar "https://api.purpurmc.org/v2/purpur/$VERSION/latest/download"
        echo "Purpur downloaded"
    elif [ "$SERVER" = "paper" ]; then
        wget -O server.jar "https://api.papermc.io/v2/projects/paper/versions/$VERSION/builds/$BUILD/downloads/paper-$VERSION-$BUILD.jar"
        echo "Paper downloaded"
    elif [ "$SERVER" = "magma" ]; then
        wget -O server.jar "https://api.magmafoundation.org/v2/projects/magma/versions/$VERSION/builds/$BUILD/downloads/magma-$VERSION-$BUILD.jar"
        echo "Magma downloaded"
    fi

    echo "eula=true" >eula.txt
    echo Agreed to Mojang EULA
    wget -O ngrok.zip https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip
    unzip ngrok.zip
    rm -rf ngrok.zip
    echo "Download complete"
}

require() {
    if [ ! $1 $2 ]; then
        echo $3
        echo "Running download..."
        download
    fi
}

requireFile() {
    require -f $1 "File $1 required but not found"
}

requireEnv() {
    var=$(python3 -c "import os;print(os.getenv('$1',''))")
    if [ -z "${var}" ]; then
        echo "Environment variable $1 not set. "
        echo "In your .env file, add a line with:"
        echo "$1="
        echo "and then right after the = add $2"
        exit
    fi
    eval "$1=$var"
}

requireExec() {
    requireFile "$1"
    chmod +x "$1"
}

requireFile "eula.txt"
requireFile "server.jar"
requireExec "ngrok"
requireEnv "ngrok_token" "your ngrok authtoken from https://dashboard.ngrok.com"
requireEnv "ngrok_region" "your region, one of:
us - United States (Ohio)
eu - Europe (Frankfurt)
ap - Asia/Pacific (Singapore)
au - Australia (Sydney)
sa - South America (Sao Paulo)
jp - Japan (Tokyo)
in - India (Mumbai)"

echo "Minecraft server starting, please wait" >$root/status.log
mkdir -p ./logs
touch ./logs/temp
rm ./logs/*
echo "Starting ngrok tunnel in region $ngrok_region"
./ngrok authtoken $ngrok_token
./ngrok tcp -region $ngrok_region --log=stdout 25565 >$root/status.log &
echo "Server Up!"
echo "Server is now running!" >$root/status.log
echo "Running server..."
java -Xms512M -Xmx512M -jar server.jar --nogui
