const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

/**
 * Triggered on item creation:
 * Scans opposite item types (e.g. found vs lost) to find potential matches
 * and dispatches match notifications to item reporters.
 */
exports.onItemCreated = functions.firestore
  .document('items/{itemId}')
  .onCreate(async (snap, context) => {
    const newItem = snap.data();
    const itemId = context.params.itemId;
    const targetType = newItem.type === 'lost' ? 'found' : 'lost';

    // Find candidate opposite items in same category
    const querySnapshot = await db.collection('items')
      .where('type', '==', targetType)
      .where('category', '==', newItem.category)
      .where('status', '==', 'active')
      .limit(10)
      .get();

    if (querySnapshot.empty) return null;

    const notifications = [];

    querySnapshot.forEach((doc) => {
      const candidate = doc.data();
      // Token overlap between titles
      const newTokens = new Set(newItem.title.toLowerCase().split(/\s+/));
      const candTokens = new Set(candidate.title.toLowerCase().split(/\s+/));
      const overlap = [...newTokens].filter(t => candTokens.has(t) && t.length > 2);

      if (overlap.length > 0) {
        // Send in-app notification to the opposite item reporter
        const recipientUid = candidate.reportedByUid;
        if (recipientUid && recipientUid !== newItem.reportedByUid) {
          notifications.push(
            db.collection('notifications').add({
              recipientUid,
              title: 'Potential Match Alert',
              body: `A new ${newItem.type} item "${newItem.title}" may match your "${candidate.title}".`,
              itemId: itemId,
              route: `/items/${itemId}`,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              isRead: false,
            })
          );
        }
      }
    });

    return Promise.all(notifications);
  });

/**
 * Triggered when a claim's status is updated (approved / rejected):
 * Dispatches notification to the claimant and ensures the item status matches.
 */
exports.onClaimStatusUpdated = functions.firestore
  .document('claims/{claimId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status === after.status) return null;

    const claimantUid = after.claimantUid;
    const itemId = after.itemId;
    const itemTitle = after.itemTitle;

    // Notify claimant
    await db.collection('notifications').add({
      recipientUid: claimantUid,
      title: `Claim ${after.status.toUpperCase()}`,
      body: `Your ownership claim for "${itemTitle}" has been ${after.status}.`,
      itemId: itemId,
      route: '/activity',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false,
    });

    // If claim was approved, atomically mark the item as returned
    if (after.status === 'approved') {
      await db.collection('items').doc(itemId).update({
        status: 'returned',
        claimedByUid: claimantUid,
        returnedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return null;
  });

/**
 * Callable Function: Submit Claim
 * Validates claimant authorization and enforces that users cannot claim
 * items they reported themselves.
 */
exports.submitClaimSecure = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'You must be signed in to submit an ownership claim.'
    );
  }

  const { itemId, verificationEvidence, claimantContact } = data;
  if (!itemId || !verificationEvidence || verificationEvidence.length < 8) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Please provide comprehensive verification evidence (minimum 8 characters).'
    );
  }

  const itemDoc = await db.collection('items').doc(itemId).get();
  if (!itemDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Item not found.');
  }

  const itemData = itemDoc.data();
  if (itemData.reportedByUid === context.auth.uid) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'You cannot submit an ownership claim on an item you reported yourself.'
    );
  }

  if (itemData.status === 'returned') {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'This item has already been verified and returned to its owner.'
    );
  }

  const claimRef = await db.collection('claims').add({
    itemId,
    itemTitle: itemData.title,
    claimantUid: context.auth.uid,
    claimantEmail: context.auth.token.email || '',
    claimantContact: claimantContact || null,
    verificationEvidence,
    status: 'pending',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await db.collection('items').doc(itemId).update({
    status: 'claimed',
    claimedByUid: context.auth.uid,
  });

  return { claimId: claimRef.id, status: 'pending' };
});
