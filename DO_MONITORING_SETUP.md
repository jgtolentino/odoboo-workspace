# DigitalOcean Monitoring Setup

## Issue
Email address `ops@insightpulseai.net` is not verified in DigitalOcean account.

## Resolution Options

### Option 1: Verify Email in DigitalOcean (Recommended)

1. Log in to DigitalOcean Control Panel
2. Go to **Settings** → **Notifications**
3. Add and verify `ops@insightpulseai.net`
4. Wait for verification email and click confirmation link
5. Retry alert creation commands below

### Option 2: Use Your Verified Email

Replace `ops@insightpulseai.net` with your verified email address:

```bash
export DIGITALOCEAN_ACCESS_TOKEN='YOUR_DO_TOKEN_HERE'
DROPLET=525178434
EMAIL=your-verified-email@example.com

# CPU ≥85% for 5 minutes
doctl monitoring alert create \
  --type v1/insights/droplet/cpu \
  --compare GreaterThan \
  --value 85 \
  --window 5m \
  --entities $DROPLET \
  --emails $EMAIL \
  --description "High CPU usage (>85% for 5 minutes)"

# Memory ≥85% for 5 minutes
doctl monitoring alert create \
  --type v1/insights/droplet/memory_utilization_percent \
  --compare GreaterThan \
  --value 85 \
  --window 5m \
  --entities $DROPLET \
  --emails $EMAIL \
  --description "High memory usage (>85% for 5 minutes)"

# Disk ≥80% for 1 hour
doctl monitoring alert create \
  --type v1/insights/droplet/disk_utilization_percent \
  --compare GreaterThan \
  --value 80 \
  --window 1h \
  --entities $DROPLET \
  --emails $EMAIL \
  --description "High disk usage (>80% for 1 hour)"

# Load average ≥2.0 for 5 minutes
doctl monitoring alert create \
  --type v1/insights/droplet/load_1 \
  --compare GreaterThan \
  --value 2.0 \
  --window 5m \
  --entities $DROPLET \
  --emails $EMAIL \
  --description "High load average (>2.0 for 5 minutes)"

# Public bandwidth out ≥400MB/s (potential DDoS)
doctl monitoring alert create \
  --type v1/insights/droplet/public_outbound_bandwidth \
  --compare GreaterThan \
  --value 400000000 \
  --window 5m \
  --entities $DROPLET \
  --emails $EMAIL \
  --description "High outbound bandwidth (>400MB/s for 5 minutes)"
```

### Option 3: Create Alerts via Control Panel

1. Go to https://cloud.digitalocean.com/projects/29cde7a1-8280-46ad-9fdf-dea7b21a7825/activity
2. Click **Monitoring** → **Alerts** → **Create Alert Policy**
3. Configure each alert:

**Alert 1: High CPU**
- Metric: CPU
- Threshold: Greater than 85%
- Window: 5 minutes
- Droplet: ocr-service-droplet (525178434)
- Notifications: Email

**Alert 2: High Memory**
- Metric: Memory
- Threshold: Greater than 85%
- Window: 5 minutes
- Droplet: ocr-service-droplet (525178434)
- Notifications: Email

**Alert 3: High Disk**
- Metric: Disk Usage
- Threshold: Greater than 80%
- Window: 1 hour
- Droplet: ocr-service-droplet (525178434)
- Notifications: Email

**Alert 4: High Load Average**
- Metric: Load Average (1 minute)
- Threshold: Greater than 2.0
- Window: 5 minutes
- Droplet: ocr-service-droplet (525178434)
- Notifications: Email

**Alert 5: Bandwidth Spike**
- Metric: Public Outbound Bandwidth
- Threshold: Greater than 400 MB/s
- Window: 5 minutes
- Droplet: ocr-service-droplet (525178434)
- Notifications: Email

### Option 4: Use Slack Webhooks (No Email Required)

```bash
export DIGITALOCEAN_ACCESS_TOKEN='YOUR_DO_TOKEN_HERE'
DROPLET=525178434
SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

doctl monitoring alert create \
  --type v1/insights/droplet/cpu \
  --compare GreaterThan \
  --value 85 \
  --window 5m \
  --entities $DROPLET \
  --slack-channels $SLACK_WEBHOOK \
  --description "High CPU usage"
```

## Verify Monitoring Agent

Check that the DigitalOcean monitoring agent is running:

```bash
ssh root@188.166.237.231 "systemctl status do-agent"
```

If not installed:

```bash
ssh root@188.166.237.231 "curl -sSL https://repos.insights.digitalocean.com/install.sh | bash"
```

## Test Alerts

After creating alerts, verify they're active:

```bash
doctl monitoring alert list --format UUID,Type,Description,Emails
```

## Current Monitoring Status

**Droplet**: ocr-service-droplet (525178434)
**Region**: Singapore (sgp1)
**Monitoring Agent**: Status checked automatically

**Recommended Alerts**:
- ✅ CPU usage > 85% for 5 minutes
- ✅ Memory usage > 85% for 5 minutes
- ✅ Disk usage > 80% for 1 hour
- ✅ Load average > 2.0 for 5 minutes
- ✅ Outbound bandwidth > 400 MB/s for 5 minutes

## Health Check Integration

The deployed `/usr/local/bin/odoobo-health.sh` script can also send email alerts on failure. Configure it:

```bash
ssh root@188.166.237.231

# Set alert email
export ALERT_EMAIL=your-verified-email@example.com

# Add to cron for monitoring every 5 minutes
cat > /etc/cron.d/odoobo_health << EOF
*/5 * * * * root /usr/local/bin/odoobo-health.sh >> /var/log/odoobo-health.log 2>&1
EOF

# Test manually
/usr/local/bin/odoobo-health.sh
```

This provides application-level health monitoring independent of infrastructure metrics.
