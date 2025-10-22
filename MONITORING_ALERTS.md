# DigitalOcean Monitoring Alerts - Active Configuration

**Droplet**: ocr-service-droplet (525178434)
**Alert Email**: jgtolentino_rn@yahoo.com
**Status**: ✅ **ALL ALERTS ACTIVE**

---

## 📊 Configured Alerts (5 Total)

### 1. High CPU Usage
- **UUID**: 94be2cff-c6df-4cb6-8c8a-05dfbc7723b9
- **Metric**: CPU utilization percentage
- **Threshold**: > 85%
- **Window**: 5 minutes
- **Action**: Email alert to jgtolentino_rn@yahoo.com
- **Status**: ✅ Enabled

**What triggers this**: CPU usage sustained above 85% for 5 consecutive minutes

### 2. High Memory Usage
- **UUID**: e3cddbab-a5f9-4927-8ae0-40c8fe0ab221
- **Metric**: Memory utilization percentage
- **Threshold**: > 85%
- **Window**: 5 minutes
- **Action**: Email alert to jgtolentino_rn@yahoo.com
- **Status**: ✅ Enabled

**What triggers this**: Memory usage sustained above 85% for 5 consecutive minutes

### 3. High Disk Usage
- **UUID**: 0bb44945-776d-42df-aeb6-d83461d8aec7
- **Metric**: Disk utilization percentage
- **Threshold**: > 80%
- **Window**: 1 hour
- **Action**: Email alert to jgtolentino_rn@yahoo.com
- **Status**: ✅ Enabled

**What triggers this**: Disk usage sustained above 80% for 1 hour

### 4. High Load Average
- **UUID**: 8a3769db-a4ac-49c9-af70-c221fa95ec42
- **Metric**: System load average (1 minute)
- **Threshold**: > 2.0
- **Window**: 5 minutes
- **Action**: Email alert to jgtolentino_rn@yahoo.com
- **Status**: ✅ Enabled

**What triggers this**: Load average above 2.0 for 5 consecutive minutes

### 5. High Outbound Bandwidth
- **UUID**: 8c3a9d01-1ac6-43db-ae55-e601efc34cdc
- **Metric**: Public outbound bandwidth
- **Threshold**: > 400 MB/s
- **Window**: 5 minutes
- **Action**: Email alert to jgtolentino_rn@yahoo.com
- **Status**: ✅ Enabled

**What triggers this**: Outbound network traffic exceeds 400 MB/s for 5 consecutive minutes (potential DDoS or data exfiltration)

---

## 📧 Alert Management

### View All Alerts
```bash
export DIGITALOCEAN_ACCESS_TOKEN='YOUR_TOKEN'
doctl monitoring alert list --format UUID,Type,Description,Emails,Enabled
```

### Delete an Alert
```bash
doctl monitoring alert delete <UUID>

# Example: Delete CPU alert
doctl monitoring alert delete 94be2cff-c6df-4cb6-8c8a-05dfbc7723b9
```

### Update an Alert (Delete + Recreate)
```bash
# Delete old alert
doctl monitoring alert delete <OLD_UUID>

# Create new alert with updated parameters
doctl monitoring alert create \
  --type v1/insights/droplet/cpu \
  --compare GreaterThan \
  --value 90 \
  --window 10m \
  --entities 525178434 \
  --emails jgtolentino_rn@yahoo.com \
  --description "High CPU usage (>90% for 10 minutes)"
```

### Disable an Alert Temporarily
**Note**: doctl doesn't support disabling alerts via CLI. Use DigitalOcean Control Panel:
1. Go to https://cloud.digitalocean.com/monitoring/alerts
2. Click the alert to edit
3. Toggle "Enabled" to off

---

## 🔍 Monitoring Agent Status

### Check Agent Health
```bash
ssh root@188.166.237.231 "systemctl status do-agent"
```

**Expected Output**:
```
● do-agent.service - The DigitalOcean Monitoring Agent
   Active: active (running)
   Version: 3.18.5
```

### View Agent Logs
```bash
ssh root@188.166.237.231 "journalctl -u do-agent -n 50 --no-pager"
```

### Restart Agent (if needed)
```bash
ssh root@188.166.237.231 "systemctl restart do-agent"
```

---

## 📈 Metrics Dashboard

