const fs = require("fs");
const path = require("path");

const DB_PATH = path.join(__dirname, "..", "..", "orders.json");

function load() {
  if (!fs.existsSync(DB_PATH)) return {};
  return JSON.parse(fs.readFileSync(DB_PATH, "utf8"));
}

function save(orders) {
  fs.writeFileSync(DB_PATH, JSON.stringify(orders, null, 2));
}

function createOrder(orderId, data) {
  const orders = load();
  orders[orderId] = { orderId, createdAt: Date.now(), ...data };
  save(orders);
  return orders[orderId];
}

function getOrder(orderId) {
  return load()[orderId];
}

function updateOrder(orderId, patch) {
  const orders = load();
  if (!orders[orderId]) return null;
  orders[orderId] = { ...orders[orderId], ...patch };
  save(orders);
  return orders[orderId];
}

module.exports = { createOrder, getOrder, updateOrder };
