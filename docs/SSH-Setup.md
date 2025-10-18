# SSH Setup for Local/Cline/Servers

## Overview

This guide covers SSH key setup for secure Git operations, separate from the ChatGPT GitHub OAuth integration. SSH is used for local development, Cline automation, and server deployments.

## A) ChatGPT ↔ GitHub Tool

**Important**: ChatGPT uses OAuth authentication, not SSH. This is handled automatically through the GitHub App integration.

## B) SSH for Local/Cline/Servers

### 1. Generate SSH Key

```bash
ssh-keygen -t ed25519 -C "you@email" -f ~/.ssh/id_ed25519
```

**Options:**

- `-t ed25519`: Use modern Ed25519 algorithm (recommended)
- `-C "you@email"`: Comment for key identification
- `-f ~/.ssh/id_ed25519`: Key file location

### 2. Start SSH Agent and Add Key

#### macOS

```bash
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

#### Linux

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

#### Windows (PowerShell)

```powershell
Start-Service ssh-agent
ssh-add $env:USERPROFILE\.ssh\id_ed25519
```

### 3. Add Public Key to GitHub

#### Using GitHub CLI

```bash
gh ssh-key add ~/.ssh/id_ed25519.pub -t "$(hostname)-dev"
```

#### Using GitHub Web UI

1. Go to **Settings** → **SSH and GPG keys**
2. Click **New SSH key**
3. Paste contents of `~/.ssh/id_ed25519.pub`
4. Add descriptive title (e.g., "MacBook-Pro-Dev")

### 4. Trust Host and Test Connection

```bash
# Add GitHub to known hosts
ssh-keyscan github.com >> ~/.ssh/known_hosts

# Test SSH connection
ssh -T git@github.com
```

**Expected output:**

```
Hi jgtolentino! You've successfully authenticated, but GitHub does not provide shell access.
```

### 5. Switch Repository Remote to SSH

```bash
git remote set-url origin git@github.com:jgtolentino/v0-odoo-notion-workspace.git
```

### 6. Optional SSH Configuration

Create `~/.ssh/config` for advanced settings:

```sshconfig
Host github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
  AddKeysToAgent yes
  UseKeychain yes        # macOS only

# Fallback through port 443 if firewalled
Host github-443
  HostName ssh.github.com
  User git
  Port 443
  IdentityFile ~/.ssh/id_ed25519
```

### 7. CI/Servers Configuration

#### Option A: Deploy Keys (Per-Repository)

1. Generate unique key for each server
2. Add public key as deploy key in repository settings
3. Use read-only or read-write as needed

#### Option B: Machine User

1. Create dedicated GitHub user for automation
2. Add SSH key to machine user account
3. Grant necessary repository permissions

#### Usage in Automation

```bash
GIT_SSH_COMMAND='ssh -i /path/to/key -o IdentitiesOnly=yes' git clone git@github.com:jgtolentino/v0-odoo-notion-workspace.git
```

### 8. Optional: SSH Commit Signing

```bash
# Configure SSH for commit signing
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true

# Verify signed commits work
git commit -S -m "Test signed commit"
```

## SSH Key Management

### Multiple Keys

If you have multiple SSH keys:

```sshconfig
Host github-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_personal
  IdentitiesOnly yes

Host github-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_work
  IdentitiesOnly yes
```

### Key Rotation

1. Generate new key pair
2. Add new public key to GitHub
3. Update any automation/scripts
4. Test new key works
5. Remove old key from GitHub

## Troubleshooting

### Common Issues

#### Permission Denied

```bash
# Fix SSH directory permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
chmod 644 ~/.ssh/known_hosts
```

#### Agent Not Running

```bash
# Restart SSH agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

#### Connection Timeout

```bash
# Try port 443 fallback
ssh -T -p 443 git@ssh.github.com
```

### Debug SSH Connection

```bash
# Verbose SSH output
ssh -T -v git@github.com

# Test specific key
ssh -T -i ~/.ssh/id_ed25519 git@github.com
```

## Security Best Practices

1. **Use Ed25519 keys** (modern, secure)
2. **Protect private keys** with strong permissions
3. **Use passphrases** for additional security
4. **Rotate keys regularly** (every 6-12 months)
5. **Monitor GitHub security log** for key usage
6. **Use deploy keys** for CI/CD (read-only when possible)

## Integration with Cline

For Cline automation, ensure:

- SSH key is available in the environment
- Git is configured to use SSH
- Repository URLs use SSH format
- Proper permissions for automated operations

This completes SSH setup for secure Git operations across local development, Cline automation, and server deployments.
