let db = loadDB();
let state = { screen: 'splash', params: {} };

const root = document.getElementById('app');

function go(screen, params = {}) {
  state = { screen, params };
  render();
}
function back() { history.back(); }

function toast(msg) {
  let t = document.getElementById('toast');
  if (!t) {
    t = document.createElement('div');
    t.id = 'toast';
    t.className = 'toast';
    document.body.appendChild(t);
  }
  t.textContent = msg;
  t.classList.add('show');
  clearTimeout(window._toastTimer);
  window._toastTimer = setTimeout(() => t.classList.remove('show'), 2200);
}

function currentCarpenter() {
  if (!db.currentUser || db.currentUser.role !== 'carpenter') return null;
  return db.carpenters.find(c => c.id === db.currentUser.id);
}

function el(tag, attrs = {}, children = '') {
  const e = document.createElement(tag);
  Object.entries(attrs).forEach(([k, v]) => {
    if (k === 'class') e.className = v;
    else if (k.startsWith('on')) e.addEventListener(k.slice(2).toLowerCase(), v);
    else e.setAttribute(k, v);
  });
  if (Array.isArray(children)) children.forEach(c => e.appendChild(typeof c === 'string' ? document.createTextNode(c) : c));
  else if (children instanceof Node) e.appendChild(children);
  else e.innerHTML = children;
  return e;
}

// ---------- ROLE SWITCHER (dev helper, simulates separate apps) ----------
function renderRoleSwitch() {
  const wrap = el('div', { class: 'role-switch' });
  const carpBtn = el('button', {
    class: db.currentUser?.role === 'carpenter' || state.screen.startsWith('c_') || ['splash','login','register','pending'].includes(state.screen) ? 'active' : '',
    onclick: () => { go('splash'); }
  }, 'Carpenter App');
  const adminBtn = el('button', { onclick: () => go('a_login') }, 'Admin Dashboard');
  const resetBtn = el('button', { onclick: () => { if (confirm('Reset all mock data?')) { db = resetDB(); go('splash'); } } }, '↺ Reset Data');
  wrap.append(carpBtn, adminBtn, resetBtn);
  return wrap;
}

// ===================== CARPENTER APP =====================

function phoneScreen(title, bodyNode, opts = {}) {
  const frame = el('div', { class: 'phone-frame' });
  const top = el('div', { class: 'topbar' });
  if (opts.showBack) {
    top.appendChild(el('button', { class: 'back-btn', onclick: () => go(opts.backTo, opts.backParams || {}) }, '← Back'));
  } else {
    top.appendChild(el('div'));
  }
  top.appendChild(el('h1', {}, title));
  top.appendChild(el('div', {}, opts.right || ''));
  frame.appendChild(top);
  const body = el('div', { class: 'screen-body' }, bodyNode);
  frame.appendChild(body);
  return frame;
}

function screenSplash() {
  const body = el('div', { style: 'text-align:center; padding-top:60px;' });
  body.innerHTML = `
    <div style="font-size:70px;">🪵</div>
    <h1 style="margin:14px 0 4px;">Carpenter Rewards</h1>
    <p class="muted">Orders • Offers • Rewards • Leads</p>
  `;
  const btns = el('div', { style: 'margin-top:40px; display:flex; flex-direction:column; gap:10px;' });
  btns.appendChild(el('button', { class: 'btn', onclick: () => go('login') }, 'Login'));
  btns.appendChild(el('button', { class: 'btn outline', onclick: () => go('register') }, 'New Carpenter? Register'));
  body.appendChild(btns);
  return phoneScreen('', body);
}

function screenLogin() {
  const body = el('div');
  const mobile = el('input', { type: 'tel', placeholder: '9876543210' });
  const pass = el('input', { type: 'password', placeholder: '••••' });
  body.appendChild(el('div', { class: 'field' }, [el('label', {}, 'Mobile Number'), mobile]));
  body.appendChild(el('div', { class: 'field' }, [el('label', {}, 'Password'), pass]));
  body.appendChild(el('button', { class: 'btn', onclick: () => {
    const c = db.carpenters.find(c => c.mobile === mobile.value);
    if (!c || c.password !== pass.value) { toast('Invalid credentials'); return; }
    if (c.status === 'Pending') { go('pending'); return; }
    if (c.status === 'Rejected') { toast('Your application was rejected.'); return; }
    db.currentUser = { id: c.id, role: 'carpenter' };
    saveDB(db);
    go('c_dashboard');
  } }, 'Login'));
  const hint = el('p', { class: 'muted', style: 'margin-top:14px;' }, 'Demo: 9876543210 / 1234 (approved) — 9876511111 / 1234 (pending)');
  body.appendChild(hint);
  return phoneScreen('Login', body, { showBack: true, backTo: 'splash' });
}

function screenRegister() {
  const body = el('div');
  const fields = {};
  const make = (label, type = 'text', placeholder = '') => {
    const input = el('input', { type, placeholder });
    body.appendChild(el('div', { class: 'field' }, [el('label', {}, label), input]));
    return input;
  };
  fields.name = make('Full Name', 'text', 'e.g. Ramesh Yadav');
  fields.mobile = make('Mobile Number', 'tel', '10-digit mobile');
  fields.password = make('Password', 'password', 'Choose a password');
  fields.shop = make('Shop Name', 'text', 'e.g. Yadav Woodworks');
  fields.address = make('Address', 'text', 'Shop / shop area address');
  body.appendChild(el('div', { class: 'field' }, [
    el('label', {}, 'Profile Photo'),
    el('div', { style: 'display:flex;align-items:center;gap:10px;' }, [
      el('div', { class: 'avatar' }, '👤'),
      el('button', { class: 'btn outline small', onclick: () => toast('Photo picker (mock) — using default avatar') }, 'Upload Photo')
    ])
  ]));
  body.appendChild(el('button', { class: 'btn', onclick: () => {
    if (!fields.name.value || !fields.mobile.value || !fields.password.value) { toast('Please fill required fields'); return; }
    const id = 'c' + (db.carpenters.length + 1);
    db.carpenters.push({
      id, name: fields.name.value, mobile: fields.mobile.value, password: fields.password.value,
      shop: fields.shop.value, address: fields.address.value, photo: '🧑‍🔧', status: 'Pending',
      points: 0, lifetimePoints: 0, redeemedPoints: 0, rank: db.carpenters.length + 1,
    });
    saveDB(db);
    toast('Registered! Awaiting admin approval.');
    go('pending');
  } }, 'Register'));
  return phoneScreen('Register', body, { showBack: true, backTo: 'splash' });
}

