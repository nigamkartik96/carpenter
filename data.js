// Mock data layer — simulates Firestore collections in localStorage
const DB_KEY = 'carpenter_app_db_v1';

function seedDB() {
  return {
    currentUser: null, // { id, role: 'carpenter'|'admin' }
    carpenters: [
      { id: 'c1', name: 'Ramesh Yadav', mobile: '9876543210', password: '1234', shop: 'Yadav Woodworks', address: 'Pune, MH', photo: '🧑‍🔧', status: 'Approved', points: 320, lifetimePoints: 870, redeemedPoints: 550, rank: 1 },
      { id: 'c2', name: 'Suresh Patil', mobile: '9876500000', password: '1234', shop: 'Patil Interiors', address: 'Nashik, MH', photo: '🧑‍🔧', status: 'Approved', points: 210, lifetimePoints: 410, redeemedPoints: 200, rank: 2 },
      { id: 'c3', name: 'Vikram Singh', mobile: '9876511111', password: '1234', shop: 'Singh Furniture', address: 'Nagpur, MH', photo: '🧑‍🔧', status: 'Pending', points: 0, lifetimePoints: 0, redeemedPoints: 0, rank: 3 },
    ],
    admin: { email: 'admin@carpenter.com', password: 'admin123' },
    offers: [
      { id: 'o1', title: 'Monsoon Plywood Bonanza', description: 'Extra 5% points on all plywood orders this week.', category: 'Weekly', start: '2026-06-16', end: '2026-06-22', banner: '🌧️' },
      { id: 'o2', title: 'Today Only: Hardware Fittings Offer', description: 'Flat 10% bonus points on hardware fittings.', category: 'Today', start: '2026-06-21', end: '2026-06-21', banner: '🔧' },
    ],
    orders: [
      { id: 'ord1001', carpenterId: 'c1', type: 'Manual', product: 'Plywood 19mm', qty: 12, status: 'Fulfilled', date: '2026-06-15', pointsEarned: 50 },
      { id: 'ord1002', carpenterId: 'c1', type: 'Photo', remarks: 'Modular kitchen panels', status: 'Processing', date: '2026-06-19', pointsEarned: 0 },
      { id: 'ord1003', carpenterId: 'c2', type: 'Voice', remarks: 'Order for door frames', status: 'Submitted', date: '2026-06-20', pointsEarned: 0 },
    ],
    invoices: [
      { id: 'inv1', carpenterId: 'c1', number: 'INV-2026-001', date: '2026-06-15', amount: 5000 },
    ],
    pointsLedger: [
      { id: 'pl1', carpenterId: 'c1', type: 'Earned', desc: 'Order #ord1001', points: 50, date: '2026-06-15' },
      { id: 'pl2', carpenterId: 'c1', type: 'Manual', desc: 'Weekly Bonus', points: 100, date: '2026-06-17' },
      { id: 'pl3', carpenterId: 'c1', type: 'Redeemed', desc: 'Gift Redemption — Tool Kit', points: -500, date: '2026-06-18' },
    ],
    gifts: [
      { id: 'g1', name: 'Premium Tool Kit', desc: '24-piece carpenter tool kit', points: 500, qty: 8, image: '🧰' },
      { id: 'g2', name: 'Mixer Grinder', desc: '750W mixer grinder', points: 800, qty: 4, image: '🍹' },
      { id: 'g3', name: 'Smart Watch', desc: 'Fitness smart watch', points: 600, qty: 6, image: '⌚' },
      { id: 'g4', name: 'Cash Redemption ₹1000', desc: 'Direct bank/UPI transfer', points: 1000, qty: 20, image: '💵' },
    ],
    giftRedemptions: [
      { id: 'gr1', carpenterId: 'c1', giftId: 'g1', date: '2026-06-18', points: 500, status: 'Dispatched' },
    ],
    leads: [
      { id: 'ld1', carpenterId: 'c1', customerName: 'Anjali Sharma', phone: '9123456780', location: 'Pune', notes: 'Need modular kitchen work.', status: 'Contacted', date: '2026-06-14' },
    ],
    notifications: [
      { id: 'n1', carpenterId: 'c1', title: 'Points Credited', body: '+50 points for Order #ord1001', date: '2026-06-15', read: false },
      { id: 'n2', carpenterId: 'c1', title: 'New Offer', body: 'Monsoon Plywood Bonanza is live!', date: '2026-06-16', read: true },
    ],
    payoutDetails: {
      c1: { accountHolder: 'Ramesh Yadav', accountNumber: '1234567890', ifsc: 'HDFC0001234', upi: 'ramesh@upi' },
    },
    pointRule: { amount: 100, points: 1 }, // 1 point per ₹100
  };
}

function loadDB() {
  const raw = localStorage.getItem(DB_KEY);
  if (!raw) {
    const fresh = seedDB();
    localStorage.setItem(DB_KEY, JSON.stringify(fresh));
    return fresh;
  }
  return JSON.parse(raw);
}

function saveDB(db) {
  localStorage.setItem(DB_KEY, JSON.stringify(db));
}

function resetDB() {
  const fresh = seedDB();
  localStorage.setItem(DB_KEY, JSON.stringify(fresh));
  return fresh;
}
