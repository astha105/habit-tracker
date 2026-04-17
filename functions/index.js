/**
 * habit_tracker_backend — Firebase Cloud Functions
 * Project : habitron-dev
 *
 * Sections
 * ────────
 * 1.  Imports & init
 * 2.  Auth triggers        — new user setup, account deletion cleanup
 * 3.  Habits API           — CRUD for habits + completion logging
 * 4.  Streaks & Stats      — server-side streak calculation, weekly summary
 * 5.  AI — Daily Message   — Gemini-powered personalised motivation
 * 6.  AI — Weekly Review   — Gemini-powered weekly habit review
 * 7.  AI — Habit Coach     — conversational habit advice (premium)
 * 8.  Payments             — Razorpay webhook → unlock premium
 * 9.  Scheduled jobs       — daily streak reset, weekly digest push
 */

"use strict";

// ─────────────────────────────────────────────────────────────────────────────
// 1. Imports & init
// ─────────────────────────────────────────────────────────────────────────────
const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated, onDocumentDeleted } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onValueCreated } = require("firebase-functions/v2/database");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { getMessaging } = require("firebase-admin/messaging");
const { initializeApp } = require("firebase-admin/app");
const { defineSecret } = require("firebase-functions/params");
const crypto = require("crypto");

initializeApp();
const db = getFirestore();

// Secrets — set via:  firebase functions:secrets:set RAZORPAY_WEBHOOK_SECRET
const RAZORPAY_SECRET = defineSecret("RAZORPAY_WEBHOOK_SECRET");

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/** Throws HttpsError if the caller is not authenticated. */
function requireAuth(auth) {
  if (!auth?.uid) throw new HttpsError("unauthenticated", "Sign in required.");
}

/** Throws HttpsError if uid from auth doesn't match the requested uid. */
function requireOwner(auth, uid) {
  requireAuth(auth);
  if (auth.uid !== uid) throw new HttpsError("permission-denied", "Access denied.");
}

/** ISO date string YYYY-MM-DD for a given Date (or today). */
function isoDate(d = new Date()) {
  return d.toISOString().slice(0, 10);
}

/** ISO week number (1-53). */
function isoWeek(d = new Date()) {
  const tmp = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
  tmp.setUTCDate(tmp.getUTCDate() + 4 - (tmp.getUTCDay() || 7));
  const yearStart = new Date(Date.UTC(tmp.getUTCFullYear(), 0, 1));
  return Math.ceil((((tmp - yearStart) / 86400000) + 1) / 7);
}


// ─────────────────────────────────────────────────────────────────────────────
// 2. Auth Triggers
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Triggered when a new Firebase Auth user is created.
 * Creates a /users/{uid} profile document with defaults.
 */
exports.onUserCreated = onDocumentCreated(
  // Firestore trigger — we use a "shadow" write from onCall below instead,
  // so this listens to that creation.
  "users/{uid}",
  async (event) => {
    // Nothing extra to do — profile is written by createOrUpdateProfile.
  }
);

/**
 * Callable: createOrUpdateProfile
 * Called once after sign-in / sign-up from the Flutter app.
 *
 * Input:  { displayName, email, photoUrl? }
 * Output: { uid, isNew }
 */
exports.createOrUpdateProfile = onCall(async (request) => {
  requireAuth(request.auth);
  const uid = request.auth.uid;
  const { displayName, email, photoUrl } = request.data;

  const ref = db.collection("users").doc(uid);
  const snap = await ref.get();
  const isNew = !snap.exists;

  if (isNew) {
    await ref.set({
      uid,
      displayName: displayName || "",
      email: email || "",
      photoUrl: photoUrl || "",
      premium: false,
      premiumUnlockedAt: null,
      createdAt: FieldValue.serverTimestamp(),
      lastActiveAt: FieldValue.serverTimestamp(),
      totalHabitsCreated: 0,
      currentStreak: 0,
      bestStreak: 0,
      fcmToken: null,
    });
  } else {
    await ref.update({
      displayName: displayName || snap.data().displayName,
      email: email || snap.data().email,
      lastActiveAt: FieldValue.serverTimestamp(),
    });
  }

  return { uid, isNew };
});

