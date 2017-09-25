#!/bin/bash
echo "Starting get-bad-actors script"

TEMP_DIR="./temp/"
sudo rm -rf $TEMP_DIR/
mkdir $TEMP_DIR/

echo "Copying NGINX logs"

sudo cp -r /var/log/nginx/ $TEMP_DIR/logs/

WHOAMI="$(whoami)"

echo "Changing ownership of files from 'root' to '$WHOAMI'"
sudo chown -R $WHOAMI $TEMP_DIR/logs/

echo "Unzipping log files..."
gunzip $TEMP_DIR/logs/*.gz

echo "Listing log files..."
ls -l $TEMP_DIR/logs/

echo "Finding all direct IP requests"
cat $TEMP_DIR/logs/access.log* | awk '($7 ~ /52.91.52.1:80\//)' | awk '{print $7}' | sort | uniq -c | sort -rn > ./temp/bad-requests.source.txt

BAD_REQUESTS_SOURCE_LINES="$(wc -l $TEMP_DIR/bad-requests.source.txt | awk '{print $1}')"

echo "$BAD_REQUESTS_SOURCE_LINES direct IP requests found"
cat temp/bad-requests.source.txt | awk '{print $2}' | sed 's|.*://[^/]*/\([^?]*\)|/\1|g' > temp/bad-paths.txt

cat $TEMP_DIR/logs/access.log* | grep -f ./temp/bad-paths.txt > ./temp/bad-requests.full.txt 

cat $TEMP_DIR/bad-requests.full.txt | sed -e 's/\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\).*$/\1/' -e t -e d | sort | uniq -c > ./temp/bad-requests.txt

BAD_REQUESTS_ACTUAL="$(cat $TEMP_DIR/bad-requests.txt | awk '{ sum += $1 } END { print sum }')"

echo "$BAD_REQUESTS_ACTUAL bad requests found in logs"
cat $TEMP_DIR/bad-requests.txt | awk '{print $2}' > ./temp/bad-ips.txt

BAD_IPS_COUNT="$(wc -l $TEMP_DIR/bad-ips.txt | awk '{print $1}')"

echo "$BAD_IPS_COUNT bad ips logged"
