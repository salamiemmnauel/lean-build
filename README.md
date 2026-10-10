# LeanBuild Fitness Tracker

A beginner-friendly, mobile-ready Progressive Web App (PWA) for tracking home workouts, meals, calories, protein, weight and body measurements.

## What's included
- Responsive layout for MacBook and phone
- Home workout routines A, B, C and D
- Food diary with calories and protein
- Weight log, trend chart and body measurements
- Editable targets (defaults: age 20, height 175 cm, starting weight 58 kg, target 64 kg, 2,400 kcal and 110 g protein)
- JSON backup export/import
- Offline app shell after the first successful visit
- Installable on supported browsers

## Important data note
This starter version stores data in the current browser on the current device. It does **not** automatically sync your phone and MacBook. Use **My targets → Export backup** on one device, then **Import backup** on the other. Do not use private/incognito browsing if you want logs to persist.

## Test locally on your Mac
1. Download and unzip `LeanBuild.zip`.
2. Open Terminal.
3. Type `cd ` (include a space), drag the unzipped `LeanBuild` folder into Terminal, and press Return.
4. Run `python3 -m http.server 8000`.
5. In your browser, open `http://localhost:8000`.
6. Stop the local server with `Control + C` in Terminal.

A local HTTP server is needed for service workers; opening `index.html` by double-clicking it will not enable the full offline/install features.

## Free deployment with GitHub Pages
1. Sign in or create a free account at https://github.com.
2. Click **+** → **New repository**. Name it `leanbuild`, choose **Public**, and create it.
3. Open the repository. Click **Add file** → **Upload files**.
4. Upload the *contents* of this folder: `index.html`, `styles.css`, `app.js`, `manifest.webmanifest`, `sw.js`, `README.md`, and the `icons` folder. Keep the filenames and folder structure exactly the same.
5. Click **Commit changes**.
6. Open **Settings** → **Pages**.
7. Under **Build and deployment**, set Source to **Deploy from a branch**, choose branch `main`, folder `/(root)`, then click **Save**.
8. Wait a minute or two. GitHub Pages will show your live address, usually `https://YOUR-USERNAME.github.io/leanbuild/`.
9. Open that HTTPS address on your MacBook and phone. Log something on each device to check it.

Official guide: https://docs.github.com/en/pages/getting-started-with-github-pages/creating-a-github-pages-site

## Install on iPhone / iPad
1. Open your live GitHub Pages address in Safari.
2. Tap the **Share** icon.
3. Choose **Add to Home Screen**. If offered, enable **Open as Web App**, then tap **Add**.

## Install on Android
1. Open the live address in Chrome.
2. Open the three-dot menu and choose **Install app** or **Add to Home screen**.

## Install on Mac
1. Open the live address in a supported browser such as Chrome or Edge.
2. Look for the install icon in the address bar or browser menu and choose **Install LeanBuild** / **Install page as app** if offered.
3. Safari on macOS versions that support web apps may offer **File → Add to Dock**.

## If GitHub Pages does not appear
- Confirm the files are in the repository root, not inside an extra nested `LeanBuild` folder.
- Check **Settings → Pages** to make sure `main` and `/(root)` are selected.
- Check the **Actions** tab for deployment status.
- The app needs an HTTPS URL for service-worker/offline support. GitHub Pages provides HTTPS.

## Privacy
There is no account or server database in this starter build. Your logs stay in the browser's local storage on each device. Export backups before clearing browser data. This app is a tracker, not medical advice.