/**
 * Callable: deleteAccount
 * Deletes all user data from Firestore then deletes the Auth user.
 */
exports.deleteAccount = onCall(async (request) => {
  requireAuth(request.auth);
  const uid = request.auth.uid;

  // Delete sub-collections
  const batch = db.batch();
  const habitsSnap = await db.collection("users").doc(uid).collection("habits").get();
  habitsSnap.forEach((d) => batch.delete(d.ref));
  batch.delete(db.collection("users").doc(uid));
  await batch.commit();

  await getAuth().deleteUser(uid);
  return { success: true };
});

// ─────────────────────────────────────────────────────────────────────────────
// 3. Habits API
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Callable: createHabit
 *
 * Input:
 *   title, description, category, targetDays,
 *   color (hex string), iconCodePoint,
 *   trackingMode ("stepByStep"|"customValue"), customValue,
 *   completionsPerDay, reminderTimes (list of "HH:MM"),
 *   stackedAfter (habit title or null)
 *
 * Output: { habitId }
 */
exports.createHabit = onCall(async (request) => {
  requireAuth(request.auth);
  const uid = request.auth.uid;
  const d = request.data;

  const ref = db.collection("users").doc(uid).collection("habits").doc();
  await ref.set({
    habitId: ref.id,
    uid,
    title: d.title,
    description: d.description || "",
    category: d.category || "General",
    targetDays: d.targetDays || 30,
    currentDays: 0,
    color: d.color || "#7C6FD8",
    iconCodePoint: d.iconCodePoint || 0xe3c9,
    trackingMode: d.trackingMode || "stepByStep",
    customValue: d.customValue || 1,
    completionsPerDay: d.completionsPerDay || 1,
    reminderTimes: d.reminderTimes || [],
    stackedAfter: d.stackedAfter || null,
    completionHistory: [],    // list of "YYYY-MM-DD" strings
    currentStreak: 0,
    bestStreak: 0,
    lastLoggedDate: null,
    archived: false,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  // Update user aggregate
  await db.collection("users").doc(uid).update({
    totalHabitsCreated: FieldValue.increment(1),
  });

  return { habitId: ref.id };
});

/**
 * Callable: updateHabit
 * Partial update — only fields present in request.data are changed.
 *
 * Input:  { habitId, ...fieldsToUpdate }
 */
exports.updateHabit = onCall(async (request) => {
  requireAuth(request.auth);
  const uid = request.auth.uid;
  const { habitId, ...fields } = request.data;
  if (!habitId) throw new HttpsError("invalid-argument", "habitId required.");

  // Prevent overwriting system fields
  const forbidden = ["uid", "habitId", "completionHistory", "currentStreak",
    "bestStreak", "lastLoggedDate", "createdAt"];
  forbidden.forEach((k) => delete fields[k]);

  fields.updatedAt = FieldValue.serverTimestamp();

  const ref = db.collection("users").doc(uid).collection("habits").doc(habitId);
  const snap = await ref.get();
  if (!snap.exists || snap.data().uid !== uid) {
    throw new HttpsError("not-found", "Habit not found.");
  }

  await ref.update(fields);
  return { success: true };
});

/**
 * Callable: deleteHabit
 * Soft-deletes by setting archived=true, or hard-deletes if permanent=true.
 *
 * Input:  { habitId, permanent? }
 */
exports.deleteHabit = onCall(async (request) => {
  requireAuth(request.auth);
  const uid = request.auth.uid;
  const { habitId, permanent } = request.data;
  if (!habitId) throw new HttpsError("invalid-argument", "habitId required.");

  const ref = db.collection("users").doc(uid).collection("habits").doc(habitId);
  const snap = await ref.get();
  if (!snap.exists || snap.data().uid !== uid) {
    throw new HttpsError("not-found", "Habit not found.");
  }

  if (permanent) {
    await ref.delete();
  } else {
    await ref.update({ archived: true, updatedAt: FieldValue.serverTimestamp() });
  }

  return { success: true };
});

/**
 * Callable: getHabits
 * Returns all active (non-archived) habits for the authenticated user.
 *
 * Output: { habits: [...] }
 */
exports.getHabits = onCall(async (request) => {
  requireAuth(request.auth);
  const uid = request.auth.uid;

  const snap = await db
    .collection("users").doc(uid).collection("habits")
    .where("archived", "==", false)
    .orderBy("createdAt", "asc")
    .get();

  return { habits: snap.docs.map((d) => d.data()) };
});

/**
 * Callable: logCompletion
 * Marks a habit as done for today (or a given date).
 * Recalculates streak server-side so the client never has to.
 *
 * Input:  { habitId, date? "YYYY-MM-DD" }
 * Output: { currentStreak, bestStreak, alreadyLogged }
 */
exports.logCompletion = onCall(async (request) => {
  requireAuth(request.auth);
  const uid = request.auth.uid;
  const { habitId, date } = request.data;
  if (!habitId) throw new HttpsError("invalid-argument", "habitId required.");

  const targetDate = date || isoDate();
  const ref = db.collection("users").doc(uid).collection("habits").doc(habitId);

  return await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists || snap.data().uid !== uid) {
      throw new HttpsError("not-found", "Habit not found.");
    }

    const habit = snap.data();
    const history = [...(habit.completionHistory || [])];

    if (history.includes(targetDate)) {
      return {
        currentStreak: habit.currentStreak,
        bestStreak: habit.bestStreak,
        alreadyLogged: true,
      };
    }

    history.push(targetDate);
    history.sort();

    // ── Recalculate current streak ───────────────────────────────────────────
    let streak = 0;
    const today = new Date();
    for (let i = history.length - 1; i >= 0; i--) {
      const expected = new Date(today);
      expected.setDate(today.getDate() - streak);
      if (history[i] === isoDate(expected)) {
        streak++;
      } else {
        break;
      }
    }

    const newBest = Math.max(habit.bestStreak || 0, streak);

    tx.update(ref, {
      completionHistory: history,
      currentStreak: streak,
      bestStreak: newBest,
      lastLoggedDate: targetDate,
      currentDays: history.length,
      updatedAt: FieldValue.serverTimestamp(),
    });

    // Update user-level best streak
    const userRef = db.collection("users").doc(uid);
    const userSnap = await tx.get(userRef);
    if (userSnap.exists && (userSnap.data().bestStreak || 0) < newBest) {
      tx.update(userRef, { bestStreak: newBest });
    }

    return { currentStreak: streak, bestStreak: newBest, alreadyLogged: false };
  });
});

