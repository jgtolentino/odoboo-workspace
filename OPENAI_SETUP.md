# 🤖 OpenAI API Key Setup Guide

**Quick guide to resolve the OPENAI_API_KEY missing error**

---

## 🚨 The Error

You're seeing this message because a GitHub Action or bot is trying to use the OpenAI API but can't find the `OPENAI_API_KEY` in your repository secrets.

```
Seems you are using me but didn't get OPENAI_API_KEY seted in Variables/Secrets for this repo.
```

---

## ✅ Quick Fix (5 minutes)

### Step 1: Get Your OpenAI API Key

1. Go to https://platform.openai.com/api-keys
2. Sign in (or create account if needed)
3. Click "Create new secret key"
4. Name it: `odoboo-workspace-github`
5. Click "Create secret key"
6. **Copy the key immediately** (starts with `sk-proj-...`)

**⚠️ Important**: The key is only shown once! Save it somewhere safe temporarily.

---

### Step 2: Add to GitHub Secrets

#### Option A: Using GitHub Web UI (Easiest)

1. Go to your repository: https://github.com/jgtolentino/odoboo-workspace
2. Click **Settings** tab (top menu)
3. In left sidebar:
   - Click "Secrets and variables"
   - Click "Actions"
4. Click **"New repository secret"**
5. Fill in:
   - **Name**: `OPENAI_API_KEY`
   - **Secret**: Paste your OpenAI key (starts with `sk-proj-...`)
6. Click **"Add secret"**

**Done!** ✅

---

#### Option B: Using GitHub CLI (If you prefer terminal)

```bash
# Navigate to your repo
cd /path/to/odoboo-workspace

# Set the secret
gh secret set OPENAI_API_KEY -b "sk-proj-YOUR_KEY_HERE"

# Verify it's set
gh secret list
```

You should see:
```
OPENAI_API_KEY            Updated 2025-10-20
```

---

### Step 3: Verify It Works

Re-run the failed GitHub Action or wait for the next push. The error should disappear.

---

## 💰 Cost Control (Recommended)

OpenAI charges per API usage. To avoid surprises:

### Set Usage Limits

1. Go to https://platform.openai.com/settings/organization/limits
2. Set **Monthly budget**: $10 (adjust as needed)
3. Enable **Email alerts** at 75% and 100%

### Monitor Usage

- Dashboard: https://platform.openai.com/usage
- Typical OCR cost: $0.01-0.05 per receipt
- Model used: `gpt-4o-mini` (cheapest option)

---

## 🔐 Security Best Practices

### ✅ DO:
- Store key in GitHub Secrets (encrypted)
- Set monthly budget limits in OpenAI dashboard
- Rotate key quarterly (every 3 months)
- Monitor usage dashboard weekly

### ❌ DON'T:
- Never commit key to git
- Never hardcode in source files
- Never share key publicly
- Don't use expensive models (stick to gpt-4o-mini)

---

## 🔄 Key Rotation Schedule

**Recommended**: Rotate every 3 months or immediately if exposed

### How to Rotate

1. **Generate new key** in OpenAI dashboard
2. **Update GitHub Secret**:
   ```bash
   gh secret set OPENAI_API_KEY -b "sk-proj-NEW_KEY_HERE"
   ```
3. **Update local .env** (if you have one):
   ```bash
   OPENAI_API_KEY=sk-proj-NEW_KEY_HERE
   ```
4. **Revoke old key** in OpenAI dashboard
5. **Test**: Re-run a GitHub Action to verify

---

## 📚 Related Documentation

- [Complete GitHub Secrets Guide](./docs/GITHUB_SECRETS_SETUP.md) - All repository secrets
- [.env.sample](./.env.sample) - Environment variable template
- [OpenAI Platform Docs](https://platform.openai.com/docs)

---

## 🆘 Still Having Issues?

### Error: "Invalid API key"
- Check key format starts with `sk-proj-`
- Verify key is active in OpenAI dashboard
- Try regenerating the key

### Error: "Rate limit exceeded"
- You've exceeded OpenAI's free tier
- Add billing method in OpenAI dashboard
- Set usage limits to control costs

### Error: "Insufficient quota"
- Add payment method to OpenAI account
- Check current balance and limits
- Top up account if needed

---

## ✅ Checklist

- [ ] Created OpenAI account
- [ ] Generated API key (starts with `sk-proj-`)
- [ ] Added `OPENAI_API_KEY` to GitHub Secrets
- [ ] Set monthly budget limit ($10 recommended)
- [ ] Enabled usage alerts
- [ ] Re-ran failed GitHub Action (if applicable)
- [ ] Verified error is gone

---

**Setup Time**: ~5 minutes
**Monthly Cost**: $1-5 (with OCR usage)
**Next Action**: Set calendar reminder to rotate key in 3 months

---

**Questions?** See [GITHUB_SECRETS_SETUP.md](./docs/GITHUB_SECRETS_SETUP.md) for detailed instructions.
