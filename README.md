# LeanBuild Community

LeanBuild is a mobile-ready fitness tracker and community app. The original tracker works locally; with a Supabase project connected, members can create accounts, sync private tracker data across devices, find friends, accept friend requests, share progress updates, opt into a workout leaderboard, and use a protected admin area.

## Files

- `index.html`, `styles.css`, `app.js`: the fitness tracker.
- `community.js`: account, cloud-sync, friends, feed, leaderboard, and admin interface.
- `supabase-config.js`: the public project URL and anon/public key placeholders.
- `supabase-schema.sql`: database tables, account profile creation, workout count trigger, and row-level security rules.
- `sw.js`, `manifest.webmanifest`, `icons/`: installable web app support.

## Important before going live

The community will not work until you create a Supabase project, run `supabase-schema.sql`, and fill in `supabase-config.js`. GitHub Pages only hosts the static website; Supabase provides the database and authentication.

Use only the Supabase **Project URL** and **anon/public key** in `supabase-config.js`. Never put a `service_role`, secret, or database password in any website file or public GitHub repository. The schema enables row-level security: tracker JSON (including meals, body measurements and weight history) is readable only by its owner. Public community profiles, posts and opted-in leaderboard fields are visible to signed-in members.

Free plans have quotas and provider terms can change. This setup is intended to fit within free tiers for a small community, but no provider can promise that every workload will remain free forever. Monitor usage in Supabase and keep a backup of your database and project settings.

## 1. Create a Supabase project

1. Open [https://supabase.com](https://supabase.com) and create a free account/project.
2. Choose a strong database password and save it somewhere private. It is not used in the front-end config.
3. Open **SQL Editor** in the Supabase dashboard, create a new query, paste the full contents of `supabase-schema.sql`, then click **Run**.
4. Open **Project Settings → API** (or the project's API keys page). Copy the **Project URL** and the **anon/public** key.
5. Open `supabase-config.js` in a text editor and replace the two placeholder values. Keep the quotation marks. Example format only:
   - URL: `https://your-project-id.supabase.co`
   - Key: the long anon/public key from your own project
6. Save the file. Do not share your key in chat or screenshots. The anon/public key is designed for browser use when row-level security is correctly configured; a service-role key is not.

## 2. Replace the files in GitHub

If you already deployed the original LeanBuild:

1. Open your `leanbuild` GitHub repository.
2. Upload the contents of this folder, replacing the old files when GitHub asks. Keep the `icons` folder in place.
3. Ensure `community.js`, `supabase-config.js`, and `supabase-schema.sql` are in the repository root, beside `index.html`.
4. Commit the changes and wait for GitHub Pages to redeploy.
5. Open the website and select **Community** in the navigation.

If GitHub does not offer replacement for an existing file, open that file in the repository, choose the pencil/edit control, replace its content with the matching file's content, and commit. Or delete the old file and upload the new one with the same name.

## 3. Configure email authentication

In Supabase, open **Authentication → URL Configuration**. Add your GitHub Pages URL to the allowed redirect/site URL list, for example `https://YOUR-USERNAME.github.io/leanbuild/`. Use your actual URL. If email confirmation is enabled, members must confirm the email before they can log in. Configure the email provider/settings in Supabase if required.

## 4. Make your account an admin

1. Sign up for LeanBuild with your own email and confirm it if required.
2. In Supabase, open **SQL Editor** and run the following after replacing the example email with the exact email you used. This assigns the admin role to your account only:

```sql
update public.profiles
set role = 'admin'
where id = (select id from auth.users where email = 'YOUR-EMAIL@example.com');
```

3. Sign out and sign back in, then open **Community → Admin**. The admin screen can review member accounts and remove inappropriate community posts. Role changes are deliberately not available in the public website.

## 5. How cloud sync works

- Sign in on the device that has your existing local LeanBuild data first. If the account has no cloud record yet, the current local tracker data is uploaded on sign-in.
- Once a cloud record exists, signing in on another device downloads that account's saved tracker data. Later changes are saved to the cloud automatically after a short pause.
- Avoid making simultaneous edits to the same account on two devices. This simple starter uses last-save-wins syncing, not a full conflict-merging system.
- Keep exported backups. The app's service worker can cache the shell for offline viewing, but authentication and cloud sync need an internet connection.

## 6. Community privacy

- Workout/meal/weight/measurement tracker data is private to the account that owns it.
- Display name, username, bio and opted-in workout count are visible to signed-in community members.
- Posts are shared with signed-in community members and can be deleted by their author or an admin.
- Leaderboard participation is opt-in. Only display name, username and workout count appear on it.
- This is a starter community, not a fully audited commercial platform. Before inviting a large public audience, add rate limits/abuse reporting, account deletion/export workflows, stronger moderation tools, and review the database policies with a security professional.

## Local testing on Mac

1. Open Terminal and type `cd ` (include a space), then drag the extracted folder into Terminal and press Return.
2. Run `python3 -m http.server 8000`.
3. Open `http://localhost:8000` in your browser.
4. Stop with `Control + C`.

For authentication, configure the Supabase URL settings to allow your local test URL if needed. The live GitHub Pages URL uses HTTPS.