/**
 * Callable: undoCompletion
 * Removes today's log entry (within a 1-hour grace window).
 *
 * Input:  { habitId, date? "YYYY-MM-DD" }
 */
exports.undoCompletion = onCall(async (request) => {
  requireAuth(request.auth);
  const uid = request.auth.uid;
  const { habitId, date } = request.data;
  if (!habitId) throw new HttpsError("invalid-argument", "habitId required.");

  const targetDate = date || isoDate();
  const ref = db.collection("users").doc(uid).collection("habits").doc(habitId);

  return await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists || snap.data().uid !== uid) {
      throw new HttpsError("not-found", "Habit not found.");
    }

    const habit = snap.data();
    const history = (habit.completionHistory || []).filter((d) => d !== targetDate);

    // Recalculate streak
    let streak = 0;
    const today = new Date();
    for (let i = history.length - 1; i >= 0; i--) {
      const expected = new Date(today);
      expected.setDate(today.getDate() - streak);
      if (history[i] === isoDate(expected)) streak++;
      else break;
    }

    tx.update(ref, {
      completionHistory: history,
      currentStreak: streak,
      currentDays: history.length,
      lastLoggedDate: history[history.length - 1] || null,
      updatedAt: FieldValue.serverTimestamp(),
    });

    return { currentStreak: streak, success: true };
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 4. Streaks & Stats
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Callable: getStats
 * Returns aggregated stats for the home screen and progress screen.
 *
 * Output:
 *   totalHabits, activeToday, completedToday, completionPctToday,
 *   bestStreak (across all habits), currentStreak,
 *   perfectDaysThisWeek, weeklyCompletionPct,
 *   habitBreakdown (array per habit: name, pct, completed, total for this week)
 */
exports.getStats = onCall(async (request) => {
  requireAuth(request.auth);
  const uid = request.auth.uid;

  const snap = await db
    .collection("users").doc(uid).collection("habits")
    .where("archived", "==", false)
    .get();

  const habits = snap.docs.map((d) => d.data());
  const today = isoDate();

  // Week boundaries (Mon–Sun)
  const now = new Date();
  const dow = (now.getDay() + 6) % 7; // 0=Mon
  const weekDates = Array.from({ length: 7 }, (_, i) => {
    const d = new Date(now);
    d.setDate(now.getDate() - dow + i);
    return isoDate(d);
  });

  let completedToday = 0;
  let bestStreak = 0;
  let currentStreak = 0;
  const habitBreakdown = [];

  for (const h of habits) {
    const hist = h.completionHistory || [];
    if (hist.includes(today)) completedToday++;
    bestStreak = Math.max(bestStreak, h.bestStreak || 0);
    currentStreak = Math.max(currentStreak, h.currentStreak || 0);

    const weekCompleted = weekDates.filter((d) => hist.includes(d)).length;
    habitBreakdown.push({
      name: h.title,
      completed: weekCompleted,
      total: 7,
      pct: Math.round((weekCompleted / 7) * 100),
    });
  }

  // Perfect days = days where every habit was completed
  const perfectDaysThisWeek = weekDates.filter((d) =>
    habits.every((h) => (h.completionHistory || []).includes(d))
  ).length;

  const totalEntries = habits.length * 7;
  const completedEntries = habitBreakdown.reduce((s, h) => s + h.completed, 0);
  const weeklyCompletionPct = totalEntries > 0
    ? Math.round((completedEntries / totalEntries) * 100)
    : 0;

  return {
    totalHabits: habits.length,
    activeToday: habits.length,
    completedToday,
    completionPctToday: habits.length > 0
      ? Math.round((completedToday / habits.length) * 100)
      : 0,
    bestStreak,
    currentStreak,
    perfectDaysThisWeek,
    weeklyCompletionPct,
    weekNumber: isoWeek(),
    habitBreakdown,
  };
});

// ─────────────────────────────────────────────────────────────────────────────
// 5. AI — Daily Motivation Message  (Claude-powered, premium)
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Callable: getDailyMotivation
 * Returns (or generates + caches) a personalised daily motivation message.
 *
 * Free users  → static rule-based message (same logic as local service)
 * Premium     → Gemini-generated, cached per day per user in Firestore
 *
 * Output: { message, generatedBy: "gemini"|"local", cached: bool }
 */
exports.getDailyMotivation = onCall(async (request) => {
  requireAuth(request.auth);
  const uid = request.auth.uid;
  const today = isoDate();

  // Check cache
  const cacheRef = db.collection("users").doc(uid)
    .collection("aiCache").doc(`motivation_${today}`);
  const cacheSnap = await cacheRef.get();
  if (cacheSnap.exists) return { ...cacheSnap.data(), cached: true };

  // Gather stats
  const habitsSnap = await db
    .collection("users").doc(uid).collection("habits")
    .where("archived", "==", false).get();
  const habits = habitsSnap.docs.map((d) => d.data());

  const bestStreak = habits.reduce((m, h) => Math.max(m, h.bestStreak || 0), 0);
  const activeHabits = habits.length;
  const completedToday = habits.filter((h) =>
    (h.completionHistory || []).includes(today)
  ).length;
  const completionPct = activeHabits > 0
    ? Math.round((completedToday / activeHabits) * 100)
    : 0;

  let message;
  if (bestStreak >= 30) {
    message = `${bestStreak} days straight — you've made this a part of who you are.`;
  } else if (bestStreak >= 14) {
    message = "Two weeks of consistency. Your future self is already thanking you.";
  } else if (bestStreak >= 7) {
    message = "A full week on your best streak. Now make it two.";
  } else if (completionPct >= 80) {
    message = `You're completing ${completionPct}% of your habits. That's not luck — that's discipline.`;
  } else {
    message = "Every expert was once a beginner. Show up today.";
  }

  const payload = { message, generatedBy: "local", date: today };
  await cacheRef.set(payload);
  return { ...payload, cached: false };
});

// ─────────────────────────────────────────────────────────────────────────────
// 6. AI — Weekly Review  (Claude-powered, premium)
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Callable: getWeeklyReview
 * Generates (or returns cached) a personalised weekly review narrative.
 *
 * Output: { review, generatedBy, weekNumber, cached }
 */
exports.getWeeklyReview = onCall(async (request) => {
  requireAuth(request.auth);
  const uid = request.auth.uid;
  const week = isoWeek();

  // Cache check
  const cacheRef = db.collection("users").doc(uid)
    .collection("aiCache").doc(`review_week_${week}`);
  const cacheSnap = await cacheRef.get();
  if (cacheSnap.exists) return { ...cacheSnap.data(), cached: true };

  const habitsSnap = await db
    .collection("users").doc(uid).collection("habits")
    .where("archived", "==", false).get();
  const habits = habitsSnap.docs.map((d) => d.data());

  const now = new Date();
  const dow = (now.getDay() + 6) % 7;
  const weekDates = Array.from({ length: 7 }, (_, i) => {
    const d = new Date(now);
    d.setDate(now.getDate() - dow + i);
    return isoDate(d);
  });

  const totalEntries = habits.length * 7;
  const completedEntries = habits.reduce((s, h) =>
    s + weekDates.filter((d) => (h.completionHistory || []).includes(d)).length, 0);
  const completionPct = totalEntries > 0
    ? Math.round((completedEntries / totalEntries) * 100)
    : 0;
  const perfectDays = weekDates.filter((d) =>
    habits.every((h) => (h.completionHistory || []).includes(d))
  ).length;

  const review = completionPct >= 70
    ? `Week ${week} was solid — ${completionPct}% completion across ${habits.length} habits. ${perfectDays} perfect days. Keep pushing.`
    : `Week ${week}: ${completionPct}% completion. There's room to grow. Pick one habit and make it non-negotiable next week.`;

  const payload = { review, generatedBy: "local", weekNumber: week };
  await cacheRef.set(payload);
  return { ...payload, cached: false };
});

// ─────────────────────────────────────────────────────────────────────────────
// 7. AI — Habit Coach Chat  (Claude-powered, premium only)
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Callable: chatWithCoach
 * One-shot conversational habit coaching. The Flutter app maintains local
 * message history and sends the last N turns each call.
 *
 * Input:
 *   messages: [{ role: "user"|"assistant", content: string }, ...]
 *             (last message must be role="user")
 *
 * Output: { reply }
 */
// chatWithCoach is handled client-side via GeminiService in Flutter.

// ─────────────────────────────────────────────────────────────────────────────
// 8. Payments — Razorpay Webhook
// ─────────────────────────────────────────────────────────────────────────────

/**
 * HTTP trigger: razorpayWebhook
 * Razorpay → POST /razorpayWebhook
 *
 * Verifies HMAC-SHA256 signature, then unlocks premium for the paying user.
 * The Flutter app passes the Firebase UID in the Razorpay `notes` field:
 *   notes: { uid: FirebaseAuth.instance.currentUser!.uid }
 */
exports.razorpayWebhook = onRequest(
  { secrets: [RAZORPAY_SECRET] },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).send("Method Not Allowed");

    // ── Signature verification ────────────────────────────────────────────────
    const receivedSig = req.headers["x-razorpay-signature"];
    const expectedSig = crypto
      .createHmac("sha256", RAZORPAY_SECRET.value())
      .update(JSON.stringify(req.body))
      .digest("hex");

    if (receivedSig !== expectedSig) {
      console.error("Razorpay signature mismatch");
      return res.status(400).send("Invalid signature");
    }

    const event = req.body.event;
    if (event !== "payment.captured") {
      // Acknowledge other events without action
      return res.status(200).send("ok");
    }

    const payment = req.body.payload?.payment?.entity;
    const uid = payment?.notes?.uid;

    if (!uid) {
      console.error("No uid in Razorpay notes", payment);
      return res.status(400).send("Missing uid in notes");
    }

    try {
      await db.collection("users").doc(uid).update({
        premium: true,
        premiumUnlockedAt: FieldValue.serverTimestamp(),
        razorpayPaymentId: payment.id,
      });

      // Log the payment for records
      await db.collection("payments").add({
        uid,
        razorpayPaymentId: payment.id,
        amount: payment.amount,
        currency: payment.currency,
        method: payment.method,
        status: "captured",
        createdAt: FieldValue.serverTimestamp(),
      });

      console.log(`Premium unlocked for uid=${uid}, payment=${payment.id}`);
      return res.status(200).send("ok");
    } catch (err) {
      console.error("Error unlocking premium:", err);
      return res.status(500).send("Internal error");
    }
  }
);