function screenPending() {
  const body = el('div', { style: 'text-align:center; padding-top:50px;' });
  body.innerHTML = `
    <div style="font-size:60px;">⏳</div>
    <h2>Pending Approval</h2>
    <p class="muted">Your registration is under review. You'll be notified once approved.</p>
  `;
  body.appendChild(el('button', { class: 'btn outline full-mt', onclick: () => go('splash') }, 'Back to Start'));
  return phoneScreen('', body);
}

function screenLocationConsent() {
  const body = el('div', { style: 'text-align:center;' });
  body.innerHTML = `
    <div style="font-size:50px;">📍</div>
    <h3>Location Sharing</h3>
    <p class="muted">"I agree to share my location with the company." We use this to verify on-site visits and improve service.</p>
  `;
  body.appendChild(el('button', { class: 'btn', onclick: () => { toast('Location sharing enabled'); go('c_dashboard'); } }, 'I Agree & Continue'));
  body.appendChild(el('button', { class: 'btn outline full-mt', onclick: () => go('c_dashboard') }, 'Not Now'));
  return phoneScreen('Location Consent', body);
}

function pts(n) { return (n >= 0 ? '+' : '') + n; }

function screenDashboard() {
  const c = currentCarpenter();
  if (!c) { go('login'); return el('div'); }
  const body = el('div');
  const header = el('div', { class: 'dash-header' }, [
    el('div', { class: 'avatar' }, c.photo),
    el('div', {}, [
      el('p', { class: 'welcome-title' }, `Welcome, ${c.name}`),
      el('p', { class: 'welcome-sub' }, `Rank #${c.rank} • ${c.shop}`),
    ])
  ]);
  body.appendChild(header);
  body.appendChild(el('div', { class: 'stat-row' }, [
    el('div', { class: 'stat-box' }, [el('div', { class: 'num' }, String(c.points)), el('div', { class: 'lbl' }, 'Current Points')]),
    el('div', { class: 'stat-box' }, [el('div', { class: 'num' }, String(c.lifetimePoints)), el('div', { class: 'lbl' }, 'Lifetime Points')]),
  ]));
  const menu = [
    ['🌅', "Today's Offers", 'Limited-time deals', () => go('c_offers', { cat: 'Today' })],
    ['📅', 'Weekly Offers', 'This week\'s campaigns', () => go('c_offers', { cat: 'Weekly' })],
    ['🧾', 'Create Order', 'Manual, photo or voice', () => go('c_create_order')],
    ['📦', 'My Orders', 'Track order status', () => go('c_orders')],
    ['🏆', 'Rewards', 'Points, leaderboard & gifts', () => go('c_rewards')],
    ['💡', 'Suggestions / Leads', 'Refer a customer lead', () => go('c_leads')],
    ['🔔', 'Notifications', 'Updates & alerts', () => go('c_notifications')],
    ['👤', 'Profile & Payout', 'Manage account & payout', () => go('c_profile')],
  ];
  menu.forEach(([ic, title, sub, action]) => {
    body.appendChild(el('div', { class: 'menu-card', onclick: action }, [
      el('div', { class: 'ic' }, ic),
      el('div', { class: 'body' }, [el('div', { class: 'title' }, title), el('div', { class: 'sub' }, sub)]),
      el('div', { class: 'chev' }, '›'),
    ]));
  });
  return phoneScreen('Dashboard', body, { right: '🔔' });
}

function screenOffers(params) {
  const cat = params.cat || 'Today';
  const body = el('div');
  body.appendChild(el('div', { class: 'tabs' }, [
    el('div', { class: 'tab' + (cat === 'Today' ? ' active' : ''), onclick: () => go('c_offers', { cat: 'Today' }) }, "Today's"),
    el('div', { class: 'tab' + (cat === 'Weekly' ? ' active' : ''), onclick: () => go('c_offers', { cat: 'Weekly' }) }, 'Weekly'),
  ]));
  const list = db.offers.filter(o => o.category === cat);
  if (!list.length) body.appendChild(el('div', { class: 'empty-state' }, [el('div', { class: 'ic' }, '📭'), el('div', {}, 'No offers right now')]));
  list.forEach(o => {
    body.appendChild(el('div', { class: 'offer-card', onclick: () => go('c_offer_detail', { id: o.id }) }, [
      el('div', { class: 'offer-banner' }, o.banner),
      el('div', { class: 'offer-content' }, [
        el('h3', {}, o.title),
        el('p', {}, o.description),
        el('div', { class: 'offer-dates' }, `${o.start} → ${o.end}`),
      ])
    ]));
  });
  return phoneScreen("Offers", body, { showBack: true, backTo: 'c_dashboard' });
}

function screenOfferDetail(params) {
  const o = db.offers.find(x => x.id === params.id);
  const body = el('div');
  if (!o) { body.appendChild(el('p', {}, 'Offer not found')); }
  else {
    body.appendChild(el('div', { class: 'offer-banner', style: 'border-radius:14px;font-size:60px;' }, o.banner));
    body.appendChild(el('h2', {}, o.title));
    body.appendChild(el('p', {}, o.description));
    body.appendChild(el('p', { class: 'muted' }, `Valid: ${o.start} to ${o.end}`));
    body.appendChild(el('button', { class: 'btn outline full-mt', onclick: () => toast('PDF download (mock)') }, '📄 View Full PDF'));
  }
  return phoneScreen('Offer Details', body, { showBack: true, backTo: 'c_offers' });
}

function screenCreateOrder() {
  const body = el('div', { class: 'grid-3' });
  const types = [
    ['✍️', 'Manual', () => go('c_order_manual')],
    ['📷', 'Photo', () => go('c_order_photo')],
    ['🎙️', 'Voice', () => go('c_order_voice')],
  ];
  types.forEach(([ic, label, action]) => {
    body.appendChild(el('div', { class: 'card order-type-card', onclick: action }, [
      el('div', { class: 'ic' }, ic), el('div', { style: 'font-weight:700;font-size:13px;' }, label)
    ]));
  });
  const wrap = el('div');
  wrap.appendChild(el('p', { class: 'muted' }, 'Choose how you want to place your order.'));
  wrap.appendChild(body);
  return phoneScreen('Create Order', wrap, { showBack: true, backTo: 'c_dashboard' });
}

