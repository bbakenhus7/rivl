# RIVL - Deployment Guide

Your RIVL app is built and ready to deploy! Here are several free options to get it online:

## Quick Deploy Options

### Option 1: Vercel (Recommended - Easiest)

1. **Install Vercel CLI** (if not already installed):
   ```bash
   npm install -g vercel
   ```

2. **Deploy**:
   ```bash
   cd build/web
   vercel
   ```

3. Follow the prompts (you'll need to sign up for a free Vercel account if you don't have one)

4. You'll get a URL like: `https://your-app.vercel.app`

**Vercel URL**: Perfect for Flutter web apps, free tier, auto HTTPS

---

### Option 2: Netlify (Alternative)

1. **Install Netlify CLI**:
   ```bash
   npm install -g netlify-cli
   ```

2. **Deploy**:
   ```bash
   cd build/web
   netlify deploy --prod
   ```

3. You'll get a URL like: `https://your-app.netlify.app`

---

### Option 3: GitHub Pages

1. **Push your code to GitHub** (if not already there)

2. **Create a gh-pages branch**:
   ```bash
   git checkout -b gh-pages
   cp -r build/web/* .
   touch .nojekyll
   git add .
   git commit -m "Deploy to GitHub Pages"
   git push origin gh-pages
   ```

3. **Enable GitHub Pages**:
   - Go to your GitHub repository
   - Settings → Pages
   - Source: Deploy from branch
   - Branch: `gh-pages` / `root`
   - Save

4. Your app will be at: `https://[username].github.io/rivl/`

---

### Option 4: Firebase Hosting

Since your app already uses Firebase, this is a great option:

1. **Install Firebase CLI**:
   ```bash
   npm install -g firebase-tools
   ```

2. **Login and initialize**:
   ```bash
   firebase login
   firebase init hosting
   ```

   When prompted:
   - Public directory: `build/web`
   - Configure as single-page app: `Yes`
   - Set up automatic builds: `No`

3. **Deploy**:
   ```bash
   firebase deploy --only hosting
   ```

4. You'll get a URL like: `https://your-project.web.app`

---

### Option 5: Surge.sh (Super Simple)

1. **Install Surge**:
   ```bash
   npm install -g surge
   ```

2. **Deploy**:
   ```bash
   cd build/web
   surge
   ```

3. First time: Enter email and choose a domain
4. You'll get a URL like: `https://your-domain.surge.sh`

---

## Your Build is Ready

The built files are already in `/home/user/rivl/build/web/`:
- `index.html` - Main HTML file
- `main.dart.js` - Compiled Flutter app (2.7MB)
- `assets/` - Fonts, icons, and resources
- `canvaskit/` - Flutter rendering engine

## Important Notes

### Firebase Configuration
Your app currently uses **stub Firebase credentials** for local development. Before deploying to production:

1. Create a real Firebase project at https://console.firebase.google.com
2. Get your web configuration
3. Replace `/lib/firebase_options_stub.dart` with real credentials
4. Rebuild: `flutter build web`

### Stripe Configuration
Currently using a fake publishable key. For production:

1. Get your real Stripe publishable key from https://dashboard.stripe.com
2. Update in `lib/main.dart` line 32
3. Rebuild: `flutter build web`

---

## Need Help?

Choose the deployment method that works best for you:
- **Vercel** - Best for quick deployment, great free tier
- **Netlify** - Similar to Vercel, also excellent
- **GitHub Pages** - If you want version control integration
- **Firebase** - If you want everything in one ecosystem
- **Surge** - Simplest option, no account needed initially

After deploying, you'll have a public URL to access your RIVL app from anywhere!
