// Valence notifier.
//
// Runs on a schedule (GitHub Actions) and sends two kinds of push, both FREE
// (no Cloud Functions, no Blaze) via the firebase-admin service account:
//   1. Event pushes  — drains `outbound_notifications` (queued by the app when a
//      coach assigns a workout or leaves a note).
//   2. At-risk alerts — pushes a coach when a client's `lastLogDate` is more than
//      AT_RISK_DAYS old. One push per silence streak.
//
// Each push is rendered in the RECIPIENT's language (their `locale` field on the
// user doc), since the sender's language isn't the recipient's. Both passes are
// idempotent, so the workflow can run as often as you like. See README.md.

const admin = require('firebase-admin');

const AT_RISK_DAYS = Number(process.env.AT_RISK_DAYS || 3);
const LANGS = ['en', 'ar', 'fr', 'es', 'pt', 'de'];

function ymd(date) {
  return date.toISOString().slice(0, 10);
}

function daysBetween(fromYmd, toYmd) {
  const a = new Date(`${fromYmd}T00:00:00Z`).getTime();
  const b = new Date(`${toYmd}T00:00:00Z`).getTime();
  return Math.round((b - a) / 86400000);
}

function localeOf(code) {
  const c = (code || 'en').slice(0, 2).toLowerCase();
  return LANGS.includes(c) ? c : 'en';
}

// Push copy per type, per language. Good-faith translations (mirror the app's).
const STRINGS = {
  at_risk: {
    en: (p) => ({ title: 'A client needs a nudge', body: `${p.name} hasn't logged in ${p.days} days.` }),
    ar: (p) => ({ title: 'أحد عملائك يحتاج إلى متابعة', body: `لم يسجّل ${p.name} منذ ${p.days} أيام.` }),
    fr: (p) => ({ title: 'Un client a besoin d’un rappel', body: `${p.name} n’a rien enregistré depuis ${p.days} jours.` }),
    es: (p) => ({ title: 'Un cliente necesita un empujón', body: `${p.name} no registra desde hace ${p.days} días.` }),
    pt: (p) => ({ title: 'Um cliente precisa de um empurrão', body: `${p.name} não regista há ${p.days} dias.` }),
    de: (p) => ({ title: 'Ein Klient braucht einen Anstoß', body: `${p.name} hat seit ${p.days} Tagen nichts eingetragen.` }),
  },
  new_workout: {
    en: (p) => ({ title: 'New workout assigned', body: p.title || 'Your coach assigned a workout.' }),
    ar: (p) => ({ title: 'تمرين جديد', body: p.title || 'أسند إليك مدربك تمرينًا.' }),
    fr: (p) => ({ title: 'Nouvelle séance', body: p.title || 'Votre coach vous a assigné une séance.' }),
    es: (p) => ({ title: 'Nuevo entrenamiento', body: p.title || 'Tu coach te asignó un entrenamiento.' }),
    pt: (p) => ({ title: 'Novo treino', body: p.title || 'O seu coach atribuiu-lhe um treino.' }),
    de: (p) => ({ title: 'Neues Workout', body: p.title || 'Dein Coach hat dir ein Workout zugewiesen.' }),
  },
  coach_note: {
    en: () => ({ title: 'New note from your coach', body: 'Your coach left you a note.' }),
    ar: () => ({ title: 'ملاحظة جديدة من مدربك', body: 'ترك لك مدربك ملاحظة.' }),
    fr: () => ({ title: 'Nouveau mot de votre coach', body: 'Votre coach vous a laissé un mot.' }),
    es: () => ({ title: 'Nueva nota de tu coach', body: 'Tu coach te dejó una nota.' }),
    pt: () => ({ title: 'Nova nota do seu coach', body: 'O seu coach deixou-lhe uma nota.' }),
    de: () => ({ title: 'Neue Notiz von deinem Coach', body: 'Dein Coach hat dir eine Notiz hinterlassen.' }),
  },
};

function render(type, locale, params) {
  const byType = STRINGS[type];
  if (!byType) return null;
  return (byType[locale] || byType.en)(params || {});
}

async function main() {
  const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  const db = admin.firestore();
  const messaging = admin.messaging();

  // Caches uid -> { token, locale } for the whole run.
  const userCache = new Map();
  async function userFor(uid) {
    if (userCache.has(uid)) return userCache.get(uid);
    const doc = await db.collection('users').doc(uid).get();
    const u = doc.exists
      ? { token: doc.data().fcmToken || null, locale: localeOf(doc.data().locale) }
      : { token: null, locale: 'en' };
    userCache.set(uid, u);
    return u;
  }

  async function sendTo(uid, token, message, data) {
    try {
      await messaging.send({ token, notification: message, data: data || {} });
      return true;
    } catch (err) {
      if (err.code === 'messaging/registration-token-not-registered') {
        await db.collection('users').doc(uid).update({
          fcmToken: admin.firestore.FieldValue.delete(),
        }).catch(() => {});
        userCache.set(uid, { token: null, locale: 'en' });
      } else {
        console.error(`send failed for ${uid}:`, err.message);
      }
      return false;
    }
  }

  let eventCount = 0;
  let atRiskCount = 0;

  // --- 1. Event queue --------------------------------------------------------
  const queue = await db
    .collection('outbound_notifications')
    .where('sent', '==', false)
    .limit(500)
    .get();
  for (const qd of queue.docs) {
    const n = qd.data();
    if (n.toUid && n.type) {
      const user = await userFor(n.toUid);
      const message = render(n.type, user.locale, n.params);
      if (user.token && message && (await sendTo(n.toUid, user.token, message, { type: n.type }))) {
        eventCount += 1;
      }
    }
    await qd.ref.delete().catch(() => {});
  }

  // --- 2. At-risk silence alerts --------------------------------------------
  const today = ymd(new Date());
  const clients = await db.collection('users').where('role', '==', 'client').get();
  for (const doc of clients.docs) {
    const client = doc.data();
    if (!client.coachId || !client.lastLogDate) continue;

    const gap = daysBetween(client.lastLogDate, today);
    if (gap < AT_RISK_DAYS) continue;

    // One push per silence streak: re-arms only after the client logs again.
    if (client.lastAtRiskNotified && client.lastAtRiskNotified > client.lastLogDate) {
      continue;
    }

    const coach = await userFor(client.coachId);
    if (!coach.token) continue;

    const message = render('at_risk', coach.locale, {
      name: client.name || 'A client',
      days: gap,
    });
    if (message && (await sendTo(client.coachId, coach.token, message, { type: 'at_risk', clientId: doc.id }))) {
      await doc.ref.update({ lastAtRiskNotified: today });
      atRiskCount += 1;
    }
  }

  console.log(`notifier: ${eventCount} event push(es), ${atRiskCount} at-risk push(es).`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
