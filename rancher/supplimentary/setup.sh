#!/bin/bash
# Stuff to get a master/node set up.

function master1
{
    prep
    installDocker

    docker run -d --restart=unless-stopped -p 8080:8080 rancher/server:stable
    
    echo -n "Waiting for rancher to come up"
    while ! curl localhost:8080; do
        echo -n "."
    done
    echo " YAY!"
    
    curl localhost:8080/v1/registrationTokens | sed 's/^.*"command":"sudo //g' | cut -d\" -f1 | sed 's/\\//g' > /vagrant/registrationCommand.secret
}

function node
{
    prep
    installDocker
    
    bash -c "`cat /vagrant/registrationCommand.secret`"
}

function client
{
    prep
    installDocker

    
}

function installDocker
{
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update
    apt-get install -y docker-ce wget
}

function preCache
{
    prep "supplimentary/cache"
    get "$serverURL"
    get "$nodeURL"
    get "$clientURL"
}

function get
{
    url="$1"
    fileName=`basename "$url"`
    
    startDir=`pwd`
    cd "$downloadDir"
    if ! [ -e "$fileName" ]; then
        wget "$url"
    else
        echo "Skipping fetch of $fileName since it already exists."
    fi
    cd "$startDir"
}

function unpack
{
    url="$1"
    fileName=`basename "$url"`
    
    tar -xzf "$downloadDir/$fileName"
}

function prep
{
    if [ "$workingDir" == '' ]; then
        export workingDir="${1:-/tmp/setup}"
        mkdir -p "$workingDir"
        cd "$workingDir"
        echo "Prepped $workingDir."
    else
        echo "Already prepped $workingDir."
    fi
    
    if [ -e /vagrant ]; then
        downloadDir="/vagrant/supplimentary/cache"
    else
        downloadDir="$workingDir"
    fi
}

function showHelp
{
    grep '["]) #' $0 | cut -d\" -f 2- | sed 's/["]) # /	/g' | column -ts \	
}


case $1 in
    "master1") # Provision the first master node.
        master1
    ;;
    
    "node") # Provision a worker node.
        node
    ;;
    "client") # Provision a client.
        client
    ;;
    "precache") # Warm the cache so that stuff doesn't have to be downloaded on each server.
        preCache
    ;;
    *)
        showHelp
    ;;
esac