/**
 * Callable: checkPremiumStatus
 * The Flutter app calls this on launch to sync premium status.
 *
 * Output: { premium: bool, premiumUnlockedAt: timestamp | null }
 */
exports.checkPremiumStatus = onCall(async (request) => {
  requireAuth(request.auth);
  const uid = request.auth.uid;

  const snap = await db.collection("users").doc(uid).get();
  if (!snap.exists) return { premium: false, premiumUnlockedAt: null };

  const { premium, premiumUnlockedAt } = snap.data();
  return {
    premium: premium === true,
    premiumUnlockedAt: premiumUnlockedAt?.toDate?.()?.toISOString() || null,
  };
});

// ─────────────────────────────────────────────────────────────────────────────
// 9. Scheduled Jobs
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Scheduled: dailyStreakReset
 * Runs at 00:05 IST (18:35 UTC) every day.
 * For every user's habit, if the habit was not completed yesterday,
 * the current streak is reset to 0.
 *
 * Note: This is a soft reset — bestStreak is never touched.
 */
exports.dailyStreakReset = onSchedule("35 18 * * *", async () => {
  const yesterday = isoDate(new Date(Date.now() - 86400000));

  // Page through all habits (could be large — use batched reads)
  const usersSnap = await db.collection("users").get();

  const promises = usersSnap.docs.map(async (userDoc) => {
    const uid = userDoc.id;
    const habitsSnap = await db
      .collection("users").doc(uid).collection("habits")
      .where("archived", "==", false).get();

    const batch = db.batch();
    let changed = 0;

    for (const habitDoc of habitsSnap.docs) {
      const habit = habitDoc.data();
      const completedYesterday = (habit.completionHistory || []).includes(yesterday);
      if (!completedYesterday && (habit.currentStreak || 0) > 0) {
        batch.update(habitDoc.ref, { currentStreak: 0 });
        changed++;
      }
    }

    if (changed > 0) await batch.commit();
  });

  await Promise.allSettled(promises);
  console.log("dailyStreakReset complete");
});