function submitOrder(order) {
  const c = currentCarpenter();
  const id = 'ord' + (1000 + db.orders.length + 1);
  db.orders.unshift({ id, carpenterId: c.id, status: 'Submitted', date: new Date().toISOString().slice(0,10), pointsEarned: 0, ...order });
  saveDB(db);
  toast('Order submitted!');
  go('c_orders');
}

function screenOrderManual() {
  const body = el('div');
  const product = el('input', { placeholder: 'e.g. Plywood 19mm' });
  const qty = el('input', { type: 'number', placeholder: 'e.g. 10', min: '1' });
  body.appendChild(el('div', { class: 'field' }, [el('label', {}, 'Product'), product]));
  body.appendChild(el('div', { class: 'field' }, [el('label', {}, 'Quantity'), qty]));
  body.appendChild(el('button', { class: 'btn', onclick: () => {
    if (!product.value || !qty.value) { toast('Fill all fields'); return; }
    submitOrder({ type: 'Manual', product: product.value, qty: qty.value });
  } }, 'Submit Order'));
  return phoneScreen('Manual Order', body, { showBack: true, backTo: 'c_create_order' });
}

function screenOrderPhoto() {
  const body = el('div');
  const remarks = el('textarea', { placeholder: 'Any remarks about this order...' });
  body.appendChild(el('div', { class: 'field' }, [
    el('label', {}, 'Order Image'),
    el('div', { style: 'border:2px dashed #d8cfc2;border-radius:10px;padding:30px;text-align:center;color:var(--muted);cursor:pointer;', onclick: () => toast('Image picker (mock) — image attached') }, '📷 Tap to upload photo')
  ]));
  body.appendChild(el('div', { class: 'field' }, [el('label', {}, 'Remarks'), remarks]));
  body.appendChild(el('button', { class: 'btn', onclick: () => submitOrder({ type: 'Photo', remarks: remarks.value || 'Photo order' }) }, 'Submit Order'));
  return phoneScreen('Photo Order', body, { showBack: true, backTo: 'c_create_order' });
}

function screenOrderVoice() {
  const body = el('div', { style: 'text-align:center;' });
  let recording = false;
  const wrap = el('div');
  const pulse = el('div', { class: 'recording-pulse', style: 'display:none;' }, '🎙️');
  const status = el('p', { class: 'muted' }, 'Tap the mic to record your order');
  const remarks = el('textarea', { placeholder: 'Optional remarks...' });
  const recBtn = el('button', { class: 'btn secondary' }, '🎙️ Start Recording');
  recBtn.addEventListener('click', () => {
    recording = !recording;
    pulse.style.display = recording ? 'flex' : 'none';
    recBtn.textContent = recording ? '⏹ Stop Recording' : '🎙️ Start Recording';
    status.textContent = recording ? 'Recording...' : 'Voice note captured (mock)';
  });
  wrap.append(pulse, status, recBtn, el('div', { class: 'field', style: 'margin-top:14px;text-align:left;' }, [el('label', {}, 'Remarks'), remarks]));
  body.appendChild(wrap);
  body.appendChild(el('button', { class: 'btn full-mt', onclick: () => submitOrder({ type: 'Voice', remarks: remarks.value || 'Voice order' }) }, 'Submit Order'));
  return phoneScreen('Voice Order', body, { showBack: true, backTo: 'c_create_order' });
}

function screenOrders() {
  const c = currentCarpenter();
  const body = el('div');
  const mine = db.orders.filter(o => o.carpenterId === c.id);
  if (!mine.length) body.appendChild(el('div', { class: 'empty-state' }, [el('div', { class: 'ic' }, '📦'), el('div', {}, 'No orders yet')]));
  mine.forEach(o => {
    body.appendChild(el('div', { class: 'card', onclick: () => go('c_order_detail', { id: o.id }) }, [
      el('div', { class: 'flex-between' }, [
        el('div', {}, [el('div', { style: 'font-weight:700;' }, `#${o.id} • ${o.type}`), el('div', { class: 'muted' }, o.date)]),
        el('span', { class: 'badge ' + o.status }, o.status),
      ])
    ]));
  });
  return phoneScreen('My Orders', body, { showBack: true, backTo: 'c_dashboard' });
}

function screenOrderDetail(params) {
  const o = db.orders.find(x => x.id === params.id);
  const body = el('div');
  if (!o) body.appendChild(el('p', {}, 'Not found'));
  else {
    body.appendChild(el('div', { class: 'card' }, [
      el('div', { class: 'flex-between' }, [el('h3', { style: 'margin:0;' }, `#${o.id}`), el('span', { class: 'badge ' + o.status }, o.status)]),
      el('p', { class: 'muted' }, `Type: ${o.type} • Date: ${o.date}`),
      o.product ? el('p', {}, `Product: ${o.product} × ${o.qty}`) : '',
      o.remarks ? el('p', {}, `Remarks: ${o.remarks}`) : '',
      o.pointsEarned ? el('p', { style: 'color:var(--success);font-weight:700;' }, `Points Earned: +${o.pointsEarned}`) : '',
    ]));
    const steps = ['Submitted', 'Processing', 'Fulfilled', 'Delivered'];
    const idx = steps.indexOf(o.status);
    const track = el('div', { class: 'card' });
    track.appendChild(el('div', { class: 'section-title', style: 'margin-top:0;' }, 'Order Progress'));
    steps.forEach((s, i) => {
      track.appendChild(el('div', { class: 'list-item' }, [
        el('div', {}, (i <= idx ? '✅ ' : '⬜ ') + s),
      ]));
    });
    body.appendChild(track);
  }
  return phoneScreen('Order Detail', body, { showBack: true, backTo: 'c_orders' });
}

function screenRewards() {
  const c = currentCarpenter();
  const body = el('div');
  body.appendChild(el('div', { class: 'stat-row' }, [
    el('div', { class: 'stat-box' }, [el('div', { class: 'num' }, String(c.points)), el('div', { class: 'lbl' }, 'Current')]),
    el('div', { class: 'stat-box' }, [el('div', { class: 'num' }, String(c.lifetimePoints)), el('div', { class: 'lbl' }, 'Lifetime')]),
    el('div', { class: 'stat-box' }, [el('div', { class: 'num' }, String(c.redeemedPoints)), el('div', { class: 'lbl' }, 'Redeemed')]),
  ]));
  const menu = [
    ['📒', 'My Points', 'Earning & redemption history', () => go('c_points_ledger')],
    ['🏆', 'Leaderboard', 'Top 5 carpenters', () => go('c_leaderboard')],
    ['🎁', 'Gift Store', 'Redeem points for gifts', () => go('c_gift_store')],
    ['📜', 'Redemption History', 'Track your redemptions', () => go('c_redemption_history')],
  ];
  menu.forEach(([ic, title, sub, action]) => {
    body.appendChild(el('div', { class: 'menu-card', onclick: action }, [
      el('div', { class: 'ic' }, ic),
      el('div', { class: 'body' }, [el('div', { class: 'title' }, title), el('div', { class: 'sub' }, sub)]),
      el('div', { class: 'chev' }, '›'),
    ]));
  });
  return phoneScreen('Rewards', body, { showBack: true, backTo: 'c_dashboard' });
}

