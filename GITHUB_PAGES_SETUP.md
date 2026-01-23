# 🚀 GitHub Pages Setup Instructions

Your RIVL app is ready to deploy! Follow these simple steps to make it live.

## ✅ Step 1: Merge the Branch (Optional but Recommended)

First, merge the deployment branch into your main branch:

1. Go to your repository: **https://github.com/bbakenhus7/rivl**
2. You'll see a notification about the branch `claude/understand-rivl-code-ibNax`
3. Click **"Compare & pull request"**
4. Review the changes (you'll see the `docs/` folder added)
5. Click **"Create pull request"**
6. Click **"Merge pull request"** → **"Confirm merge"**

## 🌐 Step 2: Enable GitHub Pages

Now enable GitHub Pages to serve your app:

1. Go to your repository: **https://github.com/bbakenhus7/rivl**
2. Click on **Settings** (top right)
3. In the left sidebar, scroll down and click **Pages**
4. Under "Build and deployment":
   - **Source**: Select "Deploy from a branch"
   - **Branch**: Select `main` (or `claude/understand-rivl-code-ibNax`) and `/docs` folder
   - Click **Save**

## ⏱️ Step 3: Wait for Deployment (1-2 minutes)

GitHub will now deploy your app. You'll see:
- "Your site is ready to be published at..."
- After 1-2 minutes, it will change to "Your site is live at..."

## 🎉 Step 4: Access Your App

Your RIVL app will be live at:

**https://bbakenhus7.github.io/rivl/**

---

## 🔧 Troubleshooting

### If you see a 404 error:
- Wait 2-3 minutes for initial deployment
- Make sure you selected the `/docs` folder (not root)
- Refresh your browser cache (Ctrl+Shift+R or Cmd+Shift+R)

### If you see a blank page:
- Check the browser console (F12) for errors
- Make sure you merged the branch or selected the correct branch in Pages settings

### Need to redeploy?
If you make changes and rebuild:
1. Run `flutter build web` in your local environment
2. Copy contents from `build/web/` to `docs/` folder
3. Commit and push to GitHub
4. GitHub Pages will automatically redeploy

---

## 📝 Important Notes

### Firebase Configuration
Your app currently uses **stub Firebase credentials**. Before using authentication:

1. Create a Firebase project at https://console.firebase.google.com
2. Add a web app to your project
3. Copy your Firebase configuration
4. Replace the stub config in `lib/firebase_options_stub.dart`
5. Rebuild and redeploy

### Stripe Configuration
Currently using a placeholder key. For real payments:

1. Get your Stripe publishable key from https://dashboard.stripe.com
2. Update in `lib/main.dart` (line 32)
3. Rebuild and redeploy

---

## 🎊 That's It!

Once GitHub Pages is enabled, your RIVL fitness competition app will be live and accessible to anyone with the URL!

**Your URL**: https://bbakenhus7.github.io/rivl/

Enjoy! 🏃‍♂️💪