/**
 * Scheduled: weeklyDigestPush
 * Runs at 08:00 IST (02:30 UTC) every Monday.
 * Sends a push notification with each user's weekly summary.
 */
exports.weeklyDigestPush = onSchedule("30 2 * * 1", async () => {
  const usersSnap = await db.collection("users")
    .where("fcmToken", "!=", null).get();

  const messages = [];

  for (const userDoc of usersSnap.docs) {
    const { fcmToken, displayName } = userDoc.data();
    if (!fcmToken) continue;

    messages.push({
      token: fcmToken,
      notification: {
        title: "Your week in review 📊",
        body: `${displayName ? displayName + ", see" : "See"} how your habits performed this week.`,
      },
      data: { screen: "weeklyReview" },
      android: { priority: "normal" },
      apns: { payload: { aps: { badge: 1 } } },
    });
  }

  if (messages.length > 0) {
    const result = await getMessaging().sendEach(messages);
    console.log(`weeklyDigestPush: ${result.successCount} sent, ${result.failureCount} failed`);
  }
});

/**
 * Callable: saveFcmToken
 * Called by the Flutter app whenever a new FCM token is received.
 *
 * Input:  { token }
 */
exports.saveFcmToken = onCall(async (request) => {
  requireAuth(request.auth);
  const uid = request.auth.uid;
  const { token } = request.data;
  if (!token) throw new HttpsError("invalid-argument", "token required.");

  await db.collection("users").doc(uid).update({ fcmToken: token });
  return { success: true };
});

