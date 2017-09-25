#!/bin/bash
echo "Starting get-bad-actors script"
sudo rm -rf ./temp/
mkdir ./temp/
echo "Copying NGINX logs"
sudo cp -r /var/log/nginx/ ./temp/logs/
sudo chown -R production ./temp/logs/
echo "Unzipping log files..."
gunzip ./temp/logs/*.gz
echo "Listing log files..."
ls -l ./temp/logs/
echo "Finding all direct IP requests"
cat ./temp/logs/access.log* | awk '($7 ~ /52.91.52.1:80\//)' | awk '{print $7}' | sort | uniq -c | sort -rn > ./temp/bad-requests.source.txt
BAD_REQUESTS_SOURCE_LINES="$(wc -l ./temp/bad-requests.source.txt | awk '{print $1}')"
echo "$BAD_REQUESTS_SOURCE_LINES direct IP requests found"
cat temp/bad-requests.source.txt | awk '{print $2}' | sed 's|.*://[^/]*/\([^?]*\)|/\1|g' > temp/bad-paths.txt
cat ./temp/logs/access.log* | grep -f ./temp/bad-paths.txt > ./temp/bad-requests.full.txt 
cat ./temp/bad-requests.full.txt | sed -e 's/\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\).*$/\1/' -e t -e d | sort | uniq -c > ./temp/bad-requests.txt
BAD_REQUESTS_ACTUAL="$(cat ./temp/bad-requests.txt | awk '{ sum += $1 } END { print sum }')"
echo "$BAD_REQUESTS_ACTUAL bad requests found in logs"
cat ./temp/bad-requests.txt | awk '{print $2}' > ./temp/bad-ips.txt
BAD_IPS_COUNT="$(wc -l ./temp/bad-ips.txt | awk '{print $1}')"
echo "$BAD_IPS_COUNT bad ips logged"
