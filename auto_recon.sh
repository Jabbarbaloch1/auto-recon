#!/bin/bash
TARGET=$1
DATE=$(date +%Y-%m-%d_%H-%M)
OUTDIR=~/Desktop/recon/results/$TARGET/$DATE

if [ -z "$TARGET" ]; then
    echo "Usage: ./auto_recon.sh <domain>"
    exit 1
fi

mkdir -p $OUTDIR
echo ""
echo "=============================="
echo " Starting Recon on: $TARGET"
echo "=============================="
echo ""

# PHASE 1: Subdomains
echo "[1/5] Finding subdomains..."
subfinder -d $TARGET -silent -all -o $OUTDIR/subfinder.txt 2>/dev/null
curl -s --max-time 30 "https://crt.sh/?q=%25.$TARGET&output=json" \
  | jq -r '.[].name_value' 2>/dev/null \
  | sed 's/\*\.//g' | sort -u > $OUTDIR/crtsh.txt
cat $OUTDIR/subfinder.txt $OUTDIR/crtsh.txt | sort -u > $OUTDIR/all_subs.txt
echo "      Total subdomains: $(wc -l < $OUTDIR/all_subs.txt)"

# PHASE 2: Live Hosts
echo ""
echo "[2/5] Checking live hosts..."
touch $OUTDIR/live_hosts.txt
while read domain; do
    domain=$(echo $domain | tr -d '\r')
    [ -z "$domain" ] && continue
    for proto in https http; do
        code=$(curl -s -o /dev/null -w "%{http_code}" \
          --max-time 5 --connect-timeout 3 \
          -L "$proto://$domain" 2>/dev/null)
        if [ "$code" != "000" ] && [ ! -z "$code" ]; then
            title=$(curl -s --max-time 5 -L "$proto://$domain" 2>/dev/null \
              | grep -i "<title>" | head -1 \
              | sed 's/<[^>]*>//g' | tr -d '\n' | xargs)
            echo "$proto://$domain [$code] [$title]" >> $OUTDIR/live_hosts.txt
            break
        fi
    done
done < $OUTDIR/all_subs.txt
echo "      Live hosts: $(wc -l < $OUTDIR/live_hosts.txt)"
cat $OUTDIR/live_hosts.txt | awk '{print $1}' > $OUTDIR/live_urls.txt

# PHASE 3: Port Scan
echo ""
echo "[3/5] Scanning ports..."
touch $OUTDIR/ports.txt
while read domain; do
    domain=$(echo $domain | tr -d '\r')
    [ -z "$domain" ] && continue
    for port in 80 443 8080 8443 8888 3000 5000 9000; do
        result=$(curl -s -o /dev/null -w "%{http_code}" \
          --max-time 3 --connect-timeout 2 \
          "http://$domain:$port" 2>/dev/null)
        if [ "$result" != "000" ] && [ ! -z "$result" ]; then
            echo "$domain:$port" >> $OUTDIR/ports.txt
        fi
    done
done < $OUTDIR/all_subs.txt
echo "      Open ports: $(wc -l < $OUTDIR/ports.txt)"

# PHASE 4: URLs
echo ""
echo "[4/5] Collecting URLs..."
touch $OUTDIR/wayback.txt
touch $OUTDIR/gau.txt
cat $OUTDIR/live_urls.txt | waybackurls > $OUTDIR/wayback.txt 2>/dev/null
cat $OUTDIR/live_urls.txt | gau --threads 3 \
  --blacklist png,jpg,gif,css,woff,svg,ico \
  > $OUTDIR/gau.txt 2>/dev/null
cat $OUTDIR/wayback.txt $OUTDIR/gau.txt | sort -u > $OUTDIR/all_urls.txt
echo "      Total URLs: $(wc -l < $OUTDIR/all_urls.txt)"

# PHASE 5: Nuclei
echo ""
echo "[5/5] Running Nuclei..."
touch $OUTDIR/nuclei.txt
if [ -s $OUTDIR/live_urls.txt ]; then
    nuclei -list $OUTDIR/live_urls.txt \
      -t cves/ -t exposures/ -t misconfiguration/ \
      -severity medium,high,critical \
      -silent -o $OUTDIR/nuclei.txt 2>/dev/null
fi
echo "      Findings: $(wc -l < $OUTDIR/nuclei.txt)"

# RESULTS
echo ""
echo "=============================="
echo " RECON COMPLETE: $TARGET"
echo "=============================="
echo ""
echo "--- Files saved ---"
ls -lh $OUTDIR/
echo ""
echo "--- Live hosts ---"
cat $OUTDIR/live_hosts.txt
echo ""
echo "--- Interesting endpoints ---"
grep -i "admin\|login\|api\|dev\|staging\|test\|dashboard\|panel\|beta\|jenkins\|internal\|graphite\|monitor\|control\|gitlab\|jira\|origin" \
  $OUTDIR/live_hosts.txt 2>/dev/null || echo "None found"
echo ""
echo "--- Nuclei findings ---"
cat $OUTDIR/nuclei.txt 2>/dev/null || echo "None found"
echo ""
echo "Paste output here in Claude for free analysis!"
