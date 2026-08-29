/**
 * CarpenterHub push sender.
 *
 * Sending an FCM message needs a service-account private key. That key
 * grants full access to the Firebase project, so it can't live in the
 * admin console (a Flutter web app -- everything in it is readable by
 * anyone who opens the site). This Worker holds the key instead and is
 * the only thing that talks to FCM.
 *
 * Cloud Functions would normally do this job, but that requires the paid
 * Blaze plan; FCM itself is free on any plan, so the project stays on
 * Spark and the trigger runs here on Cloudflare's free tier.
 *
 * Flow: admin console POSTs here with the signed-in admin's Firebase ID
 * token -> we verify that token, confirm the uid is in the `admins`
 * collection, look up the target carpenters' device tokens, and send.
 * Without the admin check anyone who found this URL could push arbitrary
 * notifications to every carpenter.
 *
 * Secrets (set with `npx wrangler secret put <NAME>`):
 *   SERVICE_ACCOUNT_JSON  the whole service-account JSON file
 *   FIREBASE_API_KEY      the project's Web API key (public, but kept
 *                         here so the Worker needs no other config)
 */

const PROJECT_ID = 'carpenterhub-96958';

// Only the admin console may call this. Anything else gets no CORS
// headers back, so a page on another origin can't use it.
const ALLOWED_ORIGINS = [
  'https://carpenterhub-96958.web.app',
  'https://carpenterhub-96958.firebaseapp.com',
  'http://localhost:5000',
];

const FIRESTORE = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

export default {
  async fetch(request, env) {
    const origin = request.headers.get('Origin') || '';
    const cors = corsHeaders(origin);

    if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: cors });
    if (request.method !== 'POST') return json({ error: 'POST only' }, 405, cors);

    try {
      const { idToken, carpenterIds, title, body, type, refId } = await request.json();
      if (!idToken) return json({ error: 'missing idToken' }, 401, cors);
      if (!Array.isArray(carpenterIds) || carpenterIds.length === 0) {
        return json({ error: 'missing carpenterIds' }, 400, cors);
      }
      if (!title || !body) return json({ error: 'missing title/body' }, 400, cors);

      const uid = await verifyIdToken(idToken, env.FIREBASE_API_KEY);
      if (!uid) return json({ error: 'invalid idToken' }, 401, cors);

      const accessToken = await getAccessToken(env);

      if (!(await docExists(`admins/${uid}`, accessToken)) &&
          !(await docExists(`orderCreators/${uid}`, accessToken))) {
        return json({ error: 'not authorized' }, 403, cors);
      }

      // One carpenter can have the app on several handsets, so this is a
      // token -> carpenter map rather than a flat list: a token that
      // turns out to be dead has to be removed from the right document.
      const targets = await collectTokens(carpenterIds, accessToken);
      if (targets.length === 0) return json({ sent: 0, note: 'no registered devices' }, 200, cors);

      let sent = 0;
      const dead = [];
      for (const { carpenterId, token } of targets) {
        const result = await sendToToken(token, { title, body, type, refId }, accessToken);
        if (result.ok) sent++;
        else if (result.dead) dead.push({ carpenterId, token });
      }

      // Uninstalled apps leave tokens behind forever otherwise, and every
      // later send wastes a request on them.
      for (const d of dead) await removeToken(d.carpenterId, d.token, accessToken);

      return json({ sent, devices: targets.length, cleaned: dead.length }, 200, cors);
    } catch (e) {
      return json({ error: `${e}` }, 500, cors);
    }
  },
};

function corsHeaders(origin) {
  const headers = {
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Max-Age': '86400',
  };
  if (ALLOWED_ORIGINS.includes(origin)) headers['Access-Control-Allow-Origin'] = origin;
  return headers;
}

function json(obj, status, cors) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { 'Content-Type': 'application/json', ...cors },
  });
}

/**
 * Confirms the caller really is signed into this Firebase project and
 * returns their uid. Google's identitytoolkit endpoint does the whole
 * signature/expiry check, which is why the Worker doesn't hand-verify
 * the JWT.
 */
async function verifyIdToken(idToken, apiKey) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ idToken }),
    },
  );
  if (!res.ok) return null;
  const data = await res.json();
  return data.users?.[0]?.localId ?? null;
}

/** Service-account JWT -> OAuth access token, for FCM and Firestore. */
async function getAccessToken(env) {
  const sa = JSON.parse(env.SERVICE_ACCOUNT_JSON);
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claim = b64url(
    JSON.stringify({
      iss: sa.client_email,
      scope: [
        'https://www.googleapis.com/auth/firebase.messaging',
        'https://www.googleapis.com/auth/datastore',
      ].join(' '),
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    }),
  );

  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToDer(sa.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(`${header}.${claim}`),
  );
  const jwt = `${header}.${claim}.${b64urlBytes(new Uint8Array(signature))}`;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });
  const data = await res.json();
  if (!data.access_token) throw new Error(`token exchange failed: ${JSON.stringify(data)}`);
  return data.access_token;
}

async function docExists(path, accessToken) {
  const res = await fetch(`${FIRESTORE}/${path}`, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  return res.ok;
}

async function collectTokens(carpenterIds, accessToken) {
  const targets = [];
  for (const carpenterId of carpenterIds) {
    const res = await fetch(`${FIRESTORE}/carpenters/${carpenterId}`, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
    if (!res.ok) continue;
    const doc = await res.json();
    const values = doc.fields?.fcmTokens?.arrayValue?.values ?? [];
    for (const v of values) {
      if (v.stringValue) targets.push({ carpenterId, token: v.stringValue });
    }
  }
  return targets;
}

/**
 * A `notification` block makes Android draw the tray entry itself when
 * the app is closed; `data` carries the deep link. android.priority high
 * is what gets it delivered promptly on a dozing device.
 */
async function sendToToken(token, { title, body, type, refId }, accessToken) {
  const res = await fetch(`https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      message: {
        token,
        notification: { title, body },
        // FCM rejects non-string data values.
        data: { type: `${type ?? ''}`, refId: `${refId ?? ''}` },
        android: {
          priority: 'HIGH',
          notification: { channel_id: 'carpenterhub_default' },
        },
      },
    }),
  });
  if (res.ok) return { ok: true };
  const err = await res.json().catch(() => ({}));
  const status = err.error?.details?.[0]?.errorCode ?? err.error?.status ?? '';
  // UNREGISTERED = app uninstalled or token rotated; INVALID_ARGUMENT on
  // a send this simple means the token itself is malformed.
  return { ok: false, dead: status === 'UNREGISTERED' || status === 'INVALID_ARGUMENT' };
}

async function removeToken(carpenterId, token, accessToken) {
  await fetch(`${FIRESTORE}:commit`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      writes: [
        {
          transform: {
            document: `projects/${PROJECT_ID}/databases/(default)/documents/carpenters/${carpenterId}`,
            fieldTransforms: [
              {
                fieldPath: 'fcmTokens',
                removeAllFromArray: { values: [{ stringValue: token }] },
              },
            ],
          },
        },
      ],
    }),
  });
}

function b64url(str) {
  return b64urlBytes(new TextEncoder().encode(str));
}

function b64urlBytes(bytes) {
  let binary = '';
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

/** PEM (as stored in the service-account JSON) -> raw DER for WebCrypto. */
function pemToDer(pem) {
  const base64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '');
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}