function screenPointsLedger() {
  const c = currentCarpenter();
  const body = el('div');
  const mine = db.pointsLedger.filter(p => p.carpenterId === c.id).slice().reverse();
  if (!mine.length) body.appendChild(el('div', { class: 'empty-state' }, [el('div', { class: 'ic' }, '📒'), el('div', {}, 'No activity yet')]));
  mine.forEach(p => {
    body.appendChild(el('div', { class: 'list-item' }, [
      el('div', {}, [el('div', { style: 'font-weight:600;' }, p.desc), el('div', { class: 'muted' }, `${p.date} • ${p.type}`)]),
      el('div', { style: `font-weight:800;color:${p.points >= 0 ? 'var(--success)' : 'var(--danger)'}` }, pts(p.points)),
    ]));
  });
  return phoneScreen('Points Activity', body, { showBack: true, backTo: 'c_rewards' });
}

function screenLeaderboard() {
  const top = db.carpenters.filter(c => c.status === 'Approved').slice().sort((a, b) => b.points - a.points).slice(0, 5);
  const body = el('div');
  top.forEach((c, i) => {
    body.appendChild(el('div', { class: 'leaderboard-row' + (i === 0 ? ' rank1' : '') }, [
      el('div', { class: 'lb-rank' }, `#${i + 1}`),
      el('div', { class: 'avatar', style: 'width:40px;height:40px;font-size:24px;' }, c.photo),
      el('div', { style: 'flex:1;' }, [el('div', { style: 'font-weight:700;' }, c.name), el('div', { class: 'muted' }, c.shop)]),
      el('div', { style: 'font-weight:800;color:var(--primary-dark);' }, c.points + ' pts'),
    ]));
  });
  return phoneScreen('Leaderboard', body, { showBack: true, backTo: 'c_rewards' });
}

function screenGiftStore() {
  const c = currentCarpenter();
  const body = el('div', { class: 'grid-2' });
  db.gifts.forEach(g => {
    body.appendChild(el('div', { class: 'card gift-card' }, [
      el('div', { class: 'ic' }, g.image),
      el('div', { style: 'font-weight:700;font-size:13px;' }, g.name),
      el('div', { class: 'muted', style: 'margin:4px 0;' }, g.desc),
      el('div', { class: 'pts' }, g.points + ' pts'),
      el('div', { class: 'muted' }, `${g.qty} available`),
      el('button', { class: 'btn small full-mt', style: 'width:100%;margin-top:8px;', disabled: c.points < g.points || g.qty < 1, onclick: () => {
        if (c.points < g.points) { toast('Not enough points'); return; }
        c.points -= g.points;
        c.redeemedPoints += g.points;
        g.qty -= 1;
        db.giftRedemptions.unshift({ id: 'gr' + (db.giftRedemptions.length + 1), carpenterId: c.id, giftId: g.id, date: new Date().toISOString().slice(0,10), points: g.points, status: 'Pending' });
        db.pointsLedger.push({ id: 'pl' + (db.pointsLedger.length + 1), carpenterId: c.id, type: 'Redeemed', desc: 'Gift Redemption — ' + g.name, points: -g.points, date: new Date().toISOString().slice(0,10) });
        saveDB(db);
        toast('Redemption requested!');
        go('c_gift_store');
      } }, c.points < g.points ? 'Not enough pts' : 'Redeem'),
    ]));
  });
  return phoneScreen('Gift Store', body, { showBack: true, backTo: 'c_rewards' });
}

function screenRedemptionHistory() {
  const c = currentCarpenter();
  const body = el('div');
  const mine = db.giftRedemptions.filter(r => r.carpenterId === c.id);
  if (!mine.length) body.appendChild(el('div', { class: 'empty-state' }, [el('div', { class: 'ic' }, '🎁'), el('div', {}, 'No redemptions yet')]));
  mine.forEach(r => {
    const g = db.gifts.find(x => x.id === r.giftId);
    body.appendChild(el('div', { class: 'card' }, [
      el('div', { class: 'flex-between' }, [
        el('div', {}, [el('div', { style: 'font-weight:700;' }, g ? g.name : 'Gift'), el('div', { class: 'muted' }, `${r.date} • ${r.points} pts`)]),
        el('span', { class: 'badge ' + r.status }, r.status),
      ])
    ]));
  });
  return phoneScreen('Redemption History', body, { showBack: true, backTo: 'c_rewards' });
}

function screenLeads() {
  const c = currentCarpenter();
  const body = el('div');
  body.appendChild(el('button', { class: 'btn', onclick: () => go('c_lead_new') }, '+ Submit New Lead'));
  body.appendChild(el('div', { class: 'section-title' }, 'My Submitted Leads'));
  const mine = db.leads.filter(l => l.carpenterId === c.id);
  if (!mine.length) body.appendChild(el('div', { class: 'empty-state' }, [el('div', { class: 'ic' }, '💡'), el('div', {}, 'No leads submitted yet')]));
  mine.forEach(l => {
    body.appendChild(el('div', { class: 'card' }, [
      el('div', { class: 'flex-between' }, [
        el('div', {}, [el('div', { style: 'font-weight:700;' }, l.customerName), el('div', { class: 'muted' }, l.notes)]),
        el('span', { class: 'badge ' + l.status }, l.status),
      ])
    ]));
  });
  return phoneScreen('Suggestions / Leads', body, { showBack: true, backTo: 'c_dashboard' });
}

