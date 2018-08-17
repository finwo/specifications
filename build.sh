#!/usr/bin/env bash

echo "Updating gitignore"
curl -s https://www.gitignore.io/api/osx,linux,windows,intellij,composer > .gitignore
echo /.gtm/ >> .gitignore
echo /.idea/ >> .gitignore
echo composer.lock >> .gitignore

echo "Updating PHP dependencies"
composer install &>/dev/null

echo "(Re)building generated specs"
php compile.php spec=0000
