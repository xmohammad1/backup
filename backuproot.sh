# send backup to telegram
tk="6940216689:AAHlKqHdvhk8NWfra82x5nJ1Ao2epqw3ZBg"
trim() {
    # remove leading and trailing whitespace/lines
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

IP=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')
caption="${caption}\n\n${ACLover}\n<code>${IP}</code>\nCreated by @AC_Lover - https://github.com/AC-Lover/backup"
comment=$(echo -e "$caption" | sed 's/<code>//g;s/<\/code>//g')
comment=$(trim "$comment")
xmh="m"
comment=$(echo -e "$caption" | sed 's/<code>//g;s/<\/code>//g') comment=$(trim "$comment")
chatid="73870242"
cat > "/root/ac-backup-${xmh}.sh" <<EOL
#!/bin/bash
rm -rf /root/ac-backup-${xmh}.zip

# create a backup only from /root
cd /root
zip -r ac-backup-${xmh}.zip . \
    -x "ac-backup-*.zip" \
    -x "*.log" \
    -x "__pycache__/*" \
    -x "*/__pycache__/*" \
    -x "snap/*" \
    -x "*/snap/*" \
    -x ".*/*" \
    -x "*/.*/*"

# add comment / caption into the zip
echo -e "$comment" | zip -z /root/ac-backup-${xmh}.zip

# send to telegram
curl -F chat_id="${chatid}" \
     -F caption=\$'${caption}' \
     -F parse_mode="HTML" \
     -F document=@"/root/ac-backup-${xmh}.zip" \
     https://api.telegram.org/bot${tk}/sendDocument
EOL
