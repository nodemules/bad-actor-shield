#!/bin/bash

echo "Starting get-bad-actors script"

DIR_SRC=$(dirname $(realpath $0))
DIR_ROOT=$(dirname $DIR_SRC)
DIR_OUT="$DIR_ROOT/out"
DIR_TEMP="$DIR_OUT/temp"

sudo rm -rf $DIR_TEMP/
mkdir $DIR_OUT/
mkdir $DIR_TEMP/

echo "Copying NGINX logs"

sudo cp -r /var/log/nginx/ $DIR_TEMP/logs/

WHOAMI="$(whoami)"

echo "Changing ownership of files from 'root' to '$WHOAMI'"
sudo chown -R $WHOAMI $DIR_TEMP/logs/

echo "Unzipping log files..."
gunzip $DIR_TEMP/logs/*.gz

NUM_OF_LOGS=$(find $DIR_TEMP/logs/*.log* | wc -l)
echo "$NUM_OF_LOGS log files found"

echo "Finding all direct IP requests"
cat $DIR_TEMP/logs/access.log* | awk '($7 ~ /52.91.52.1:80\//)' | awk '{print $7}' | sort | uniq -c | sort -rn > $DIR_TEMP/bad-requests.source.txt

BAD_REQUESTS_SOURCE_LINES="$(wc -l $DIR_TEMP/bad-requests.source.txt | awk '{print $1}')"

echo "$BAD_REQUESTS_SOURCE_LINES direct IP requests found"
cat $DIR_TEMP/bad-requests.source.txt | awk '{print $2}' | sed 's|.*://[^/]*/\([^?]*\)|/\1|g' > $DIR_TEMP/bad-paths.txt

NEW_BAD_PATHS_COUNT=$(wc -l $DIR_TEMP/bad-paths.txt | awk '{print $1}')

echo "$NEW_BAD_PATHS_COUNT new bad paths found"

cat $DIR_TEMP/logs/access.log* | grep -f $DIR_TEMP/bad-paths.txt > $DIR_TEMP/bad-requests.full.txt 

cat $DIR_TEMP/bad-requests.full.txt | sed -e 's/\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\).*$/\1/' -e t -e d | sort | uniq -c > $DIR_TEMP/bad-requests.txt

BAD_REQUESTS_ACTUAL="$(cat $DIR_TEMP/bad-requests.txt | awk '{ sum += $1 } END { print sum }')"

echo "$BAD_REQUESTS_ACTUAL bad requests found in logs"
cat $DIR_TEMP/bad-requests.txt | awk '{print $2}' > $DIR_TEMP/bad-ips.txt

NEW_BAD_IPS_COUNT="$(wc -l $DIR_TEMP/bad-ips.txt | awk '{print $1}')"

echo "$NEW_BAD_IPS_COUNT bad ips logged"

OLD_BAD_PATHS_COUNT=$(wc -l $DIR_OUT/bad-paths.txt | awk '{print $1}')

cat $DIR_TEMP/bad-paths.txt $DIR_OUT/bad-paths.txt | sort | uniq > $DIR_OUT/bad-paths.txt

BAD_PATHS_COUNT=$(wc -l $DIR_OUT/bad-paths.txt | awk '{print $1}')

echo -e "$((BAD_PATHS_COUNT - OLD_BAD_PATHS_COUNT)) new unique bad paths have been added to '$DIR_OUT/bad-paths.txt',\n there are now $BAD_PATHS_COUNT documented bad paths"

OLD_BAD_IPS_COUNT=$(wc -l $DIR_OUT/bad-ips.txt | awk '{print $1}')

cat $DIR_TEMP/bad-ips.txt $DIR_OUT/bad-ips.txt | sort | uniq > $DIR_OUT/bad-ips.txt

BAD_IPS_COUNT=$(wc -l $DIR_OUT/bad-ips.txt | awk '{print $1}')

echo -e "$((BAD_IPS_COUNT - OLD_BAD_IPS_COUNT)) new unique bad IPs have been added to '$DIR_OUT/bad-ips.txt',\n there are now $BAD_IPS_COUNT documented bad IPs"

echo "Cleaning up files..."

rm -rf $DIR_TEMP/

echo "BadActorShield is done!"
