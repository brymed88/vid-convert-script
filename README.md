# vid-convert-script

Intro:

This is a linux bash script that will convert multiple video file formats to mp4 and h264 codec. I developed this script to automatically convert video files and upload them to a raspberryPI server that is running Plex Media Server software. The reason for conversion is that the raspberryPi, while powerful lacks the processing power to transcode movies on the fly. By converting to the h264 format there is no need to transcode the video when watching movies on most modern day smart TV's.

----------------------------------------------------------------------------------------------------------------

Prerequisites:

Set the global variables notated in the convert.sh file. These variables will tell the script where your saved movies files should be located and whether or not you want to utilize an SFTP transfer after conversion.

Note: If using SFTP transfer an ssh key needs to be created. A decent article on how to accomplish this can be found on Tech Republic - https://www.techrepublic.com/article/how-to-use-secure-copy-with-ssh-key-authentication/. Once created the script needs to be updated to point to your local ssh file and the SFTP variables for IP, Username need to be set. Lastly alter the variable "enable_transfer" from 0 to 1 to enable SFTP within the script.

-----------------------------------------------------------------------------------------------------------------

TERMINAL USAGE:

This script can easily be ran from the terminal window by entering the below command.

Note: In the below example "/home/Dev/vid-convert-script/convert.sh" is the location of this script on my file system. Depending on the location you select to clone the script this will need to be adjusted.

Change the below values

* Torrent label - Torrent label ie shows, movies etc..
    Note: Label that is used in the FTP transfer file path. For example if label is "Shows" the ftp transfer would save to /remoteip/folder/Shows. If videos are not categorized this way on your system leave quotes empty ""
* Full save path - full save path for video file ie "/home/user/Downloads/mountain men". If the video is not under a subfolder, this value would be "/home/user/Downloads/mountain men.avi"

bash /home/Dev/vid-convert-script/convert.sh "Shows" "/home/user/Downloads/mountain men"

----------------------------------------------------------------------------------------------------------------

qBITTORRENT USAGE:

%L - Torrent Label
%R - Full Save Path - includes folder torrent is in

Within qBittorrent Under Settings->Downloads-> Run External Program On Torrent Completion, paste the below snippet

Note: In the below example "/home/Dev/vid-convert-script/convert.sh" is the location of this script on my file system. Depending on the git clone location, this will need to be adjusted.

/home/Dev/vid-convert-script/convert.sh "%D" "%L" "%R"

OR

gnome-terminal -- /home/Dev/vid-convert-script/convert.sh "%L" "%R"

If seeing the output is desired.

After torrent finishes downloading qBittorrent will kick off the convert.sh script and process the video conversion.

----------------------------------------------------------------------------------------------------------------

Summary:

Thank you for checking out my project and feel free to submit comments/improvement ideas!