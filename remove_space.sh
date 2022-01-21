#!/bin/bash

## Author:Brycen Medart
## URL:https://treantlabs.com
## Version: 1.0
## License: MIT License

##
## Can run from terminal using below command. Will need to change location depending on where the remove_space.sh file is located
## /home/brymed/dev/projects/vid-convert-script/remove_space.sh "/home/brymed/Videos/tmp/paw.patrol/" "char-to-remove" "char-to-replace"
## ex.. /home/brymed/dev/projects/vid-convert-script/remove_space.sh "/home/brymed/Videos/tmp/paw.patrol/" " " "."
##

#VARIABLES
folder_path="$1"
old_char="$2"
new_char="$3"

##
## For all files in specified directory, rename file to remove spaces and replace with '.' character
##
for f in $folder_path/*; do 
echo "converting : $f to ${f//$old_char/$new_char}"
mv "$f" "${f//$old_char/$new_char}"; 

done


