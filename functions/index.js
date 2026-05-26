const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe')(functions.config().stripe.secret_key);

admin.initializeApp();
const db = admin.firestore();

// ── Create Payment Intent ─────────────────────────────────────────

exports.createPaymentIntent = functions.https.onRequest(async (req, res) => {
  // CORS
  res.set('Access-Control-Allow-Origin', '*');
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    return res.status(204).send('');
  }

  try {
    // Verify Firebase ID token
    const authHeader = req.headers.authorization || '';
    const idToken = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
    if (!idToken) return res.status(401).json({ error: 'Unauthorized' });

    const decoded = await admin.auth().verifyIdToken(idToken);
    const userId = decoded.uid;

    const { amount, currency, orderId } = req.body;
    if (!amount || !currency) {
      return res.status(400).json({ error: 'Missing amount or currency' });
    }

    // Get or create Stripe customer
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.data() || {};
    let customerId = userData.stripeCustomerId;

    if (!customerId) {
      const customer = await stripe.customers.create({
        email: decoded.email,
        metadata: { firebaseUid: userId },
      });
      customerId = customer.id;
      await db.collection('users').doc(userId).update({ stripeCustomerId: customerId });
    }

    // Create payment intent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount),
      currency: currency.toLowerCase(),
      customer: customerId,
      metadata: { orderId, userId },
      automatic_payment_methods: { enabled: true },
    });

    return res.status(200).json({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    });
  } catch (err) {
    console.error('createPaymentIntent error:', err);
    return res.status(500).json({ error: err.message });
  }
});

// ── Stripe Webhook ────────────────────────────────────────────────

exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const webhookSecret = functions.config().stripe.webhook_secret;

  let event;
  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, webhookSecret);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  switch (event.type) {
    case 'payment_intent.succeeded': {
      const pi = event.data.object;
      const orderId = pi.metadata.orderId;
      if (orderId) {
        await db.collection('orders').doc(orderId).update({
          status: 'confirmed',
          stripePaymentIntentId: pi.id,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`Order ${orderId} confirmed`);
      }
      break;
    }
    case 'payment_intent.payment_failed': {
      const pi = event.data.object;
      const orderId = pi.metadata.orderId;
      if (orderId) {
        await db.collection('orders').doc(orderId).update({
          status: 'cancelled',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
      break;
    }
    default:
      console.log(`Unhandled event type: ${event.type}`);
  }

  return res.json({ received: true });
});

// ── Get Payment Methods ───────────────────────────────────────────

exports.getPaymentMethods = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  try {
    const idToken = (req.headers.authorization || '').replace('Bearer ', '');
    const decoded = await admin.auth().verifyIdToken(idToken);

    const userDoc = await db.collection('users').doc(decoded.uid).get();
    const customerId = userDoc.data()?.stripeCustomerId;
    if (!customerId) return res.json({ paymentMethods: [] });

    const methods = await stripe.paymentMethods.list({
      customer: customerId, type: 'card',
    });

    return res.json({
      paymentMethods: methods.data.map(pm => ({
        id: pm.id,
        brand: pm.card.brand,
        last4: pm.card.last4,
        expMonth: pm.card.exp_month,
        expYear: pm.card.exp_year,
      })),
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ── Send Order Confirmation Email (via SendGrid) ──────────────────

exports.onOrderCreated = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snap, context) => {
    const order = snap.data();
    const userId = order.userId;

    const userDoc = await db.collection('users').doc(userId).get();
    const email = userDoc.data()?.email;
    if (!email) return;

    // Send FCM notification
    const tokensDoc = await db.collection('users').doc(userId).get();
    const tokens = tokensDoc.data()?.fcmTokens || [];

    if (tokens.length > 0) {
      await admin.messaging().sendEachForMulticast({
        tokens,
        notification: {
          title: '🎉 Order Confirmed!',
          body: `Your order #${context.params.orderId.substring(0, 8).toUpperCase()} has been placed.`,
        },
        data: {
          type: 'order',
          orderId: context.params.orderId,
        },
      });
    }
  });

// ── Update Order Status (admin) ───────────────────────────────────

exports.onOrderStatusChanged = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (before.status === after.status) return;

    const userDoc = await db.collection('users').doc(after.userId).get();
    const tokens = userDoc.data()?.fcmTokens || [];
    if (tokens.length === 0) return;

    const statusMessages = {
      processing: { title: '📦 Order Processing', body: 'Your order is being prepared.' },
      shipped:    { title: '🚚 Order Shipped!',   body: 'Your order is on its way.' },
      delivered:  { title: '✅ Order Delivered!', body: 'Your order has been delivered. Enjoy!' },
      cancelled:  { title: '❌ Order Cancelled',  body: 'Your order has been cancelled.' },
    };

    const msg = statusMessages[after.status];
    if (!msg) return;

    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: msg,
      data: { type: 'order', orderId: context.params.orderId },
    });
  });
