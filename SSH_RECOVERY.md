# SSH Recovery Instructions

## Issue
SSH connection refused on port 22 to 188.166.237.231

## Fix via DigitalOcean Recovery Console

### 1. Access Recovery Console
1. Log in to DigitalOcean Control Panel
2. Navigate to Droplets → ocr-service-droplet
3. Click "Access" → "Recovery Console"
4. Wait for console to connect

### 2. Restore SSH Service

```bash
# Ensure sshd is running and enabled
systemctl enable --now ssh
systemctl status ssh

# Check if sshd is listening
ss -tlnp | grep :22

# If not running, start it
systemctl start ssh
```

### 3. Fix Firewall Rules

```bash
# Allow SSH through UFW
ufw allow 22/tcp
ufw reload
ufw status verbose

# Verify rule exists
ufw status | grep 22
```

### 4. Check fail2ban (if installed)

```bash
# Check if fail2ban is installed and running
systemctl status fail2ban || echo "fail2ban not installed"

# If banned, unban your IP (replace with your actual IP)
fail2ban-client status sshd
fail2ban-client unban YOUR_IP_HERE

# Or disable jail temporarily
fail2ban-client stop sshd
```

### 5. Verify DigitalOcean Cloud Firewall

In DigitalOcean Control Panel:
1. Go to Networking → Firewalls
2. Check if any firewall is attached to this droplet
3. Ensure inbound rule allows TCP port 22 from your IP

### 6. Test SSH Connection

From your local machine:
```bash
ssh -v root@188.166.237.231
```

## Post-Recovery Hardening

Once SSH is restored, harden the configuration:

```bash
# Disable password authentication (key-only)
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

# Verify changes
grep -E '^(PasswordAuthentication|PermitRootLogin)' /etc/ssh/sshd_config

# Restart SSH
systemctl restart ssh

# Verify still works
ssh root@188.166.237.231 "echo 'SSH key-only auth working'"
```

## Deploy Pending Changes

After SSH is restored:

```bash
# 1. Deploy health check script
scp scripts/odoobo-health.sh root@188.166.237.231:/usr/local/bin/
ssh root@188.166.237.231 "chmod +x /usr/local/bin/odoobo-health.sh"

# 2. Deploy backup script
scp scripts/odoobo-backup.sh root@188.166.237.231:/usr/local/bin/
ssh root@188.166.237.231 "chmod +x /usr/local/bin/odoobo-backup.sh"

# 3. Test backup immediately
ssh root@188.166.237.231 "/usr/local/bin/odoobo-backup.sh"

# 4. Update cron to use script
ssh root@188.166.237.231 "cat > /etc/cron.d/odoobo_backup << 'EOF'
# Odoo nightly backup (2 AM)
0 2 * * * root /usr/local/bin/odoobo-backup.sh >> /var/log/odoobo-backup.log 2>&1
EOF"

# 5. Deploy updated compose.yaml and dynamic.yml
cd /Users/tbwa/Projects/odoobo
git add compose.yaml docker/traefik/dynamic.yml scripts/
git commit -m "fix: Traefik longpolling routing + rate-limit tuning + backup script"
git push origin main

# 6. Pull and restart on server
ssh root@188.166.237.231 "cd /opt/odoobo && git pull && docker compose up -d"

# 7. Verify health
ssh root@188.166.237.231 "/usr/local/bin/odoobo-health.sh"
```

## Troubleshooting

### SSH still refused after above steps

```bash
# Check journal for SSH errors
journalctl -u ssh -n 50 --no-pager

# Check if port 22 is bound
netstat -tlnp | grep :22

# Check SSH config syntax
sshd -t

# Restart SSH forcefully
systemctl stop ssh
systemctl start ssh
```

### Can't access Recovery Console

1. Use DigitalOcean "Power Cycle" (not "Power Off")
2. Try VNC console instead of browser console
3. Contact DO support if hardware issue

### Firewall blocking everything

```bash
# Emergency: disable UFW temporarily
ufw disable

# Re-enable with minimal rules
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
```