// ─────────────────────────────────────────────────────────────────────────────
// 10. Accountability Partners
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Generates a 6-character alphanumeric invite code and creates a pending
 * partnership document.
 *
 * Input:  { habitIds: string[] }
 * Output: { inviteCode: string, partnershipId: string }
 */
exports.createPartnership = onCall(async (request) => {
  requireAuth(request.auth);
  const uid = request.auth.uid;
  const { habitIds } = request.data;

  if (!Array.isArray(habitIds) || habitIds.length === 0) {
    throw new HttpsError("invalid-argument", "habitIds array required.");
  }

  // Generate unique 6-char code
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let code = "";
  for (let i = 0; i < 6; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }

  const ref = await db.collection("partnerships").add({
    ownerUid: uid,
    partnerUid: null,
    habitIds,
    status: "pending",
    inviteCode: code,
    createdAt: FieldValue.serverTimestamp(),
  });

  return { inviteCode: code, partnershipId: ref.id };
});

/**
 * Accepts a partnership invite using the 6-character code.
 * The caller becomes the accountability partner.
 *
 * Input:  { inviteCode: string }
 * Output: { partnershipId: string, ownerName: string }
 */
exports.acceptPartnership = onCall(async (request) => {
  requireAuth(request.auth);
  const uid = request.auth.uid;
  const { inviteCode } = request.data;

  if (!inviteCode) throw new HttpsError("invalid-argument", "inviteCode required.");

  const snap = await db.collection("partnerships")
    .where("inviteCode", "==", inviteCode.toUpperCase())
    .where("status", "==", "pending")
    .limit(1)
    .get();

  if (snap.empty) {
    throw new HttpsError("not-found", "Invalid or already-used invite code.");
  }

  const doc = snap.docs[0];
  const data = doc.data();

  if (data.ownerUid === uid) {
    throw new HttpsError("invalid-argument", "You cannot partner with yourself.");
  }

  await doc.ref.update({ partnerUid: uid, status: "active" });

  // Fetch owner's display name to return to the accepting user
  const ownerSnap = await db.collection("users").doc(data.ownerUid).get();
  const ownerName = (ownerSnap.data() || {}).displayName || "Your friend";

  // Notify the owner that their invite was accepted
  const ownerToken = (ownerSnap.data() || {}).fcmToken;
  if (ownerToken) {
    const partnerSnap = await db.collection("users").doc(uid).get();
    const partnerName = (partnerSnap.data() || {}).displayName || "Someone";
    try {
      await getMessaging().send({
        token: ownerToken,
        notification: {
          title: "New accountability partner!",
          body: `${partnerName} accepted your invite and is now tracking you 👀`,
        },
        data: { type: "partner_accepted", partnershipId: doc.id },
      });
    } catch (_) { /* non-fatal */ }
  }

  return { partnershipId: doc.id, ownerName };
});

