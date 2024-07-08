#!/bin/bash

## Author:Brycen Medart
## URL:https://treantlabs.com
## Version: 1.0
## License: MIT License

##--------------
# Argument Variables - Do not change unless use case is understood
##--------------------

#File Category Parameter - ie (Adult Movie, Shows, etc..)
cat="$1"

#File Full Path Parameter
f_path="$2"

#Array of Movie ext types
ext_array=("srt" "avi" "flv" "mkv" "mov" "mp4" "wmv" "en.srt")

##-------------
#Global change variables - Change to configure for your environment.
##--------------------

#Enable file name rewrite to remove certain characters programmatically
sanitize_name=1

#Remove converted local file after transfer 0=no 1=yes
remove_file_after_transfer=0
remove_original_after_conversion=0
remove_parent_folder=0
remove_non_movie_files=1

#Video File Save Folder, alter to save converted movies to new location.
m_saveFolder="/home/brymed/tor"

#SSH Key file location/name
rsa_keyName=".ssh/id_rsa.pub"

#Remote Server Information For SFTP Transfer. Alter these values to match your environment.
enable_transfer=1
remote_ip="192.168.1.121"
remote_username="brymed88"
remote_saveFolder="/media/MediaFiles/plex/media/"

function print_msg() {
      type="$1"
      text="$2"
      printf "\n$type: $text\n"
}

function remove_file() {
      file="$1"
      file_ext="${file##*.}"
      print_msg "WARN" "REMOVING - "$(basename $file)" - $file_ext is not an allowed type"
      rm "$file"
}

function sanitize_names() {
      file="$1"
      parent="$(dirname "$file")"
      file_name="$(basename -- "$file")"

      s="${file_name//[^[:alnum:].]/-}" # replace all non-alnum characters to -
      shopt -s extglob
      s="${s//+("-")/-}" # convert multiple - to single -
      s="${s/#-/}"       # remove - from start
      s="${s/%-/}"       # remove - from end
      s="${s,,}"         # convert to lowercase

      #If not same name
      if [ "$s" != "$(basename -- "$file")" ]; then
            mv "$file" ""$parent"/"$s""

            #return modified location for file/folder
            echo "$parent/$s"
            exit -1
      fi

      # return non modified
      echo "$file"
}

function find_files() {

      for f in *; do

            entity="$f"

            if [ $sanitize_name -eq 1 ]; then
                  entity=$(sanitize_names "$f")
            fi

            if [[ -d $entity ]]; then

                  print_msg "INFO" "DIR FOUND - $(basename "$entity") - is a directory, traversing..."
                  (cd -- "$(realpath $entity)" && find_files)

            elif [[ -f $entity ]]; then

                  file_ext="${entity##*.}"

                  # Search array for video ext
                  if [[ "${ext_array[*]}" =~ "${file_ext}" ]]; then
                        convert "$(realpath "$entity")"
                  else
                        #If remove_non_movie_files
                        if [ $remove_non_movie_files -eq 1 ]; then
                              remove_file "$(realpath "$entity")"
                        fi
                  fi

            else
                  print_msg "ERROR" "$(realpath $entity) - is not valid..."
            fi

      done

}

function transfer_file() {

      #Assign Argument to variable
      i=$1
      print_msg "INFO" "TRANSFERRING - "$(basename "$i")""
      scp -i ~/$rsa_keyName "$i" $remote_username@$remote_ip:/$remote_saveFolder/$cat || exit -1

      print_msg "INFO" "TRANSFER COMPLETE - "$(basename "$i")""
      #Remove file after transfer if $remove_file is set
      sleep 1

      if [ $remove_file_after_transfer -eq 1 ]; then

            rm "$(realpath "$i")"
            print_msg "INFO" "REMOVING - file "$(basename "$i")""
      fi
}

function convert() {
      file_path=$1

      file="$(basename "$file_path")"
      file_ext="${file##*.}"
      file_name="${file%.*}"
      file_parent="$(dirname "$file_path")"
      file_loc="$file_path"

      if [ $file_ext == "srt" ]; then

            if [ "$file_ext" != "en.srt" ] && [[ "$file_name" != *".en"* ]]; then
                  print_msg "INFO" "CONVERTING - $file"

                  mv "$file_path" ""$file_parent"/"$file_name".en.srt"
                  file_loc=""$file_parent"/"$file_name".en.srt"
            fi

      else
            #Assign Video/Audio codecs to variables
            codecV=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nokey=1:noprint_wrappers=1 "$file_path")
            codecA=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=nokey=1:noprint_wrappers=1 "$file_path")

            print_msg "INFO" "BEGIN CONVERSION - $file"

            #logic here
            ffmpeg -v quiet -stats -i "$file_path" -c:v libx264 -preset fast -crf 24 -c:a copy "tmp_$file_name.mp4"

            #Sleep until movie is processed !important
            while pidof /usr/bin/ffmpeg; do sleep 10; done >/dev/null

            chmod 777 "tmp_$file_name.mp4"

            if [ $remove_original_after_conversion -eq 1 ]; then
                  rm "$file_path"
            else
                  mv "$file_path" "old.$file_name.$file_ext"
            fi

            #rename back to original
            mv ""$file_parent"/tmp_$file_name.mp4" "$file_name.mp4"

            file_loc=""$file_parent"/$file_name.mp4"

            print_msg "INFO" "CONVERSION COMPLETE - "$file""

      fi

      #If transfer is enabled then transfer file
      if [ $enable_transfer -eq 1 ]; then
            transfer_file "$file_loc"
      fi
}

# #CD into directory to avoid unwanted actions

(
      printf "\n--------\nAuthor: Brycen Medart\nLicense: MIT\nLink: https://github.com/brymed88\n--------\n\n"

      #initial file/folder location
      item="$f_path"

      if [ $sanitize_name -eq 1 ]; then
            item=$(sanitize_names "$f_path")
      fi

      cd "$item"
      find_files

      if [ $remove_parent_folder -eq 1 ]; then
            rm -d "$item" || print_msg "ERROR" ""$item" not empty, skipping removal"
      fi
)

read -n 1 -r -s -p $'\nProcess complete,\nPress enter to continue...\n'
