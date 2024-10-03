#!/bin/bash

echo "########################################################################"
echo "##                                                                    ## "
echo "##  ██╗██╗   ██╗███████╗████████╗██████╗ ███████╗███████╗███╗   ███╗  ## "
echo "##  ██║╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔══██╗██╔════╝██╔════╝████╗ ████║  ## "
echo "##  ██║ ╚████╔╝ ███████╗   ██║   ██████╔╝█████╗  █████╗  ██╔████╔██║  ## "
echo "##  ██║  ╚██╔╝  ╚════██║   ██║   ██╔══██╗██╔══╝  ██╔══╝  ██║╚██╔╝██║  ##"
echo "##  ██║   ██║   ███████║   ██║   ██║  ██║███████╗███████╗██║ ╚═╝ ██║  ## "
echo "##  ╚═╝   ╚═╝   ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝     ╚═╝  ## " 
echo "##                                                                    ## "
echo "######################################################################## "

echo "Updating system and installing rclone"
sudo apt update -y
sudo apt install rclone -y

echo "Starting rclone configuration for Google Drive"
rclone config create gdrive drive

echo "Please complete the Google Drive authentication process."

echo "Testing rclone connection to Google Drive"
rclone lsd gdrive:

if [ $? -ne 0 ]; then
    echo "Rclone configuration failed or not authenticated. Please run 'rclone config' manually to complete setup."
    exit 1
fi


read -p "Enter the full path to the folder you want to back up (e.g., /home/user/documents): " SOURCE_DIR

if [ ! -d "$SOURCE_DIR" ]; then
    echo "Directory does not exist. Exiting."
    exit 1
fi


while true; do
    read -p "Enter the backup interval in hours (e.g., 3 for every 3 hours): " BACKUP_INTERVAL
    if [[ $BACKUP_INTERVAL =~ ^[0-9]+$ ]] && [ $BACKUP_INTERVAL -gt 0 ]; then
        break
    else
        echo "Please enter a valid positive number."
    fi
done

BACKUP_SCRIPT="/usr/local/bin/skysync.sh"
echo "Creating SkySync script at $BACKUP_SCRIPT"

sudo tee $BACKUP_SCRIPT > /dev/null <<EOL
#!/bin/bash
# SkySync: Backup directory to Google Drive
SOURCE_DIR="$SOURCE_DIR"
DEST_DIR="gdrive:/backup-folder"

rclone sync \$SOURCE_DIR \$DEST_DIR --verbose
EOL

sudo chmod +x $BACKUP_SCRIPT

echo "Setting up SkySync cron job to run every $BACKUP_INTERVAL hours"

(crontab -l | grep -v 'skysync.sh') | crontab -

CRON_JOB="0 */$BACKUP_INTERVAL * * * $BACKUP_SCRIPT >> /var/log/skysync_backup.log 2>&1"
(crontab -l ; echo "$CRON_JOB") | crontab -

echo "SkySync setup complete! The folder $SOURCE_DIR will be backed up to Google Drive every $BACKUP_INTERVAL hours."

echo "You can monitor the backup process by checking the log file: /var/log/skysync_backup.log"