function screenLeadNew() {
  const body = el('div');
  const name = el('input', { placeholder: 'Customer name' });
  const phone = el('input', { type: 'tel', placeholder: 'Customer phone number' });
  const location = el('input', { placeholder: 'Location (optional)' });
  const notes = el('textarea', { placeholder: 'e.g. Need modular kitchen work.' });
  body.appendChild(el('div', { class: 'field' }, [el('label', {}, 'Customer Name'), name]));
  body.appendChild(el('div', { class: 'field' }, [el('label', {}, 'Phone Number'), phone]));
  body.appendChild(el('div', { class: 'field' }, [el('label', {}, 'Location (Optional)'), location]));
  body.appendChild(el('div', { class: 'field' }, [el('label', {}, 'Requirement Notes'), notes]));
  body.appendChild(el('p', { class: 'muted' }, '📍 GPS location, timestamp & carpenter ID will be auto-captured for verification.'));
  body.appendChild(el('button', { class: 'btn', onclick: () => {
    if (!name.value || !phone.value) { toast('Fill required fields'); return; }
    const c = currentCarpenter();
    db.leads.unshift({ id: 'ld' + (db.leads.length + 1), carpenterId: c.id, customerName: name.value, phone: phone.value, location: location.value, notes: notes.value, status: 'New', date: new Date().toISOString().slice(0,10) });
    saveDB(db);
    toast('Lead submitted!');
    go('c_leads');
  } }, 'Submit Lead'));
  return phoneScreen('New Lead', body, { showBack: true, backTo: 'c_leads' });
}

function screenNotifications() {
  const c = currentCarpenter();
  const body = el('div');
  const mine = db.notifications.filter(n => n.carpenterId === c.id);
  if (!mine.length) body.appendChild(el('div', { class: 'empty-state' }, [el('div', { class: 'ic' }, '🔔'), el('div', {}, 'No notifications')]));
  mine.forEach(n => {
    body.appendChild(el('div', { class: 'card', style: n.read ? 'opacity:.6;' : 'border-left:3px solid var(--primary);' }, [
      el('div', { style: 'font-weight:700;' }, n.title),
      el('div', { class: 'muted' }, n.body),
      el('div', { class: 'muted', style: 'margin-top:4px;font-size:11px;' }, n.date),
    ]));
  });
  return phoneScreen('Notifications', body, { showBack: true, backTo: 'c_dashboard' });
}

function screenProfile() {
  const c = currentCarpenter();
  const body = el('div');
  body.appendChild(el('div', { class: 'dash-header' }, [
    el('div', { class: 'avatar' }, c.photo),
    el('div', {}, [el('p', { class: 'welcome-title' }, c.name), el('p', { class: 'welcome-sub' }, c.mobile)]),
  ]));
  body.appendChild(el('div', { class: 'card' }, [
    el('div', { class: 'list-item' }, [el('div', {}, 'Shop Name'), el('div', {}, c.shop)]),
    el('div', { class: 'list-item' }, [el('div', {}, 'Address'), el('div', {}, c.address)]),
    el('div', { class: 'list-item' }, [el('div', {}, 'Status'), el('span', { class: 'badge ' + c.status }, c.status)]),
  ]));
  body.appendChild(el('div', { class: 'menu-card', onclick: () => go('c_payout') }, [
    el('div', { class: 'ic' }, '💳'), el('div', { class: 'body' }, [el('div', { class: 'title' }, 'Payout Details'), el('div', { class: 'sub' }, 'Bank account & UPI')]), el('div', { class: 'chev' }, '›')
  ]));
  body.appendChild(el('div', { class: 'menu-card', onclick: () => go('c_invoices') }, [
    el('div', { class: 'ic' }, '🧾'), el('div', { class: 'body' }, [el('div', { class: 'title' }, 'Invoices'), el('div', { class: 'sub' }, 'View & download invoices')]), el('div', { class: 'chev' }, '›')
  ]));
  body.appendChild(el('button', { class: 'btn outline full-mt', onclick: () => { db.currentUser = null; saveDB(db); go('splash'); } }, 'Logout'));
  return phoneScreen('Profile', body, { showBack: true, backTo: 'c_dashboard' });
}

function screenPayout() {
  const c = currentCarpenter();
  const existing = db.payoutDetails[c.id] || {};
  const body = el('div');
  const holder = el('input', { value: existing.accountHolder || '', placeholder: 'Account Holder Name' });
  const accnum = el('input', { value: existing.accountNumber || '', placeholder: 'Account Number' });
  const ifsc = el('input', { value: existing.ifsc || '', placeholder: 'IFSC Code' });
  const upi = el('input', { value: existing.upi || '', placeholder: 'UPI ID' });
  body.appendChild(el('div', { class: 'section-title', style: 'margin-top:0;' }, 'Bank Account'));
  body.appendChild(el('div', { class: 'field' }, [el('label', {}, 'Account Holder Name'), holder]));
  body.appendChild(el('div', { class: 'field' }, [el('label', {}, 'Account Number'), accnum]));
  body.appendChild(el('div', { class: 'field' }, [el('label', {}, 'IFSC'), ifsc]));
  body.appendChild(el('div', { class: 'section-title' }, 'UPI'));
  body.appendChild(el('div', { class: 'field' }, [el('label', {}, 'UPI ID'), upi]));
  body.appendChild(el('div', { class: 'field' }, [el('label', {}, 'QR Code'), el('div', { style: 'border:2px dashed #d8cfc2;border-radius:10px;padding:20px;text-align:center;color:var(--muted);cursor:pointer;', onclick: () => toast('QR upload (mock)') }, '📷 Upload QR Code')]));
  body.appendChild(el('button', { class: 'btn', onclick: () => {
    db.payoutDetails[c.id] = { accountHolder: holder.value, accountNumber: accnum.value, ifsc: ifsc.value, upi: upi.value };
    saveDB(db);
    toast('Payout details saved');
  } }, 'Save Payout Details'));
  return phoneScreen('Payout Details', body, { showBack: true, backTo: 'c_profile' });
}

function screenInvoices() {
  const c = currentCarpenter();
  const body = el('div');
  const mine = db.invoices.filter(i => i.carpenterId === c.id);
  if (!mine.length) body.appendChild(el('div', { class: 'empty-state' }, [el('div', { class: 'ic' }, '🧾'), el('div', {}, 'No invoices yet')]));
  mine.forEach(i => {
    body.appendChild(el('div', { class: 'card flex-between' }, [
      el('div', {}, [el('div', { style: 'font-weight:700;' }, i.number), el('div', { class: 'muted' }, `${i.date} • ₹${i.amount}`)]),
      el('button', { class: 'btn small', onclick: () => toast('Downloading PDF (mock)') }, 'Download'),
    ]));
  });
  return phoneScreen('Invoices', body, { showBack: true, backTo: 'c_profile' });
}

// ===================== ADMIN DASHBOARD =====================

