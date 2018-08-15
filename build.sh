#!/usr/bin/env bash

# Update the .gitignore file
curl -s https://www.gitignore.io/api/osx,linux,windows,intellij > .gitignore
echo /.gtm/ >> .gitignore
echo /.idea/ >> .gitignore