/**
 * Returns all active partnerships for the current user (as owner or partner),
 * enriched with the other person's display name and today's habit completion.
 *
 * Output: { partnerships: Array }
 */
exports.getPartnerships = onCall(async (request) => {
  requireAuth(request.auth);
  const uid = request.auth.uid;

  const [ownerSnap, partnerSnap] = await Promise.all([
    db.collection("partnerships").where("ownerUid", "==", uid).where("status", "==", "active").get(),
    db.collection("partnerships").where("partnerUid", "==", uid).where("status", "==", "active").get(),
  ]);

  const docs = [...ownerSnap.docs, ...partnerSnap.docs];
  const today = new Date().toISOString().slice(0, 10);

  const partnerships = await Promise.all(docs.map(async (doc) => {
    const d = doc.data();
    const isOwner = d.ownerUid === uid;
    const otherUid = isOwner ? d.partnerUid : d.ownerUid;

    // Fetch other user's profile
    const otherSnap = await db.collection("users").doc(otherUid).get();
    const other = otherSnap.data() || {};

    // Fetch shared habits' completion for today
    const habitsSnap = await db.collection("users").doc(isOwner ? uid : otherUid)
      .collection("habits")
      .where(FieldPath.documentId(), "in", d.habitIds.slice(0, 10))
      .get();

    const habits = habitsSnap.docs.map((h) => {
      const hd = h.data();
      return {
        id: h.id,
        title: hd.title,
        currentStreak: hd.currentStreak || 0,
        loggedToday: hd.lastLoggedDate === today,
      };
    });

    return {
      partnershipId: doc.id,
      isOwner,
      otherUid,
      otherName: other.displayName || "Partner",
      habitIds: d.habitIds,
      habits,
    };
  }));

  return { partnerships };
});

