# DNS Configuration for insightpulseai.net

Configure your DNS records to point to the Singapore droplet.

## Required DNS Records

### DigitalOcean Droplet IP

```
188.166.237.231
```

### DNS Records

| Type      | Name  | Value              | TTL  |
| --------- | ----- | ------------------ | ---- |
| **A**     | @     | 188.166.237.231    | 3600 |
| **A**     | www   | 188.166.237.231    | 3600 |
| **CNAME** | ocr   | insightpulseai.net | 3600 |
| **CNAME** | agent | insightpulseai.net | 3600 |

### Optional Records (Recommended)

| Type    | Name    | Value                                                   | TTL  | Purpose       |
| ------- | ------- | ------------------------------------------------------- | ---- | ------------- |
| **MX**  | @       | mail.insightpulseai.net                                 | 3600 | Email routing |
| **TXT** | @       | "v=spf1 mx ~all"                                        | 3600 | SPF record    |
| **TXT** | \_dmarc | "v=DMARC1; p=none; rua=mailto:admin@insightpulseai.net" | 3600 | DMARC policy  |

## Configuration by DNS Provider

### Cloudflare

1. **Login**: https://dash.cloudflare.com
2. **Select Domain**: insightpulseai.net
3. **DNS Settings**:

   ```
   Type: A
   Name: @
   IPv4: 188.166.237.231
   Proxy: OFF (DNS only)
   TTL: Auto

   Type: A
   Name: www
   IPv4: 188.166.237.231
   Proxy: OFF (DNS only)
   TTL: Auto
   ```

4. **SSL/TLS Mode**: Full (not Full Strict yet)
5. **Wait**: 5-10 minutes for propagation

### DigitalOcean Domains

1. **Login**: https://cloud.digitalocean.com
2. **Networking** → **Domains** → **Add Domain**
3. **Domain Name**: insightpulseai.net
4. **Add Records**:

   ```bash
   # Via doctl CLI
   doctl compute domain records create insightpulseai.net \
     --record-type A \
     --record-name @ \
     --record-data 188.166.237.231 \
     --record-ttl 3600

   doctl compute domain records create insightpulseai.net \
     --record-type A \
     --record-name www \
     --record-data 188.166.237.231 \
     --record-ttl 3600
   ```

### GoDaddy

1. **Login**: https://dcc.godaddy.com
2. **My Products** → **DNS** → **Manage**
3. **Add Records**:

   ```
   Type: A
   Name: @
   Value: 188.166.237.231
   TTL: 1 Hour

   Type: A
   Name: www
   Value: 188.166.237.231
   TTL: 1 Hour
   ```

### Namecheap

1. **Login**: https://ap.www.namecheap.com
2. **Domain List** → **Manage** → **Advanced DNS**
3. **Add Records**:

   ```
   Type: A Record
   Host: @
   Value: 188.166.237.231
   TTL: Automatic

   Type: A Record
   Host: www
   Value: 188.166.237.231
   TTL: Automatic
   ```

## Verification

### Check DNS Propagation

```bash
# Check A record
dig +short insightpulseai.net
# Expected: 188.166.237.231

# Check www subdomain
dig +short www.insightpulseai.net
# Expected: 188.166.237.231

# Check from multiple locations
# https://www.whatsmydns.net/#A/insightpulseai.net
```

### Test DNS with nslookup

```bash
# macOS/Linux
nslookup insightpulseai.net
nslookup www.insightpulseai.net

# Windows
nslookup insightpulseai.net 8.8.8.8
```

### Online Tools

- **DNS Checker**: https://dnschecker.org/#A/insightpulseai.net
- **DNS Propagation**: https://www.whatsmydns.net/#A/insightpulseai.net
- **MX Toolbox**: https://mxtoolbox.com/SuperTool.aspx?action=a%3ainsightpulseai.net

## Propagation Time

- **Typical**: 5-30 minutes
- **Maximum**: 24-48 hours (rare)
- **Recommendation**: Wait 1 hour before SSL setup

## After DNS Configuration

Once DNS is configured and verified:

```bash
# Step 1: Deploy services
./scripts/deploy-agent-service.sh 188.166.237.231

# Step 2: Setup SSL/TLS
./scripts/setup-ssl.sh 188.166.237.231 admin@insightpulseai.net
```

## Endpoints After Setup

### Production URLs (HTTPS)

- **Main**: https://insightpulseai.net/
- **OCR Service**: https://insightpulseai.net/ocr/
- **Agent Service**: https://insightpulseai.net/agent/
- **Health Check**: https://insightpulseai.net/health

### Development URLs (HTTP - IP only)

- **Main**: http://188.166.237.231/
- **OCR Service**: http://188.166.237.231/ocr/
- **Agent Service**: http://188.166.237.231/agent/

## Troubleshooting

### DNS Not Resolving

```bash
# Clear local DNS cache (macOS)
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

# Clear local DNS cache (Windows)
ipconfig /flushdns

# Clear local DNS cache (Linux)
sudo systemd-resolve --flush-caches
```

### Wrong IP Returned

```bash
# Check TTL and wait for expiration
dig insightpulseai.net

# Force specific DNS server
dig @8.8.8.8 insightpulseai.net  # Google DNS
dig @1.1.1.1 insightpulseai.net  # Cloudflare DNS
```

### SSL Certificate Issues

```bash
# If Certbot fails, check DNS first
dig +short insightpulseai.net
# Must return: 188.166.237.231

# Check if port 80 is accessible
curl -v http://insightpulseai.net/.well-known/acme-challenge/test

# Manual certificate issuance
ssh root@188.166.237.231
certbot certonly --standalone -d insightpulseai.net -d www.insightpulseai.net
```

## Security Recommendations

### Cloudflare (If Using)

1. **Set SSL/TLS Mode**: Full (Strict) after SSL setup
2. **Enable HSTS**: Max Age: 12 months
3. **Enable Always Use HTTPS**: Force HTTPS redirect
4. **Minify**: CSS, JavaScript, HTML
5. **Brotli Compression**: Enable

### Firewall Rules

```bash
# SSH into droplet
ssh root@188.166.237.231

# Configure UFW
ufw allow 22/tcp   # SSH
ufw allow 80/tcp   # HTTP (for Let's Encrypt)
ufw allow 443/tcp  # HTTPS
ufw enable

# Verify
ufw status
```

### Rate Limiting (Already Configured)

- **OCR Service**: 10 requests/second (burst: 20)
- **Agent Service**: 30 requests/second (burst: 50)

## Monitoring

### SSL Certificate Expiration

```bash
# Check certificate expiration
ssh root@188.166.237.231 'certbot certificates'

# Test auto-renewal
ssh root@188.166.237.231 'certbot renew --dry-run'
```

### Uptime Monitoring

Setup external monitoring:

- **UptimeRobot**: https://uptimerobot.com
- **Pingdom**: https://www.pingdom.com
- **StatusCake**: https://www.statuscake.com

Monitor these endpoints:

- https://insightpulseai.net/health
- https://insightpulseai.net/ocr/health
- https://insightpulseai.net/agent/health