function adminShell(activeKey, title, contentNode) {
  const frame = el('div', { class: 'admin-frame' });
  const sidebar = el('div', { class: 'sidebar' });
  sidebar.appendChild(el('h2', {}, '🪵 Admin'));
  const links = [
    ['a_dashboard', '📊', 'Dashboard'],
    ['a_approvals', '✅', 'Approval Queue'],
    ['a_carpenters', '👥', 'Carpenter List'],
    ['a_map', '🗺️', 'Live Tracking Map'],
    ['a_offers', '🎯', 'Offers'],
    ['a_orders', '📦', 'Orders'],
    ['a_points_rules', '⚙️', 'Points Rules'],
    ['a_gifts', '🎁', 'Gift Management'],
    ['a_redemptions', '📜', 'Redemption Requests'],
    ['a_leads', '💡', 'Lead Management'],
    ['a_notifications', '🔔', 'Notification Center'],
  ];
  links.forEach(([key, ic, label]) => {
    sidebar.appendChild(el('div', { class: 'side-link' + (key === activeKey ? ' active' : ''), onclick: () => go(key) }, `${ic} ${label}`));
  });
  sidebar.appendChild(el('div', { class: 'side-link', style: 'margin-top:20px;color:#e57373;', onclick: () => { db.currentUser = null; saveDB(db); go('a_login'); } }, '🚪 Logout'));
  frame.appendChild(sidebar);
  const main = el('div', { class: 'admin-body' });
  main.appendChild(el('div', { class: 'admin-header' }, [el('h1', {}, title)]));
  main.appendChild(contentNode);
  frame.appendChild(main);
  return frame;
}

function screenAdminLogin() {
  const wrap = el('div', { style: 'max-width:380px;margin:80px auto;' });
  const card = el('div', { class: 'card' });
  card.appendChild(el('h2', { style: 'margin-top:0;' }, '🪵 Admin Login'));
  const email = el('input', { type: 'email', value: 'admin@carpenter.com' });
  const pass = el('input', { type: 'password', value: 'admin123' });
  card.appendChild(el('div', { class: 'field' }, [el('label', {}, 'Email'), email]));
  card.appendChild(el('div', { class: 'field' }, [el('label', {}, 'Password'), pass]));
  card.appendChild(el('button', { class: 'btn', onclick: () => {
    if (email.value === db.admin.email && pass.value === db.admin.password) {
      db.currentUser = { role: 'admin' };
      saveDB(db);
      go('a_dashboard');
    } else toast('Invalid admin credentials');
  } }, 'Login'));
  wrap.appendChild(card);
  return wrap;
}

function screenAdminDashboard() {
  const pendingCount = db.carpenters.filter(c => c.status === 'Pending').length;
  const totalOrders = db.orders.length;
  const totalRedeemed = db.giftRedemptions.length;
  const totalLeads = db.leads.length;
  const body = el('div');
  body.appendChild(el('div', { class: 'kpi-row' }, [
    ['👥', db.carpenters.length, 'Total Carpenters'],
    ['⏳', pendingCount, 'Pending Approvals'],
    ['📦', totalOrders, 'Total Orders'],
    ['🎁', totalRedeemed, 'Gift Redemptions'],
    ['💡', totalLeads, 'Leads Captured'],
  ].map(([ic, num, lbl]) => el('div', { class: 'kpi' }, [el('div', { class: 'num' }, `${ic} ${num}`), el('div', { class: 'lbl' }, lbl)]))));

  body.appendChild(el('div', { class: 'section-title', style: 'margin-top:0;' }, 'Recent Orders'));
  const table = el('table');
  table.innerHTML = '<tr><th>Order ID</th><th>Carpenter</th><th>Type</th><th>Status</th><th>Date</th></tr>';
  db.orders.slice(0, 5).forEach(o => {
    const c = db.carpenters.find(x => x.id === o.carpenterId);
    const tr = el('tr');
    tr.innerHTML = `<td>#${o.id}</td><td>${c ? c.name : '—'}</td><td>${o.type}</td><td><span class="badge ${o.status}">${o.status}</span></td><td>${o.date}</td>`;
    table.appendChild(tr);
  });
  body.appendChild(table);
  return adminShell('a_dashboard', 'Dashboard', body);
}

function screenAdminApprovals() {
  const body = el('div');
  const pending = db.carpenters.filter(c => c.status === 'Pending');
  if (!pending.length) body.appendChild(el('div', { class: 'empty-state' }, [el('div', { class: 'ic' }, '✅'), el('div', {}, 'No pending approvals')]));
  pending.forEach(c => {
    body.appendChild(el('div', { class: 'card flex-between' }, [
      el('div', {}, [el('div', { style: 'font-weight:700;' }, `${c.name} — ${c.shop}`), el('div', { class: 'muted' }, `${c.mobile} • ${c.address}`)]),
      el('div', { style: 'display:flex;gap:8px;' }, [
        el('button', { class: 'btn small', onclick: () => {
          c.status = 'Approved';
          db.notifications.push({ id: 'n' + (db.notifications.length + 1), carpenterId: c.id, title: 'Account Approved', body: 'Your account has been approved! You can now login.', date: new Date().toISOString().slice(0,10), read: false });
          saveDB(db); toast('Approved ' + c.name); go('a_approvals');
        } }, 'Approve'),
        el('button', { class: 'btn small outline', onclick: () => { c.status = 'Rejected'; saveDB(db); toast('Rejected ' + c.name); go('a_approvals'); } }, 'Reject'),
      ])
    ]));
  });
  return adminShell('a_approvals', 'Approval Queue', body);
}

function screenAdminCarpenters() {
  const body = el('div');
  const table = el('table');
  table.innerHTML = '<tr><th>Name</th><th>Shop</th><th>Mobile</th><th>Status</th><th>Points</th></tr>';
  db.carpenters.forEach(c => {
    const tr = el('tr');
    tr.innerHTML = `<td>${c.name}</td><td>${c.shop}</td><td>${c.mobile}</td><td><span class="badge ${c.status}">${c.status}</span></td><td>${c.points}</td>`;
    table.appendChild(tr);
  });
  body.appendChild(table);
  return adminShell('a_carpenters', 'Carpenter List', body);
}

