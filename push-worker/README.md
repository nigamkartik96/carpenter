# CarpenterHub push sender

Sends the phone-level push notifications for the carpenter app, free.

## Why this exists

FCM (the push service itself) is free on Firebase's Spark plan and always
has been. What isn't free is **Cloud Functions**, which is where the
"when a notification is created, send a push" code normally lives — that
needs the paid Blaze plan.

So that code lives here instead, on Cloudflare's free tier, and the
Firebase project stays on Spark. Functionally it's the same thing: the
carpenter's phone shows the notification within seconds, whether the app
is open, backgrounded, or fully closed.

It can't live in the admin console, because sending requires a
service-account private key that grants full access to the Firebase
project — and the admin console is a Flutter **web** app, so anything in
it is readable by anyone who opens the site.

## How a notification travels

1. Admin does something in the console (comments on an order, credits
   points, publishes an offer, sends a broadcast).
2. The console writes the notification document to Firestore — this is
   the source of truth, and drives the in-app notification list.
3. The console then POSTs to this Worker, including the admin's own
   Firebase ID token.
4. The Worker verifies that token, confirms the uid is in the `admins`
   collection, reads the target carpenters' device tokens from their
   `carpenters/{id}.fcmTokens` field, and calls FCM.
5. The phone shows the notification. Tapping it opens the order.

Step 3 failing (Worker down, not deployed, misconfigured) never breaks
step 2 — the admin's action still succeeds and the in-app list still
updates. Push is strictly additive.

## One-time setup

### 1. Create the Cloudflare account

Sign up at <https://dash.cloudflare.com/sign-up>. The Workers free plan
covers 100,000 requests/day and does not ask for a card.

### 2. Get the Firebase service-account key

Firebase Console → gear icon → **Project settings** → **Service accounts**
→ **Generate new private key**. This downloads a JSON file.

Treat it like a password: it grants full admin access to the project.
Never commit it — it goes in as a Worker secret below, not into git.

### 3. Get the Web API key

Firebase Console → **Project settings** → **General** → "Web API key".
This one is public (it already ships inside both apps); the Worker uses
it to verify admin ID tokens.

### 4. Deploy

From this directory:

```bash
npm install
```

```bash
npx wrangler login
```

```bash
npx wrangler secret put SERVICE_ACCOUNT_JSON
```

Paste the **entire contents** of the JSON file from step 2 when prompted,
then press Enter.

```bash
npx wrangler secret put FIREBASE_API_KEY
```

Paste the Web API key from step 3.

```bash
npx wrangler deploy
```

Deploy prints a URL like
`https://carpenterhub-push.<your-subdomain>.workers.dev`.

### 5. Point the admin console at it

Put that URL in `kPushWorkerUrl` in
`admin_console/lib/push_service.dart`, then redeploy the console:

```bash
./deploy-admin.ps1
```

Until this is set, the constant stays empty and the console simply skips
the push call — everything else works as before.

## Testing it

1. Install the new APK on a phone and log in as an approved carpenter.
   Accept the notification permission prompt when it appears.
2. Confirm the device registered: in Firestore, that carpenter's document
   should now have an `fcmTokens` array with one entry.
3. In the admin console, open one of that carpenter's orders and post a
   comment.
4. The phone should show a notification within a few seconds — including
   with the app closed. Tapping it opens that order.

If nothing arrives, check the Worker's own logs:

```bash
npx wrangler tail
```

Common causes: the phone denied the notification permission (Android
Settings → Apps → CarpenterHub → Notifications), the carpenter never
opened the new build so has no token registered, or `kPushWorkerUrl` was
left empty in the console build that's currently deployed.

## Costs

Nothing. FCM is free and unmetered. Cloudflare's free tier allows 100,000
Worker requests per day; one push to one device is one request, so a
few hundred notifications a day uses a fraction of a percent of it.
