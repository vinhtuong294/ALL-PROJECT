const API = 'http://localhost:8001';
let sessionId = null;
let convHistory = [];
let loading = false;
let selectedDays = 1;
let selectedNotes = [];
let currentTab = 'chat';

// ─── Init ────────────────────────────────────────────────
checkAPI();

function checkAPI() {
  fetch(`${API}/health`)
    .then(r => r.json())
    .then(d => {
      document.getElementById('dot').className = 'dot on';
      document.getElementById('statusTxt').textContent = `Online · ${d.total_dishes} món`;
    })
    .catch(() => {
      document.getElementById('dot').className = 'dot off';
      document.getElementById('statusTxt').textContent = 'API offline';
    });
}

// ─── Tab / View switching ────────────────────────────────
function switchTab(tab) {
  currentTab = tab;

  ['chat','menu','shop'].forEach(t => {
    document.getElementById('tabChat').classList.toggle('active', t === 'chat' && tab === 'chat');
    document.getElementById('tabMenu').classList.toggle('active', t === 'menu' && tab === 'menu');
    document.getElementById('tabShop').classList.toggle('active', t === 'shop' && tab === 'shop');
  });

  document.getElementById('navChat').classList.toggle('active', tab === 'chat');
  document.getElementById('navMenu').classList.toggle('active', tab === 'menu');
  document.getElementById('navShop').classList.toggle('active', tab === 'shop');

  document.getElementById('viewChat').classList.toggle('active', tab !== 'menu');
  document.getElementById('viewMenu').classList.toggle('active', tab === 'menu');

  if (tab === 'shop') {
    document.getElementById('msgInput').placeholder = 'Hỏi gian hàng nào bán gì, ở đâu, rating cao...';
  } else {
    document.getElementById('msgInput').placeholder = 'Hỏi về món ăn, gian hàng, công thức...';
  }
}

// ─── Menu builder ────────────────────────────────────────
function selectDays(btn) {
  document.querySelectorAll('.day-btn').forEach(b => b.classList.remove('selected'));
  btn.classList.add('selected');
  selectedDays = parseInt(btn.dataset.days);
}

function toggleNote(btn) {
  btn.classList.toggle('selected');
  const noteMap = {
    'Món chay': 'Món chay', 'Miền Bắc': 'Miền Bắc',
    'Miền Trung': 'Miền Trung', 'Miền Nam': 'Miền Nam',
    'Trẻ em': 'Trẻ em', 'Người lớn tuổi': 'Người lớn tuổi', 'Ăn kiêng': 'Ăn kiêng',
  };
  const key = Object.keys(noteMap).find(k => btn.textContent.includes(k));
  if (btn.classList.contains('selected') && key) {
    if (!selectedNotes.includes(noteMap[key])) selectedNotes.push(noteMap[key]);
  } else {
    selectedNotes = selectedNotes.filter(n => n !== noteMap[key]);
  }
}