function screenAdminMap() {
  const body = el('div');
  const approved = db.carpenters.filter(c => c.status === 'Approved');
  const map = el('div', { class: 'map-placeholder' });
  const positions = [[30, 30], [60, 50], [40, 70], [75, 25]];
  approved.forEach((c, i) => {
    const [top, left] = positions[i % positions.length];
    map.appendChild(el('div', { class: 'map-pin', style: `top:${top}%;left:${left}%;`, title: c.name, onclick: () => toast(`${c.name} — last seen 3 min ago`) }, '📍'));
  });
  body.appendChild(map);
  body.appendChild(el('p', { class: 'muted' }, 'Click a pin to view last-seen details. (Mock map — integrates with Google Maps SDK in production.)'));
  return adminShell('a_map', 'Live Tracking Map', body);
}

function screenAdminOffers() {
  const body = el('div');
  body.appendChild(el('button', { class: 'btn', style: 'width:auto;', onclick: () => go('a_offer_new') }, '+ Create Offer'));
  const table = el('table');
  table.style.marginTop = '14px';
  table.innerHTML = '<tr><th>Title</th><th>Category</th><th>Start</th><th>End</th></tr>';
  db.offers.forEach(o => {
    const tr = el('tr');
    tr.innerHTML = `<td>${o.banner} ${o.title}</td><td>${o.category}</td><td>${o.start}</td><td>${o.end}</td>`;
    table.appendChild(tr);
  });
  body.appendChild(table);
  return adminShell('a_offers', 'Offers List', body);
}

function screenAdminOfferNew() {
  const body = el('div', { class: 'card', style: 'max-width:480px;' });
  const title = el('input', { placeholder: 'Offer title' });
  const desc = el('textarea', { placeholder: 'Description' });
  const cat = el('select', {}, '<option>Today</option><option>Weekly</option>');
  const start = el('input', { type: 'date' });
  const end = el('input', { type: 'date' });
  body.appendChild(el('div', { class: 'field' }, [el('label', {}, 'Title'), title]));
  body.appendChild(el('div', { class: 'field' }, [el('label', {}, 'Description'), desc]));
  body.appendChild(el('div', { class: 'field' }, [el('label', {}, 'Category'), cat]));
  body.appendChild(el('div', { class: 'field' }, [el('label', {}, 'Start Date'), start]));
  body.appendChild(el('div', { class: 'field' }, [el('label', {}, 'End Date'), end]));
  body.appendChild(el('div', { class: 'field' }, [el('label', {}, 'Banner / PDF'), el('div', { style: 'border:2px dashed #d8cfc2;border-radius:10px;padding:16px;text-align:center;color:var(--muted);cursor:pointer;', onclick: () => toast('Upload (mock)') }, '📤 Upload Banner Image / PDF')]));
  body.appendChild(el('button', { class: 'btn', onclick: () => {
    if (!title.value) { toast('Title required'); return; }
    db.offers.unshift({ id: 'o' + (db.offers.length + 1), title: title.value, description: desc.value, category: cat.value, start: start.value, end: end.value, banner: '🎯' });
    db.carpenters.filter(c => c.status === 'Approved').forEach(c => db.notifications.push({ id: 'n' + (db.notifications.length + 1), carpenterId: c.id, title: 'New Offer', body: title.value + ' is now live!', date: new Date().toISOString().slice(0,10), read: false }));
    saveDB(db);
    toast('Offer created & notifications sent');
    go('a_offers');
  } }, 'Create & Notify'));
  return adminShell('a_offers', 'Create Offer', body);
}

function screenAdminOrders() {
  const body = el('div');
  const table = el('table');
  table.innerHTML = '<tr><th>Order ID</th><th>Carpenter</th><th>Type</th><th>Status</th><th>Date</th><th>Action</th></tr>';
  db.orders.forEach(o => {
    const c = db.carpenters.find(x => x.id === o.carpenterId);
    const tr = el('tr');
    const tdAction = el('td');
    const select = el('select');
    ['Submitted', 'Processing', 'Fulfilled', 'Delivered', 'Cancelled'].forEach(s => {
      const opt = el('option', { value: s }, s);
      if (s === o.status) opt.selected = true;
      select.appendChild(opt);
    });
    select.addEventListener('change', () => {
      const prevStatus = o.status;
      o.status = select.value;
      if (o.status === 'Fulfilled' && prevStatus !== 'Fulfilled' && c) {
        const earned = Math.floor((o.qty || 1) * 100 / db.pointRule.amount) * db.pointRule.points || 50;
        o.pointsEarned = earned;
        c.points += earned;
        c.lifetimePoints += earned;
        db.pointsLedger.push({ id: 'pl' + (db.pointsLedger.length + 1), carpenterId: c.id, type: 'Earned', desc: 'Order #' + o.id, points: earned, date: new Date().toISOString().slice(0,10) });
        db.notifications.push({ id: 'n' + (db.notifications.length + 1), carpenterId: c.id, title: 'Points Credited', body: `+${earned} points for Order #${o.id}`, date: new Date().toISOString().slice(0,10), read: false });
      }
      saveDB(db);
      toast(`Order #${o.id} → ${o.status}`);
      go('a_orders');
    });
    tdAction.appendChild(select);
    tr.append(
      el('td', {}, `#${o.id}`), el('td', {}, c ? c.name : '—'), el('td', {}, o.type),
      el('td', {}, el('span', { class: 'badge ' + o.status }, o.status)), el('td', {}, o.date), tdAction
    );
    table.appendChild(tr);
  });
  body.appendChild(table);
  return adminShell('a_orders', 'Orders List', body);
}

function screenAdminPointsRules() {
  const body = el('div', { class: 'card', style: 'max-width:420px;' });
  const amount = el('input', { type: 'number', value: db.pointRule.amount });
  const points = el('input', { type: 'number', value: db.pointRule.points });
  body.appendChild(el('p', {}, 'Define how purchase amount converts into loyalty points.'));
  body.appendChild(el('div', { class: 'field' }, [el('label', {}, 'Points'), points]));
  body.appendChild(el('div', { class: 'field' }, [el('label', {}, 'Per ₹ Amount'), amount]));
  body.appendChild(el('button', { class: 'btn', onclick: () => {
    db.pointRule = { amount: Number(amount.value), points: Number(points.value) };
    saveDB(db);
    toast('Point rule updated');
  } }, 'Save Rule'));
  return adminShell('a_points_rules', 'Points Rules', body);
}

