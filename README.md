# 🔍 Auto Recon - Bug Bounty Recon Script

Free automated recon script for bug bounty hunting on Kali Linux.
No API key needed!

## ✅ What It Does
- Finds subdomains
- Checks live hosts
- Scans open ports
- Collects URLs
- Runs Nuclei vulnerability scan

## ⚙️ Install Tools First
```bash
sudo apt install golang-go jq curl -y
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go install github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
go install github.com/lc/gau/v2/cmd/gau@latest
go install github.com/tomnomnom/waybackurls@latest
nuclei -update-templates
```

## 🚀 Run It
```bash
git clone https://github.com/Jabbarbaloch1/auto-recon.git
cd auto-recon
chmod +x auto_recon.sh
./auto_recon.sh example.com
```

## ⚠️ Legal
Only test targets you have permission to test.
Always check program scope on Bugcrowd/HackerOne first.

## 👤 Author
Jabbar Baloch  - Bug bounty hunter