async function generateMenu() {
  const goal = document.getElementById('menuGoal').value;
  const meals = parseInt(document.getElementById('menuMeals').value);
  const allergyText = document.getElementById('allergyInput').value.trim();
  
  // Parse allergies from comma-separated text
  const allergies = allergyText
    ? allergyText.split(',').map(a => a.trim()).filter(a => a)
    : [];
  
  const btn = document.getElementById('genBtn');

  btn.disabled = true;
  btn.innerHTML = '<span class="spin"></span> Đang tạo thực đơn...';

  try {
    const res = await fetch(`${API}/menu/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ 
        days: selectedDays, 
        meals_per_day: meals, 
        health_goal: goal, 
        notes: selectedNotes,
        allergen_ingredients: allergies
      }),
    });
    const data = await res.json();
    renderMenu(data);
  } catch (e) {
    document.getElementById('menuResult').innerHTML =
      `<p style="color:var(--red);font-size:13px">Lỗi: ${e.message}</p>`;
  } finally {
    btn.disabled = false;
    btn.innerHTML = '✨ Tạo thực đơn';
  }
}

function renderMenu(data) {
  const goalLabels = {'Cân bằng':'Dinh dưỡng cân bằng','Giảm cân':'Giảm cân','Tăng cân':'Tăng cân','Tăng cơ':'Tăng cơ','Sức đề kháng':'Tăng sức đề kháng'};
  document.getElementById('menuSub').textContent =
    `${goalLabels[data.health_goal] || data.health_goal} · ${data.days} ngày · ${data.meals_per_day} bữa/ngày`;

  const daysHTML = data.menu.map((day, di) => {
    const mealsHTML = day.meals.map(m => {
      const d = m.dish;
      const imgTag = d.image_url
        ? `<img src="${esc(d.image_url)}" alt="${esc(d.dish_name)}" loading="lazy" onerror="this.parentElement.innerHTML='🍽️'">`
        : '🍽️';
      return `
        <div class="meal-row">
          <div class="meal-label">${esc(m.meal)}</div>
          <div class="meal-img">${imgTag}</div>
          <div class="meal-info">
            <div class="meal-name">${esc(d.dish_name)}</div>
            <div class="meal-meta">
              ${d.calories ? `<span class="meal-tag">🔥 ${Math.round(d.calories)} kcal</span>` : ''}
              ${d.cooking_time ? `<span class="meal-tag">⏱ ${esc(d.cooking_time)}</span>` : ''}
              ${d.level ? `<span class="meal-tag">📊 ${esc(d.level)}</span>` : ''}
            </div>
          </div>
          <div class="meal-actions">
            <button class="meal-action-btn btn-recipe" onclick='openRecipeFromDish(${JSON.stringify(d).replace(/'/g,"&#39;")})'>📖 Công thức</button>
            <button class="meal-action-btn btn-buy" onclick="loadStalls('${esc(d.dish_id)}', this, true)">🛒 Mua</button>
          </div>
        </div>`;
    }).join('');
    return `
      <div class="day-block">
        <div class="day-header">
          <div class="day-title">
            <span style="background:var(--accent-glow);color:var(--accent);padding:3px 10px;border-radius:6px;font-size:12px">Ngày ${day.day}</span>
          </div>
          <span style="font-size:11px;color:var(--muted)">${day.meals.length} bữa</span>
        </div>
        <div class="day-meals">${mealsHTML}</div>
      </div>`;
  }).join('');

  document.getElementById('menuResult').innerHTML = `<div class="menu-days">${daysHTML}</div>`;
}

// ─── Chat ────────────────────────────────────────────────
function suggest(text) {
  if (currentTab !== 'chat' && currentTab !== 'shop') switchTab('chat');
  document.getElementById('viewChat').classList.add('active');
  document.getElementById('viewMenu').classList.remove('active');
  document.getElementById('msgInput').value = text;
  sendMessage();
}

function newChat() {
  sessionId = null;
  convHistory = [];
  const msgs = document.getElementById('msgs');
  msgs.innerHTML = `
    <div class="welcome" id="welcome">
      <div class="welcome-emoji">🍳</div>
      <h1>Trợ Lý Ẩm Thực AI</h1>
      <p>Hỏi tôi về món ăn, công thức nấu, gian hàng nguyên liệu hay thực đơn sức khỏe!</p>
      <div class="chips">
        <button class="chip" onclick="suggest('Gợi ý món thịt bò')">🥩 Món thịt bò</button>
        <button class="chip" onclick="suggest('Món hải sản tươi ngon')">🦐 Hải sản tươi</button>
        <button class="chip" onclick="suggest('Ăn kiêng giảm cân nên ăn gì?')">🥗 Ăn kiêng</button>
        <button class="chip" onclick="suggest('Nấu nhanh 15 phút')">⚡ Nấu nhanh</button>
        <button class="chip" onclick="suggest('Gian hàng nào bán thịt bò tươi uy tín?')">🏪 Gian hàng</button>
      </div>
      <div style="margin-top:10px;display:flex;flex-direction:column;align-items:center;gap:6px">
        <span style="font-size:11px;color:var(--muted2);letter-spacing:0.5px">— Demo các tính năng mới —</span>
        <div class="chips">
          <button class="chip demo-chip" onclick="suggest('Tìm món chay ngon không có thịt cá')">🥬 Test món chay</button>
          <button class="chip demo-chip" onclick="suggest('Cá mồi nấu gì ngon')">🐟 Test cá mồi</button>
          <button class="chip demo-chip" onclick="suggest('Gian hàng bán hải sản tươi')">🏪 Test gian hàng</button>
        </div>
      </div>
    </div>`;
}

function handleKey(e) {
  if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMessage(); }
}

function autoResize(el) {
  el.style.height = 'auto';
  el.style.height = Math.min(el.scrollHeight, 120) + 'px';
}

async function sendMessage() {
  const input = document.getElementById('msgInput');
  const text = input.value.trim();
  if (!text || loading) return;

  const welcome = document.getElementById('welcome');
  if (welcome) welcome.remove();

  if (currentTab === 'menu') switchTab('chat');

  addMsg('user', text);
  convHistory.push({ role: 'user', content: text });

  input.value = '';
  input.style.height = 'auto';
  loading = true;
  document.getElementById('sendBtn').disabled = true;

  const typingEl = addTyping();

  try {
    const res = await fetch(`${API}/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message: text, session_id: sessionId, history: convHistory.slice(-6) }),
    });
    const data = await res.json();
    sessionId = data.session_id;
    convHistory.push({ role: 'assistant', content: data.reply });
    typingEl.remove();
    renderBotMsg(data);
  } catch (err) {
    typingEl.remove();
    addMsg('bot', `Lỗi kết nối: ${err.message}`);
  }

  loading = false;
  document.getElementById('sendBtn').disabled = false;
  scrollBot();
}