function screenAdminGifts() {
  const body = el('div');
  body.appendChild(el('button', { class: 'btn', style: 'width:auto;', onclick: () => {
    const name = prompt('Gift name?'); if (!name) return;
    const points = Number(prompt('Required points?') || 0);
    const qty = Number(prompt('Available quantity?') || 0);
    db.gifts.push({ id: 'g' + (db.gifts.length + 1), name, desc: '', points, qty, image: '🎁' });
    saveDB(db); go('a_gifts');
  } }, '+ Add Gift'));
  const grid = el('div', { class: 'grid-3', style: 'margin-top:14px;' });
  db.gifts.forEach(g => {
    grid.appendChild(el('div', { class: 'card gift-card' }, [
      el('div', { class: 'ic' }, g.image), el('div', { style: 'font-weight:700;' }, g.name),
      el('div', { class: 'pts' }, g.points + ' pts'), el('div', { class: 'muted' }, g.qty + ' available'),
    ]));
  });
  body.appendChild(grid);
  return adminShell('a_gifts', 'Gift Management', body);
}

function screenAdminRedemptions() {
  const body = el('div');
  const table = el('table');
  table.innerHTML = '<tr><th>Carpenter</th><th>Gift</th><th>Points</th><th>Date</th><th>Status</th><th>Action</th></tr>';
  db.giftRedemptions.forEach(r => {
    const c = db.carpenters.find(x => x.id === r.carpenterId);
    const g = db.gifts.find(x => x.id === r.giftId);
    const tr = el('tr');
    const tdAction = el('td');
    const select = el('select');
    ['Pending', 'Approved', 'Processing', 'Dispatched', 'Delivered'].forEach(s => {
      const opt = el('option', { value: s }, s);
      if (s === r.status) opt.selected = true;
      select.appendChild(opt);
    });
    select.addEventListener('change', () => {
      r.status = select.value;
      if (c) db.notifications.push({ id: 'n' + (db.notifications.length + 1), carpenterId: c.id, title: 'Redemption Update', body: `Your ${g ? g.name : 'gift'} is now ${r.status}`, date: new Date().toISOString().slice(0,10), read: false });
      saveDB(db); toast('Status updated'); go('a_redemptions');
    });
    tdAction.appendChild(select);
    tr.append(
      el('td', {}, c ? c.name : '—'), el('td', {}, g ? g.name : '—'), el('td', {}, r.points),
      el('td', {}, r.date), el('td', {}, el('span', { class: 'badge ' + r.status }, r.status)), tdAction
    );
    table.appendChild(tr);
  });
  body.appendChild(table);
  return adminShell('a_redemptions', 'Redemption Requests', body);
}

function screenAdminLeads() {
  const body = el('div');
  const table = el('table');
  table.innerHTML = '<tr><th>Customer</th><th>Phone</th><th>Carpenter</th><th>Notes</th><th>Status</th></tr>';
  db.leads.forEach(l => {
    const c = db.carpenters.find(x => x.id === l.carpenterId);
    const tr = el('tr');
    const tdStatus = el('td');
    const select = el('select');
    ['New', 'Contacted', 'Qualified', 'Converted', 'Closed'].forEach(s => {
      const opt = el('option', { value: s }, s);
      if (s === l.status) opt.selected = true;
      select.appendChild(opt);
    });
    select.addEventListener('change', () => { l.status = select.value; saveDB(db); toast('Lead updated'); go('a_leads'); });
    tdStatus.appendChild(select);
    tr.append(el('td', {}, l.customerName), el('td', {}, l.phone), el('td', {}, c ? c.name : '—'), el('td', {}, l.notes), tdStatus);
    table.appendChild(tr);
  });
  body.appendChild(table);
  return adminShell('a_leads', 'Lead Management', body);
}

function screenAdminNotifications() {
  const body = el('div', { class: 'card', style: 'max-width:480px;' });
  const title = el('input', { placeholder: 'Notification title' });
  const text = el('textarea', { placeholder: 'Message body' });
  body.appendChild(el('div', { class: 'field' }, [el('label', {}, 'Title'), title]));
  body.appendChild(el('div', { class: 'field' }, [el('label', {}, 'Message'), text]));
  body.appendChild(el('button', { class: 'btn', onclick: () => {
    if (!title.value) { toast('Title required'); return; }
    db.carpenters.filter(c => c.status === 'Approved').forEach(c => db.notifications.push({ id: 'n' + (db.notifications.length + 1), carpenterId: c.id, title: title.value, body: text.value, date: new Date().toISOString().slice(0,10), read: false }));
    saveDB(db);
    toast('Notification broadcast to all approved carpenters');
  } }, 'Send Broadcast'));
  const recentTitle = el('div', { class: 'section-title' }, 'Recent Notifications');
  const list = el('div');
  db.notifications.slice(-6).reverse().forEach(n => list.appendChild(el('div', { class: 'list-item' }, [el('div', {}, n.title), el('div', { class: 'muted' }, n.date)])));
  const wrap = el('div');
  wrap.append(body, recentTitle, list);
  return adminShell('a_notifications', 'Notification Center', wrap);
}

// ===================== ROUTER =====================

const routes = {
  splash: screenSplash,
  login: screenLogin,
  register: screenRegister,
  pending: screenPending,
  c_location: screenLocationConsent,
  c_dashboard: screenDashboard,
  c_offers: screenOffers,
  c_offer_detail: screenOfferDetail,
  c_create_order: screenCreateOrder,
  c_order_manual: screenOrderManual,
  c_order_photo: screenOrderPhoto,
  c_order_voice: screenOrderVoice,
  c_orders: screenOrders,
  c_order_detail: screenOrderDetail,
  c_rewards: screenRewards,
  c_points_ledger: screenPointsLedger,
  c_leaderboard: screenLeaderboard,
  c_gift_store: screenGiftStore,
  c_redemption_history: screenRedemptionHistory,
  c_leads: screenLeads,
  c_lead_new: screenLeadNew,
  c_notifications: screenNotifications,
  c_profile: screenProfile,
  c_payout: screenPayout,
  c_invoices: screenInvoices,

  a_login: screenAdminLogin,
  a_dashboard: screenAdminDashboard,
  a_approvals: screenAdminApprovals,
  a_carpenters: screenAdminCarpenters,
  a_map: screenAdminMap,
  a_offers: screenAdminOffers,
  a_offer_new: screenAdminOfferNew,
  a_orders: screenAdminOrders,
  a_points_rules: screenAdminPointsRules,
  a_gifts: screenAdminGifts,
  a_redemptions: screenAdminRedemptions,
  a_leads: screenAdminLeads,
  a_notifications: screenAdminNotifications,
};

function render() {
  root.innerHTML = '';
  root.appendChild(renderRoleSwitch());
  const fn = routes[state.screen] || screenSplash;
  const node = fn(state.params);
  if (node) root.appendChild(node);
}

render();
