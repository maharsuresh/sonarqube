#!/bin/sh
#Source environment
#source ~/.bashrc
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi
export SONAR_VERSION="4.1.0.1829"

echo "inside the sonar-analysis..."