// ─── Render ──────────────────────────────────────────────
function addMsg(role, text) {
  const msgs = document.getElementById('msgs');
  const div = document.createElement('div');
  div.className = `msg ${role}`;
  const av = role === 'user' ? '👤' : '🍜';
  if (role === 'user') {
    div.innerHTML = `<div class="av">${av}</div><div class="bubble">${esc(text)}</div>`;
  } else {
    div.innerHTML = `<div class="av">${av}</div><div class="bubble"><div class="reply-box">${esc(text)}</div></div>`;
  }
  msgs.appendChild(div);
  scrollBot();
}

function addTyping() {
  const msgs = document.getElementById('msgs');
  const div = document.createElement('div');
  div.className = 'msg bot';
  div.innerHTML = `
    <div class="av">🍜</div>
    <div class="bubble">
      <div class="typing">
        <div class="tdot"></div><div class="tdot"></div><div class="tdot"></div>
      </div>
    </div>`;
  msgs.appendChild(div);
  scrollBot();
  return div;
}

const INTENT_LABELS = {
  greeting:'Chào hỏi', menu_planning:'Thực đơn',
  health_advice:'Sức khỏe', cooking_instruction:'Công thức',
  filter_quick:'Nấu nhanh', search_ingredient:'Nguyên liệu',
  search_dish_type:'Loại món', special_occasion:'Dịp đặc biệt',
  diet_type:'Chế độ ăn', buy_action:'Mua hàng',
  search_general:'Tìm kiếm', search_shop:'Gian hàng',
  search_dish:'Tìm món', family_group:'Gia đình', unknown:'...',
};

