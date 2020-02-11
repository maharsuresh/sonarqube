#!/bin/sh
#Source environment
#source ~/.bashrc
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi
export SONAR_VERSION="4.1.0.1829"

echo "inside the sonar-analysis..."
#Download the sonar scanner binaries
if [ ! -f sonarscanner.zip ]; then
    curl -H "Accept: application/zip" https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-$SONAR_VERSION.zip -o sonarscanner.zip
    unzip sonarscanner.zip
fi

SONAR_HOME=`find "$PWD" -type d -name 'sonar-scanner*'`
if [[ ! "$SONAR_HOME" =~ sonar-scanner ]]; then
    echo "Failed to setup sonar binaries"
    exit
else
    echo "SONAR_HOME: $SONAR_HOME"
fi

#Change to use absolute paths
export PATH=$PATH:$SONAR_HOME/bin

# assuming below structure
# $project-root/sonar-analysis, navigating to project root
cd ../

echo "Running sonar-scanner from: $PWD"

