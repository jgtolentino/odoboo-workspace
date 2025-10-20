# SSH Access Setup for Droplet

**Droplet**: ocr-service-droplet
**IP**: 188.166.237.231
**Issue**: SSH key not configured on droplet

## Quick Fix - Option 1: DigitalOcean Console (Fastest)

1. **Open Droplet Console**:

   ```bash
   # Or visit: https://cloud.digitalocean.com/droplets/525178434/access
   ```

2. **Login as root** (use the password from your email)

3. **Add your SSH key**:

   ```bash
   mkdir -p ~/.ssh
   echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL1fS0f8Nw/F3UxJhMhzaOkhfIKktEW+0DTKarPwvywv local-dev" >> ~/.ssh/authorized_keys
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/authorized_keys
   ```

4. **Test SSH from your local machine**:
   ```bash
   ssh root@188.166.237.231 "echo 'SSH working!'"
   ```

## Option 2: Rebuild Droplet with SSH Key

If console access doesn't work:

```bash
# Rebuild droplet with SSH key attached
doctl compute droplet-action rebuild 525178434 \
  --image ubuntu-22-04-x64 \
  --wait

# This will reset the droplet but add your SSH key
```

## Option 3: Password-based SSH (Temporary)

1. **Reset root password** via DigitalOcean console:
   - Go to: https://cloud.digitalocean.com/droplets/525178434/access
   - Click "Reset Root Password"
   - Check your email for the new password

2. **Connect with password**:

   ```bash
   ssh root@188.166.237.231
   # Enter the password from email
   ```

3. **Add your SSH key** (same commands as Option 1)

## After SSH Access Works

Once you can SSH into the droplet, proceed with deployment:

```bash
# Test SSH
ssh root@188.166.237.231 "echo 'SSH working!'"

# Deploy services
./scripts/deploy-agent-service.sh 188.166.237.231

# Setup SSL
./scripts/setup-ssl.sh 188.166.237.231 admin@insightpulseai.net
```

## Verification

```bash
# Should work without password prompt:
ssh root@188.166.237.231 "uname -a"

# Expected output:
# Linux ocr-service-droplet 5.15.0-xxx-generic #xxx-Ubuntu SMP ...
```

---

**Next**: Once SSH works, run deployment script!