function buildQueryAnalysisPanel(qa) {
  if (!qa) return '';

  const uid = 'qa-' + Math.random().toString(36).slice(2, 8);
  let rows = '';

  // search_query
  if (qa.search_query) {
    rows += `<div class="qa-row">
      <span class="qa-label">🔍 Query</span>
      <span class="qa-value">${esc(qa.search_query)}</span>
    </div>`;
  }

  // exclude_terms
  if (qa.exclude_terms && qa.exclude_terms.length > 0) {
    const pills = qa.exclude_terms.map(t => `<span class="qa-pill">✕ ${esc(t)}</span>`).join('');
    rows += `<div class="qa-row">
      <span class="qa-label">🚫 Loại trừ</span>
      <span class="qa-value">${pills}</span>
    </div>`;
  }

  // entities
  if (qa.entities && Object.keys(qa.entities).length > 0) {
    const pills = Object.entries(qa.entities)
      .map(([k, v]) => `<span class="qa-entity-pill">${esc(k)}: ${esc(v)}</span>`)
      .join('');
    rows += `<div class="qa-row">
      <span class="qa-label">🎯 Entities</span>
      <span class="qa-value">${pills}</span>
    </div>`;
  }

  if (!rows) return '';

  return `
    <div class="qa-panel">
      <div class="qa-header" onclick="toggleQA('${uid}')">
        <span>🧠 LLM hiểu câu hỏi như thế nào</span>
        <span class="qa-toggle" id="toggle-${uid}">▶</span>
      </div>
      <div class="qa-body" id="${uid}">${rows}</div>
    </div>`;
}

function toggleQA(uid) {
  const body = document.getElementById(uid);
  const toggle = document.getElementById('toggle-' + uid);
  const open = body.classList.toggle('open');
  toggle.textContent = open ? '▼' : '▶';
  toggle.style.transform = open ? 'rotate(0)' : '';
}

function renderBotMsg(data) {
  const msgs = document.getElementById('msgs');
  const div = document.createElement('div');
  div.className = 'msg bot';

  const isShop = data.intent === 'search_shop';
  const tagClass = isShop ? 'intent-tag shop-tag' : 'intent-tag';
  const tagIcon = isShop ? '🏪' : '🍽️';

  // Query analysis panel
  const qaHTML = buildQueryAnalysisPanel(data.query_analysis);

  // Dishes section
  let dishesHTML = '';
  if (data.dishes && data.dishes.length > 0) {
    const cards = data.dishes.map((d, i) => buildDishCard(d, i)).join('');
    dishesHTML = `
      <div class="dishes-section">
        <div class="section-header">🍽️ Tìm thấy ${data.total_found} món ăn</div>
        <div class="dishes-grid">${cards}</div>
      </div>`;
  }

  // Shops section
  let shopsHTML = '';
  if (data.shops && data.shops.length > 0) {
    const cards = data.shops.map(s => buildShopCard(s)).join('');
    shopsHTML = `
      <div class="dishes-section">
        <div class="section-header">🏪 ${data.shops.length} gian hàng phù hợp</div>
        <div class="shops-grid">${cards}</div>
      </div>`;
  }

  div.innerHTML = `
    <div class="av">🍜</div>
    <div class="bubble">
      <span class="${tagClass}">${tagIcon} ${INTENT_LABELS[data.intent] || data.intent}</span>
      ${qaHTML}
      <div class="reply-box">${fmtReply(data.reply)}</div>
      ${dishesHTML}
      ${shopsHTML}
    </div>`;

  msgs.appendChild(div);
  scrollBot();
}

