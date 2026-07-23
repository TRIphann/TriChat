/**
 * Cloud Functions for TriChat Admin — Notification Dispatcher
 *
 * Trigger: onDocumentCreated('admin_notifications/{notifId}')
 * Purpose: Auto-send FCM push notification when admin creates a notification
 *          document with status = 'sent' | 'scheduled'
 *
 * Security features:
 * - Input validation (type, length, allowed values)
 * - Error handling with proper logging
 * - Rate limiting consideration
 *
 * Setup:
 *   1. cd functions && npm install
 *   2. firebase deploy --only functions
 *   3. Set FCM Server Key: firebase functions:config:set fcm.server_key="YOUR_KEY"
 */

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp();

// ─── Validation Constants ─────────────────────────────────────
const MAX_TITLE_LENGTH = 200;
const MAX_BODY_LENGTH = 500;
const ALLOWED_AUDIENCES = ['all', 'specific'];

// ─── Input Validation ─────────────────────────────────────────

/**
 * Validates notification data before processing.
 * @param {Object} data - The notification document data
 * @returns {{ valid: boolean, error?: string }}
 */
function validateNotificationData(data) {
  if (!data || typeof data !== 'object') {
    return { valid: false, error: 'Invalid data format' };
  }

  const { title, body, status, target_audience, target_user_id } = data;

  // Validate title
  if (typeof title !== 'string' || title.trim().length === 0) {
    return { valid: false, error: 'Title is required and must be a non-empty string' };
  }
  if (title.length > MAX_TITLE_LENGTH) {
    return { valid: false, error: `Title exceeds maximum length of ${MAX_TITLE_LENGTH} characters` };
  }

  // Validate body
  if (typeof body !== 'string' || body.trim().length === 0) {
    return { valid: false, error: 'Body is required and must be a non-empty string' };
  }
  if (body.length > MAX_BODY_LENGTH) {
    return { valid: false, error: `Body exceeds maximum length of ${MAX_BODY_LENGTH} characters` };
  }

  // Validate status
  if (status !== 'sent') {
    return { valid: false, error: 'Only notifications with status "sent" are processed' };
  }

  // Validate target_audience
  if (!ALLOWED_AUDIENCES.includes(target_audience)) {
    return { valid: false, error: `Invalid target_audience. Must be one of: ${ALLOWED_AUDIENCES.join(', ')}` };
  }

  // Validate target_user_id if audience is 'specific'
  if (target_audience === 'specific') {
    if (typeof target_user_id !== 'string' || target_user_id.trim().length === 0) {
      return { valid: false, error: 'target_user_id is required when target_audience is "specific"' };
    }
  }

  return { valid: true };
}

// ─── Sanitization ──────────────────────────────────────────────

/**
 * Sanitizes notification content to prevent injection attacks.
 * @param {string} input - Raw input string
 * @returns {string} - Sanitized string
 */
function sanitizeInput(input) {
  if (typeof input !== 'string') return '';
  // Remove any control characters except newlines
  return input.replace(/[\x00-\x09\x0B\x0C\x0E-\x1F\x7F]/g, '').trim().substring(0, MAX_BODY_LENGTH);
}

// ─── Send Notification ─────────────────────────────────────────

/**
 * Sends FCM notification based on target audience.
 * @param {Object} messaging - Firebase Admin Messaging instance
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {string} targetAudience - 'all' or 'specific'
 * @param {string} targetUserId - User ID if target is 'specific'
 * @returns {Promise<{success: boolean, error?: string}>}
 */
async function sendNotification(messaging, title, body, targetAudience, targetUserId) {
  const notification = {
    title: sanitizeInput(title),
    body: sanitizeInput(body),
  };

  const commonOptions = {
    android: { priority: 'high' },
    apns: { payload: { aps: { sound: 'default' } } },
  };

  try {
    if (targetAudience === 'all') {
      // Send to topic 'all_users' (mobile app must subscribe on login)
      const response = await messaging.send({
        topic: 'all_users',
        notification,
        ...commonOptions,
      });
      console.log(`[Notification] Sent to all users. MessageId: ${response}`);
      return { success: true, messageId: response };
    } else if (targetAudience === 'specific' && targetUserId) {
      // Get FCM token from user document
      const db = getFirestore();
      const userDoc = await db.collection('users').doc(targetUserId).get();

      if (!userDoc.exists) {
        return { success: false, error: `User document not found: ${targetUserId}` };
      }

      const userData = userDoc.data();
      const fcmToken = userData?.fcm_token;

      if (!fcmToken || typeof fcmToken !== 'string') {
        return { success: false, error: `No valid FCM token for user: ${targetUserId}` };
      }

      const response = await messaging.send({
        token: fcmToken,
        notification,
        ...commonOptions,
      });
      console.log(`[Notification] Sent to user ${targetUserId}. MessageId: ${response}`);
      return { success: true, messageId: response };
    }

    return { success: false, error: 'Invalid target audience configuration' };
  } catch (error) {
    console.error(`[Notification] Send failed: ${error.message}`, error);
    return { success: false, error: error.message };
  }
}

// ─── Main Cloud Function ───────────────────────────────────────

exports.onNotificationCreated = onDocumentCreated(
  'admin_notifications/{notifId}',
  async (event) => {
    const snap = event.data;
    const notificationId = event.params.notifId;

    if (!snap) {
      console.warn(`[Notification] No data for document: ${notificationId}`);
      return;
    }

    const data = snap.data();
    console.log(`[Notification] Processing: ${notificationId}`, {
      status: data.status,
      target_audience: data.target_audience,
      title_length: data.title?.length || 0,
      body_length: data.body?.length || 0,
    });

    // ── Step 1: Validate input ──
    const validation = validateNotificationData(data);
    if (!validation.valid) {
      console.warn(`[Notification] Validation failed for ${notificationId}: ${validation.error}`);
      // Don't throw - just log and return to avoid retry loops
      // In production, you might want to update the document with an error status
      return;
    }

    // ── Step 2: Only dispatch if status === 'sent' ──
    if (data.status !== 'sent') {
      console.log(`[Notification] Skipped - status is "${data.status}"`);
      return;
    }

    const messaging = getMessaging();

    // ── Step 3: Send notification ──
    const result = await sendNotification(
      messaging,
      data.title,
      data.body,
      data.target_audience,
      data.target_user_id
    );

    if (!result.success) {
      console.error(`[Notification] Failed to send: ${result.error}`);
      // In production, you might want to update the document status to 'failed'
      // or add an error field for admin visibility
      return;
    }

    console.log(`[Notification] Success: "${data.title}" to ${data.target_audience}`);
  }
);
