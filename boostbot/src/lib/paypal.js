const config = require("../config");

const BASE_URL =
  config.paypal.env === "live"
    ? "https://api-m.paypal.com"
    : "https://api-m.sandbox.paypal.com";

async function getAccessToken() {
  const auth = Buffer.from(
    `${config.paypal.clientId}:${config.paypal.clientSecret}`
  ).toString("base64");

  const res = await fetch(`${BASE_URL}/v1/oauth2/token`, {
    method: "POST",
    headers: {
      Authorization: `Basic ${auth}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: "grant_type=client_credentials",
  });

  if (!res.ok) {
    throw new Error(`PayPal auth failed: ${res.status} ${await res.text()}`);
  }
  const data = await res.json();
  return data.access_token;
}

async function paypalFetch(pathname, options = {}) {
  const token = await getAccessToken();
  const res = await fetch(`${BASE_URL}${pathname}`, {
    ...options,
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
      ...options.headers,
    },
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    const err = new Error(`PayPal API error: ${res.status}`);
    err.details = data;
    throw err;
  }
  return data;
}

// Creates a real PayPal order for the given amount and returns the order id
// plus the approval URL the customer must open to pay.
async function createOrder(amountUsd, description) {
  const order = await paypalFetch("/v2/checkout/orders", {
    method: "POST",
    body: JSON.stringify({
      intent: "CAPTURE",
      purchase_units: [
        {
          description,
          amount: { currency_code: "USD", value: amountUsd.toFixed(2) },
        },
      ],
    }),
  });

  const approveLink = order.links.find((l) => l.rel === "approve")?.href;
  return { orderId: order.id, approveLink };
}

// Captures payment after the customer has approved it on PayPal's site.
// Returns null if the order was never approved/captured successfully.
async function captureOrder(orderId) {
  const result = await paypalFetch(
    `/v2/checkout/orders/${orderId}/capture`,
    { method: "POST" }
  );

  const capture = result.purchase_units?.[0]?.payments?.captures?.[0];
  if (result.status !== "COMPLETED" || !capture) return null;

  return { captureId: capture.id, status: capture.status };
}

async function refundCapture(captureId) {
  return paypalFetch(`/v2/payments/captures/${captureId}/refund`, {
    method: "POST",
    body: JSON.stringify({}),
  });
}

module.exports = { createOrder, captureOrder, refundCapture };