function buildDishCard(dish, idx) {
  const imgHTML = dish.image_url
    ? `<img src="${esc(dish.image_url)}" alt="${esc(dish.dish_name)}" loading="lazy" onerror="this.parentElement.innerHTML='<div class=dcard-placeholder>🍽️</div>'">`
    : '<div class="dcard-placeholder">🍽️</div>';
  const cal = dish.calories ? `${Math.round(dish.calories)} kcal` : '';
  const ings = dish.recipe?.ingredients?.slice(0, 4).join(', ') || '';
  const dishJson = JSON.stringify(dish).replace(/'/g, "&#39;");
  const detailUrl = dish.detail_url || (dish.detail_path ? `${API}${dish.detail_path}` : '');

  return `
    <div class="dcard" onclick='openRecipeFromDish(${dishJson})'>
      <div class="dcard-img">
        ${imgHTML}
        ${cal ? `<span class="cal-pill">🔥 ${cal}</span>` : ''}
      </div>
      <div class="dcard-body">
        <div class="dcard-name">${esc(dish.dish_name)}</div>
        <div class="dcard-tags">
          ${dish.cooking_time ? `<span class="dtag">⏱ ${esc(dish.cooking_time)}</span>` : ''}
          ${dish.level ? `<span class="dtag">📊 ${esc(dish.level)}</span>` : ''}
          ${dish.servings ? `<span class="dtag">👥 ${esc(dish.servings)}</span>` : ''}
        </div>
        ${ings ? `<div class="dcard-ing">🧅 ${esc(ings)}</div>` : ''}
        ${detailUrl ? `<a class="buy-btn" href="${esc(detailUrl)}" target="_blank" rel="noopener" onclick="event.stopPropagation()">🔗 Xem chi tiết món</a>` : ''}
        ${dish.buy_action ? `<button class="buy-btn" onclick="event.stopPropagation();buyDish('${esc(dish.buy_action.dish_id)}','${esc(dish.dish_name)}')">🛒 Mua nguyên liệu</button>` : ''}
      </div>
    </div>`;
}

function buildShopCard(s) {
  const items = s.goods || s.ingredients_available || [];
  const goodsHTML = items.slice(0, 6).map(g => `
    <div class="good-pill">
      ${esc(g.ingredient_name)}
      <span class="good-price">${(g.price||0).toLocaleString('vi-VN')}đ/${esc(g.unit||'')}</span>
      ${g.discount > 0 ? `<span class="good-disc">-${g.discount}%</span>` : ''}
    </div>`).join('');

  const imgTag = s.stall_image
    ? `<img src="${esc(s.stall_image)}" alt="${esc(s.stall_name)}">`
    : '🏪';

  return `
    <div class="scard">
      <div class="scard-top">
        <div class="scard-img">${imgTag}</div>
        <div class="scard-info">
          <div class="scard-name">${esc(s.stall_name)}</div>
          <div class="scard-meta">
            <span class="rating">⭐ ${(s.avr_rating||0).toFixed(1)}</span>
            ${s.stall_location ? `· <span>📍 ${esc(s.stall_location)}</span>` : ''}
          </div>
        </div>
      </div>
      ${items.length > 0 ? `
        <div style="font-size:11px;color:var(--muted);margin-bottom:6px;font-weight:500">
          Đang bán (${items.length} sản phẩm):
        </div>
        <div class="scard-goods">${goodsHTML}</div>` : ''}
    </div>`;
}

// ─── Recipe Modal ────────────────────────────────────────
function openRecipeFromDish(dish) {
  document.getElementById('modalTitle').textContent = dish.dish_name;
  const recipe = dish.recipe || {};
  let body = '';

  body += '<div class="meta-row">';
  if (dish.calories) body += `<div class="meta-chip">🔥 ${Math.round(dish.calories)} kcal</div>`;
  if (dish.cooking_time) body += `<div class="meta-chip">⏱ ${esc(dish.cooking_time)}</div>`;
  if (dish.level) body += `<div class="meta-chip">📊 ${esc(dish.level)}</div>`;
  if (dish.servings) body += `<div class="meta-chip">👥 ${esc(dish.servings)}</div>`;
  if (dish.health_goal) body += `<div class="meta-chip">🎯 ${esc(dish.health_goal)}</div>`;
  body += '</div>';

  if (recipe.ingredients && recipe.ingredients.length > 0) {
    body += `<div class="rsec">
      <h3>🧅 Nguyên liệu <span style="font-size:11px;color:var(--muted);font-weight:400">(nhấn để xem gian hàng)</span></h3>
      <ul>${recipe.ingredients.map(ing => `
        <li onclick="showStallsForIngredient('${esc(ing)}', this)">
          <span style="flex:1">${esc(ing)}</span>
          <span style="font-size:11px;color:var(--accent)">🏪 Tìm mua →</span>
        </li>`).join('')}
      </ul>
    </div>`;
  }

  if (recipe.preparation)
    body += `<div class="rsec"><h3>🔪 Sơ chế</h3><div class="rtext">${esc(recipe.preparation)}</div></div>`;
  if (recipe.steps)
    body += `<div class="rsec"><h3>👨‍🍳 Các bước nấu</h3><div class="rtext">${esc(recipe.steps)}</div></div>`;
  if (recipe.serving_tips)
    body += `<div class="rsec"><h3>🍽️ Cách dùng</h3><div class="rtext">${esc(recipe.serving_tips)}</div></div>`;

  const detailUrl = dish.detail_url || (dish.detail_path ? `${API}${dish.detail_path}` : '');
  body += `${detailUrl ? `<a class="modal-buy-btn" href="${esc(detailUrl)}" target="_blank" rel="noopener" style="display:inline-flex;justify-content:center;text-decoration:none;margin-bottom:10px">🔗 Xem đường dẫn món ăn</a>` : ''}
    <button class="modal-buy-btn" onclick="loadStalls('${esc(dish.dish_id)}', this, false)">
      🛒 Xem gian hàng bán nguyên liệu
    </button>
    <div id="stalls-${esc(dish.dish_id)}"></div>`;

  document.getElementById('modalBody').innerHTML = body;
  document.getElementById('modal').style.display = 'flex';
  document.body.style.overflow = 'hidden';
}

function closeModal() {
  document.getElementById('modal').style.display = 'none';
  document.body.style.overflow = '';
}

function closeModalOutside(e) {
  if (e.target === document.getElementById('modal')) closeModal();
}

document.addEventListener('keydown', e => { if (e.key === 'Escape') closeModal(); });

// ─── Stalls loaders ──────────────────────────────────────
async function loadStalls(dishId, btnEl, openModal) {
  if (openModal) {
    showToast('⏳ Đang tìm gian hàng...');
    try {
      const res = await fetch(`${API}/dishes/${dishId}/stalls`);
      const data = await res.json();
      if (data.stalls && data.stalls.length > 0) {
        renderStallsInChat(data.stalls, dishId);
        showToast(`🏪 Tìm thấy ${data.stalls.length} gian hàng!`);
      } else {
        showToast('😔 Chưa có gian hàng bán nguyên liệu món này.');
      }
    } catch (e) { showToast('Lỗi: ' + e.message); }
    return;
  }

  const container = document.getElementById(`stalls-${dishId}`);
  if (!container) return;
  btnEl.disabled = true;
  btnEl.innerHTML = '<span class="spin"></span> Đang tìm gian hàng...';

  try {
    const res = await fetch(`${API}/dishes/${dishId}/stalls`);
    const data = await res.json();
    btnEl.style.display = 'none';
    if (!data.stalls || data.stalls.length === 0) {
      container.innerHTML = `<p style="color:var(--muted);font-size:13px;margin-top:10px">Chưa có gian hàng bán nguyên liệu món này.</p>`;
      return;
    }
    container.innerHTML = `
      <div style="margin-top:14px">
        <div class="section-header" style="margin-bottom:10px">🏪 ${data.total_stalls} gian hàng có nguyên liệu</div>
        <div class="shops-grid">${data.stalls.map(s => buildShopCard(s)).join('')}</div>
      </div>`;
  } catch (err) {
    container.innerHTML = `<p style="color:var(--red);font-size:13px;margin-top:8px">Lỗi: ${err.message}</p>`;
    btnEl.disabled = false;
    btnEl.innerHTML = '🛒 Xem gian hàng bán nguyên liệu';
  }
}

function renderStallsInChat(stalls, dishId) {
  const msgs = document.getElementById('msgs');
  const div = document.createElement('div');
  div.className = 'msg bot';
  div.innerHTML = `
    <div class="av">🏪</div>
    <div class="bubble">
      <span class="intent-tag shop-tag">🏪 Gian hàng</span>
      <div class="reply-box" style="margin-bottom:12px">
        Tìm thấy <strong>${stalls.length}</strong> gian hàng có nguyên liệu cho món bạn chọn:
      </div>
      <div class="shops-grid">${stalls.map(s => buildShopCard(s)).join('')}</div>
    </div>`;
  msgs.appendChild(div);
  scrollBot();
}

async function showStallsForIngredient(name, liEl) {
  const existing = liEl.nextElementSibling;
  if (existing && existing.classList.contains('stall-panel')) { existing.remove(); return; }

  const panel = document.createElement('div');
  panel.className = 'stall-panel';
  panel.innerHTML = `<div style="color:var(--muted);font-size:12.5px">⏳ Đang tìm gian hàng bán <strong>${esc(name)}</strong>...</div>`;
  liEl.insertAdjacentElement('afterend', panel);

  try {
    const res = await fetch(`${API}/ingredients/stalls?name=${encodeURIComponent(name)}`);
    const data = await res.json();

    if (!data.stalls || data.stalls.length === 0) {
      panel.innerHTML = `<div style="color:var(--muted);font-size:12.5px">😔 Chưa có gian hàng bán <strong>${esc(name)}</strong></div>`;
      return;
    }

    panel.innerHTML = `
      <div style="font-size:11.5px;font-weight:600;color:var(--muted);margin-bottom:8px">
        🏪 ${data.total_stalls} gian hàng bán <strong style="color:var(--text)">${esc(name)}</strong>
      </div>
      ${data.stalls.map(s => `
        <div style="display:flex;align-items:center;gap:10px;padding:7px 0;border-bottom:1px solid var(--border)">
          <div style="width:34px;height:34px;border-radius:7px;overflow:hidden;background:var(--s3);flex-shrink:0;display:flex;align-items:center;justify-content:center;font-size:17px">
            ${s.stall_image ? `<img src="${esc(s.stall_image)}" style="width:100%;height:100%;object-fit:cover">` : '🏪'}
          </div>
          <div style="flex:1;min-width:0">
            <div style="font-size:12.5px;font-weight:600">${esc(s.stall_name)}</div>
            <div style="font-size:11px;color:var(--muted)">⭐ ${(s.avr_rating||0).toFixed(1)} · ${esc(s.stall_location||'')}</div>
          </div>
          <div style="text-align:right;flex-shrink:0">
            <div style="font-size:13px;font-weight:700;color:var(--accent)">${(s.price||0).toLocaleString('vi-VN')}đ/${esc(s.unit||'')}</div>
            ${s.discount > 0 ? `<div style="font-size:11px;color:var(--green)">-${s.discount}% giảm giá</div>` : ''}
            <div style="font-size:11px;color:var(--muted)">Còn ${s.inventory||0} ${esc(s.unit||'')}</div>
          </div>
        </div>`).join('')}`;
  } catch (err) {
    panel.innerHTML = `<div style="color:var(--red);font-size:12.5px">Lỗi: ${err.message}</div>`;
  }
}

function buyDish(dishId, dishName) {
  showToast(`Đã thêm "${dishName}" vào giỏ hàng!`);
}

// ─── Utils ───────────────────────────────────────────────
function esc(str) {
  if (!str) return '';
  const d = document.createElement('div');
  d.textContent = String(str);
  return d.innerHTML;
}

function fmtReply(text) {
  if (!text) return '';
  let h = esc(text);
  h = h.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');
  h = h.replace(/\n/g, '<br>');
  return h;
}

function scrollBot() {
  const el = document.getElementById('chatScroll');
  requestAnimationFrame(() => { el.scrollTop = el.scrollHeight; });
}

function showToast(msg) {
  let t = document.getElementById('toast');
  if (!t) { t = document.createElement('div'); t.id='toast'; t.className='toast'; document.body.appendChild(t); }
  t.textContent = msg;
  t.classList.add('show');
  setTimeout(() => t.classList.remove('show'), 2800);
}