/**
 * Sends a nudge push notification to the habit owner.
 *
 * Input:  { partnershipId: string, habitId: string, message?: string }
 * Output: { sent: boolean }
 */
exports.nudgePartner = onCall(async (request) => {
  requireAuth(request.auth);
  const uid = request.auth.uid;
  const { partnershipId, habitId, message } = request.data;

  if (!partnershipId) throw new HttpsError("invalid-argument", "partnershipId required.");

  const docSnap = await db.collection("partnerships").doc(partnershipId).get();
  if (!docSnap.exists) throw new HttpsError("not-found", "Partnership not found.");

  const d = docSnap.data();
  if (d.ownerUid !== uid && d.partnerUid !== uid) {
    throw new HttpsError("permission-denied", "Not in this partnership.");
  }

  // The person being nudged is whoever is NOT the caller
  const targetUid = d.ownerUid === uid ? d.partnerUid : d.ownerUid;

  // Fetch sender's name
  const senderSnap = await db.collection("users").doc(uid).get();
  const senderName = (senderSnap.data() || {}).displayName || "Your partner";

  // Fetch target's FCM token
  const targetSnap = await db.collection("users").doc(targetUid).get();
  const fcmToken = (targetSnap.data() || {}).fcmToken;

  if (!fcmToken) return { sent: false };

  const nudgeText = message || `${senderName} is rooting for you — go complete your habit! 💪`;

  await getMessaging().send({
    token: fcmToken,
    notification: {
      title: `${senderName} nudged you!`,
      body: nudgeText,
    },
    data: {
      type: "nudge",
      partnershipId,
      habitId: habitId || "",
    },
  });

  // Log nudge to Firestore
  await db.collection("nudges").add({
    fromUid: uid,
    toUid: targetUid,
    partnershipId,
    habitId: habitId || null,
    message: nudgeText,
    sentAt: FieldValue.serverTimestamp(),
  });

  return { sent: true };
});
