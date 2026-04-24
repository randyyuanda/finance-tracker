const admin = require('firebase-admin');

function init() {
  if (admin.apps.length > 0) return true;
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!raw) {
    console.warn('[FCM] FIREBASE_SERVICE_ACCOUNT not set — push disabled');
    return false;
  }
  try {
    admin.initializeApp({ credential: admin.credential.cert(JSON.parse(raw)) });
    return true;
  } catch (e) {
    console.error('[FCM] Init failed:', e.message);
    return false;
  }
}

/**
 * Send FCM push to one or more device tokens (batched by 500).
 * Silently skips if Firebase is not configured.
 */
exports.sendToTokens = async (tokens, { title, body }) => {
  if (!init() || tokens.length === 0) return;

  const chunks = [];
  for (let i = 0; i < tokens.length; i += 500) chunks.push(tokens.slice(i, i + 500));

  for (const chunk of chunks) {
    try {
      const result = await admin.messaging().sendEachForMulticast({
        tokens: chunk,
        notification: { title, body },
        android: {
          priority: 'high',
          notification: { channelId: 'fintrack_admin', sound: 'default' },
        },
      });
      const failed = result.responses.filter((r) => !r.success).length;
      if (failed > 0) console.warn(`[FCM] ${failed}/${chunk.length} tokens failed`);
    } catch (e) {
      console.error('[FCM] Multicast error:', e.message);
    }
  }
};
