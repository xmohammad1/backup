#!/bin/bash

# Bot token
while [[ -z "$tk" ]]; do
    echo "Bot token: "
    read -r tk
    if [[ $tk == $'\0' ]]; then
        echo "Invalid input. Token cannot be empty."
        unset tk
    fi
done

# Chat id
while [[ -z "$chatid" ]]; do
    echo "Chat id: "
    read -r chatid
    if [[ $chatid == $'\0' ]]; then
        echo "Invalid input. Chat id cannot be empty."
        unset chatid
    elif [[ ! $chatid =~ ^\-?[0-9]+$ ]]; then
        echo "${chatid} is not a number."
        unset chatid
    fi
done

# Caption
echo "Caption (for example, your domain, to identify the backup file more easily): "
read -r caption

# Cronjob
while true; do
    echo "Cronjob (minutes and hours) (e.g : 30 6 or 0 12) : "
    read -r minute hour
    if [[ $minute == 0 ]] && [[ $hour == 0 ]]; then
        cron_time="* * * * *"
        break
    elif [[ $minute == 0 ]] && [[ $hour =~ ^[0-9]+$ ]] && [[ $hour -lt 24 ]]; then
        cron_time="0 */${hour} * * *"
        break
    elif [[ $hour == 0 ]] && [[ $minute =~ ^[0-9]+$ ]] && [[ $minute -lt 60 ]]; then
        cron_time="*/${minute} * * * *"
        break
    elif [[ $minute =~ ^[0-9]+$ ]] && [[ $hour =~ ^[0-9]+$ ]] && [[ $hour -lt 24 ]] && [[ $minute -lt 60 ]]; then
        cron_time="*/${minute} */${hour} * * *"
        break
    else
        echo "Invalid input, please enter a valid cronjob format (minutes and hours, e.g: 0 6 or 30 12)"
    fi
done

while [[ -z "$crontabs" ]]; do
    echo "Would you like the previous crontabs to be cleared? [y/n] : "
    read -r crontabs
    if [[ $crontabs == $'\0' ]]; then
        echo "Invalid input. Please choose y or n."
        unset crontabs
    elif [[ ! $crontabs =~ ^[yn]$ ]]; then
        echo "${crontabs} is not a valid option. Please choose y or n."
        unset crontabs
    fi
done

if [[ "$crontabs" == "y" ]]; then
    sudo crontab -l | grep -vE '/root/opt-backup.*\\.sh' | crontab -
fi

if [[ ! -d "/opt" ]]; then
    echo "The /opt directory does not exist."
    exit 1
fi

trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

IP=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')
caption="${caption}\n\n/opt backup\n<code>${IP}</code>\nCreated by @AC_Lover - https://github.com/AC-Lover/backup"
comment=$(echo -e "$caption" | sed 's/<code>//g;s/<\/code>//g')
comment=$(trim "$comment")

sudo apt install zip -y

cat > "/root/opt-backup.sh" <<EOL
#!/bin/bash
set -euo pipefail
rm -f /root/opt-backup.zip
mapfile -t opt_dirs < <(find /opt -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
files_to_backup=()

for dir in "\${opt_dirs[@]}"; do
    if [[ -f "\${dir}/bot.db" ]]; then
        files_to_backup+=("\${dir}/bot.db")
    fi
    if [[ -f "\${dir}/vpn_bot/config.py" ]]; then
        files_to_backup+=("\${dir}/vpn_bot/config.py")
    fi
done

if [[ -f "/opt/bot.db" ]]; then
    files_to_backup+=("/opt/bot.db")
fi

if [[ -f "/opt/vpn_bot/config.py" ]]; then
    files_to_backup+=("/opt/vpn_bot/config.py")
fi

if [[ \${#files_to_backup[@]} -eq 0 ]]; then
    echo "No matching files found under /opt."
    exit 0
fi

zip /root/opt-backup.zip "\${files_to_backup[@]}"
echo -e "${comment}" | zip -z /root/opt-backup.zip
curl -F chat_id="${chatid}" -F caption=\$'${caption}' -F parse_mode="HTML" -F document=@"/root/opt-backup.zip" https://api.telegram.org/bot${tk}/sendDocument
EOL

chmod +x /root/opt-backup.sh

{ crontab -l -u root 2>/dev/null; echo "${cron_time} /bin/bash /root/opt-backup.sh >/dev/null 2>&1"; } | crontab -u root -

bash "/root/opt-backup.sh"

echo -e "\nDone\n"