View real-time metrics in DigitalOcean Control Panel:
- **URL**: https://cloud.digitalocean.com/droplets/525178434/graphs
- **Available Metrics**:
  - CPU usage (%)
  - Memory usage (%)
  - Disk I/O (read/write)
  - Disk usage (%)
  - Network bandwidth (inbound/outbound)
  - Load average (1, 5, 15 min)

---

## 🚨 Alert Response Procedures

### CPU Alert (>85%)
**Investigate**:
```bash
ssh root@188.166.237.231 "top -bn1 | head -20"
ssh root@188.166.237.231 "docker stats --no-stream"
```

**Common Causes**:
- Odoo worker overload (increase workers or resources)
- Database query bottleneck (check slow queries)
- Backup running (expected during nightly 2 AM backup)

**Resolution**:
- Scale up droplet size if sustained
- Optimize database queries
- Adjust Odoo worker configuration

### Memory Alert (>85%)
**Investigate**:
```bash
ssh root@188.166.237.231 "free -h"
ssh root@188.166.237.231 "docker stats --no-stream"
```

**Common Causes**:
- Odoo memory leak (restart service)
- Too many workers for available memory
- PostgreSQL cache settings too high

**Resolution**:
- Restart Odoo: `docker compose restart odoo`
- Reduce workers in odoo.conf
- Scale up droplet memory

### Disk Alert (>80%)
**Investigate**:
```bash
ssh root@188.166.237.231 "df -h"
ssh root@188.166.237.231 "du -sh /opt/odoobo/backup/*"
ssh root@188.166.237.231 "docker system df"
```

**Common Causes**:
- Backup accumulation (retention not working)
- Docker image/volume buildup
- Log file growth

**Resolution**:
- Clean old backups manually if needed
- Run: `docker system prune -a --volumes`
- Rotate logs: `journalctl --vacuum-time=7d`

### Load Alert (>2.0)
**Investigate**:
```bash
ssh root@188.166.237.231 "uptime"
ssh root@188.166.237.231 "w"
```

**Common Causes**:
- High CPU usage (see CPU alert)
- I/O wait (disk bottleneck)
- Many concurrent connections

**Resolution**:
- Check CPU and disk I/O
- Review active processes
- Consider scaling if sustained

### Bandwidth Alert (>400MB/s)
**Investigate**:
```bash
ssh root@188.166.237.231 "iftop -t -s 10"
ssh root@188.166.237.231 "docker logs --tail 100 odoobo-traefik-1"
```

**Common Causes**:
- DDoS attack
- File upload/download surge
- Backup sync to DO Spaces

**Resolution**:
- Check Traefik logs for suspicious traffic
- Review access logs for abnormal patterns
- Enable rate limiting (already configured)
- Contact DO support if under attack

---

## 🔔 Email Notifications

Alerts are sent to: **jgtolentino_rn@yahoo.com**

**Email Format**:
```
Subject: [DigitalOcean] Alert: High CPU usage (>85% for 5 minutes)

Your Droplet "ocr-service-droplet" (525178434) has triggered an alert:

Metric: CPU utilization
Current Value: 92%
Threshold: 85%
Window: 5 minutes

View metrics: https://cloud.digitalocean.com/droplets/525178434/graphs
```

**Email Management**:
- Add filters in Yahoo Mail to highlight/categorize DO alerts
- Set up forwarding to team Slack channel if needed
- Keep inbox clean to avoid missing critical alerts

---

## 📋 Alert Testing

### Trigger Test Alert (CPU)
```bash
# Generate CPU load for 6 minutes (exceeds 5-min window)
ssh root@188.166.237.231 "stress --cpu 2 --timeout 360s"

# Wait for alert email (usually arrives within 2-3 minutes after threshold exceeded)
```

**Note**: Only test during non-business hours to avoid false alarms.

---

## 🔄 Maintenance Schedule

### Weekly
- Review alert history in DO Control Panel
- Check for any missed or false-positive alerts

### Monthly
- Verify jgtolentino_rn@yahoo.com is still accessible
- Test one alert to ensure notifications working
- Review alert thresholds and adjust if needed

### Quarterly
- Review all 5 alerts for continued relevance
- Update alert descriptions if infrastructure changes
- Consider adding new alerts based on usage patterns

---

*Last Updated: October 23, 2025 04:40 UTC*
*Created by: Claude Code deployment automation*
