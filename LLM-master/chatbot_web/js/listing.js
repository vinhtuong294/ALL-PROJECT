// ═══ LISTING PAGE ═══════════════════════════════════════════
// State
let dishesData = [];
let shopsData  = [];
let currentTab = 'dishes';
let currentPage = 1;
const ITEMS_PER_PAGE = 100;
let filteredResults = [];
let selectedItem = null;

const filters = {
  dishes: { healthGoal: '', difficulties: [], maxTime: null, minCal: null, maxCal: null },
  shops:  { minRating: 0, priceRanges: [], productType: '' },
};

const API = 'http://localhost:8000';

// ─── INIT ──────────────────────────────────────────────────
window.addEventListener('DOMContentLoaded', async () => {
  document.getElementById('resultsGrid').innerHTML =
    '<div class="listing-loading">Đang tải dữ liệu...</div>';

  try {
    const [dishRes, shopRes] = await Promise.all([
      fetch(`${API}/dishes/search?limit=1000`).then(r => r.json()),
      fetch(`${API}/stalls/search?limit=1000`).then(r => r.json()),
    ]);
    dishesData = dishRes.dishes || [];
    shopsData  = shopRes.stalls  || [];
    console.log(`[Listing] ${dishesData.length} dishes, ${shopsData.length} shops`);

    renderFiltersPanel();
    applyFilters();
  } catch (err) {
    document.getElementById('resultsGrid').innerHTML =
      `<div class="listing-loading" style="color:var(--red)">
         Lỗi tải dữ liệu: ${esc(err.message)}<br>
         <span style="font-size:12px;color:var(--muted)">Kiểm tra API ${API}</span>
       </div>`;
  }
});

// ─── TAB ───────────────────────────────────────────────────
function switchListingTab(tab) {
  currentTab = tab;
  currentPage = 1;
  document.querySelectorAll('.listing-tab').forEach(b =>
    b.classList.toggle('active', b.dataset.tab === tab));
  renderFiltersPanel();
  applyFilters();
}

// ─── FILTERS PANEL ─────────────────────────────────────────
function renderFiltersPanel() {
  const p = document.getElementById('filtersPanel');

  if (currentTab === 'dishes') {
    p.innerHTML = `
      <div class="filter-group">
        <label class="filter-label">Mục tiêu sức khỏe</label>
        <select class="filter-select" id="fHealthGoal" onchange="onFilter()">
          <option value="">Tất cả</option>
          <option value="Dinh dưỡng cân bằng">⚖️ Cân bằng</option>
          <option value="Giảm cân">🥗 Giảm cân</option>
          <option value="Tăng cân">💪 Tăng cân</option>
          <option value="Tăng cơ">🏋️ Tăng cơ</option>
          <option value="Sức đề kháng">🛡️ Sức đề kháng</option>
        </select>
      </div>
      <div class="filter-group">
        <label class="filter-label">Độ khó</label>
        <div class="filter-buttons" id="diffBtns">
          <button class="filter-btn" onclick="togDiff(this,'Dễ')">Dễ</button>
          <button class="filter-btn" onclick="togDiff(this,'Trung bình')">Trung bình</button>
          <button class="filter-btn" onclick="togDiff(this,'Khó')">Khó</button>
        </div>
      </div>
      <div class="filter-group">
        <label class="filter-label">Thời gian nấu (phút)</label>
        <input type="number" class="filter-input" id="fMaxTime"
               placeholder="Tối đa" min="0" max="180" onchange="onFilter()">
      </div>
      <div class="filter-group">
        <label class="filter-label">Calo tối thiểu</label>
        <input type="number" class="filter-input" id="fMinCal"
               placeholder="Min" min="0" onchange="onFilter()">
      </div>
      <div class="filter-group">
        <label class="filter-label">Calo tối đa</label>
        <input type="number" class="filter-input" id="fMaxCal"
               placeholder="Max" min="0" onchange="onFilter()">
      </div>
      <button class="filter-clear" onclick="clearAllFilters()">Xóa bộ lọc</button>`;
  } else {
    p.innerHTML = `
      <div class="filter-group">
        <label class="filter-label">Đánh giá tối thiểu</label>
        <select class="filter-select" id="fMinRating" onchange="onFilter()">
          <option value="0">Tất cả</option>
          <option value="3">⭐ 3.0+</option>
          <option value="3.5">⭐ 3.5+</option>
          <option value="4">⭐ 4.0+</option>
          <option value="4.5">⭐ 4.5+</option>
        </select>
      </div>
      <div class="filter-group">
        <label class="filter-label">Loại hàng</label>
        <input type="text" class="filter-input" id="fProductType"
               placeholder="Thịt, hải sản, rau..." oninput="onFilter()">
      </div>
      <button class="filter-clear" onclick="clearAllFilters()">Xóa bộ lọc</button>`;
  }
}

// ─── FILTER HANDLERS ───────────────────────────────────────
function onFilter() {
  if (currentTab === 'dishes') {
    const f = filters.dishes;
    f.healthGoal = val('fHealthGoal');
    f.maxTime    = numVal('fMaxTime');
    f.minCal     = numVal('fMinCal');
    f.maxCal     = numVal('fMaxCal');
  } else {
    const f = filters.shops;
    f.minRating   = parseFloat(val('fMinRating')) || 0;
    f.productType = val('fProductType');
  }
  currentPage = 1;
  applyFilters();
}

function togDiff(btn, level) {
  const arr = filters.dishes.difficulties;
  const i = arr.indexOf(level);
  if (i > -1) arr.splice(i, 1); else arr.push(level);
  btn.classList.toggle('active');
  currentPage = 1;
  applyFilters();
}

function clearAllFilters() {
  if (currentTab === 'dishes') {
    filters.dishes = { healthGoal:'', difficulties:[], maxTime:null, minCal:null, maxCal:null };
  } else {
    filters.shops = { minRating:0, priceRanges:[], productType:'' };
  }
  renderFiltersPanel();
  currentPage = 1;
  applyFilters();
}

// ─── APPLY FILTERS ─────────────────────────────────────────
function applyFilters() {
  if (currentTab === 'dishes') {
    const f = filters.dishes;
    filteredResults = dishesData.filter(d => {
      if (f.healthGoal && d.health_goal !== f.healthGoal) return false;
      if (f.difficulties.length && !f.difficulties.includes(d.level)) return false;
      if (f.maxTime) {
        const t = parseTime(d.cooking_time);
        if (t && t > f.maxTime) return false;
      }
      if (f.minCal && d.calories < f.minCal) return false;
      if (f.maxCal && d.calories > f.maxCal) return false;
      return true;
    });
  } else {
    const f = filters.shops;
    filteredResults = shopsData.filter(s => {
      if (f.minRating && (s.avr_rating || 0) < f.minRating) return false;
      if (f.productType) {
        const kw = f.productType.toLowerCase();
        const goods = (s.goods || []).map(g => g.ingredient_name.toLowerCase()).join(' ');
        if (!goods.includes(kw)) return false;
      }
      return true;
    });
  }

  renderResults();
  renderPagination();
  updateCount();
}

// ─── RENDER RESULTS ────────────────────────────────────────
function renderResults() {
  const grid  = document.getElementById('resultsGrid');
  const empty = document.getElementById('emptyState');

  if (!filteredResults.length) {
    grid.style.display  = 'none';
    empty.style.display = 'block';
    return;
  }
  grid.style.display  = 'grid';
  empty.style.display = 'none';

  const start = (currentPage - 1) * ITEMS_PER_PAGE;
  const page  = filteredResults.slice(start, start + ITEMS_PER_PAGE);

  grid.innerHTML = page.map(item =>
    currentTab === 'dishes' ? dishCard(item) : shopCard(item)
  ).join('');
}

function dishCard(d) {
  const time = d.cooking_time || '?';
  const cal  = d.calories ? Math.round(d.calories) : '?';
  const ragContext = d.rag_context || '';
  return `
    <div class="listing-card" onclick="showDishDetail(event)">
      <div class="card-emoji">🍳</div>
      <div class="card-title">${esc(d.dish_name)}</div>
      <div class="card-meta">
        <div class="card-meta-item">🏥 ${esc(d.health_goal || '—')}</div>
        <div class="card-meta-item">⏱️ ${esc(String(time))}</div>
        <div class="card-meta-item">🔥 ${cal} kcal</div>
        <div class="card-meta-item">📊 ${esc(d.level || '—')}</div>
      </div>
      ${d.recipe && d.recipe.ingredients ? `
        <div class="card-tags">
          ${d.recipe.ingredients.slice(0,3).map(i =>
            `<span class="card-tag">${esc(i)}</span>`).join('')}
          ${d.recipe.ingredients.length > 3 ? `<span class="card-tag">+${d.recipe.ingredients.length-3}</span>` : ''}
        </div>` : ''}
      ${ragContext ? `
        <div class="card-rag-context">
          <div class="card-rag-label">RAG context</div>
          <div class="card-rag-text">${esc(ragContext)}</div>
        </div>` : ''}
      <div style="display:none">${esc(JSON.stringify(d))}</div>
    </div>`;
}

function shopCard(s) {
  const rating = s.avr_rating ? `⭐ ${s.avr_rating}` : '—';
  const goods  = (s.goods || []).slice(0,3);
  return `
    <div class="listing-card" onclick="showShopDetail(event)">
      <div class="card-emoji">🏪</div>
      <div class="card-title">${esc(s.stall_name)}</div>
      <div class="card-meta">
        <div class="card-meta-item card-rating">${rating}</div>
        ${s.stall_location ? `<div class="card-meta-item">📍 ${esc(s.stall_location)}</div>` : ''}
        <div class="card-meta-item">📦 ${s.total_goods || 0} sản phẩm</div>
      </div>
      <div class="card-tags">
        ${goods.map(g =>
          `<span class="card-tag">${esc(g.ingredient_name)}</span>`).join('')}
        ${(s.goods||[]).length > 3 ? `<span class="card-tag">+${s.goods.length-3}</span>` : ''}
      </div>
      <div style="display:none">${esc(JSON.stringify(s))}</div>
    </div>`;
}

// ─── PAGINATION ────────────────────────────────────────────
function renderPagination() {
  const ctl   = document.getElementById('paginationControls');
  const total = Math.ceil(filteredResults.length / ITEMS_PER_PAGE);

  if (filteredResults.length <= ITEMS_PER_PAGE) {
    ctl.style.display = 'none';
    return;
  }
  ctl.style.display = 'flex';

  const start = (currentPage - 1) * ITEMS_PER_PAGE + 1;
  const end   = Math.min(currentPage * ITEMS_PER_PAGE, filteredResults.length);

  let opts = '';
  for (let i = 1; i <= total; i++)
    opts += `<option value="${i}" ${i===currentPage?'selected':''}>Trang ${i}</option>`;

  ctl.innerHTML = `
    <button class="pagination-btn" onclick="goPage(${currentPage-1})" ${currentPage===1?'disabled':''}>← Trước</button>
    <select class="pagination-select" onchange="goPage(+this.value)">${opts}</select>
    <button class="pagination-btn" onclick="goPage(${currentPage+1})" ${currentPage===total?'disabled':''}>Tiếp →</button>
    <div class="pagination-info">Hiển thị ${start}-${end} / ${filteredResults.length} kết quả</div>`;
}

function goPage(p) {
  const total = Math.ceil(filteredResults.length / ITEMS_PER_PAGE);
  if (p < 1 || p > total) return;
  currentPage = p;
  renderResults();
  renderPagination();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

// ─── UTILS ─────────────────────────────────────────────────
function updateCount() {
  document.getElementById('resultCount').textContent =
    `${filteredResults.length} kết quả tìm thấy`;
}

function parseTime(str) {
  if (!str) return null;
  const m = String(str).match(/(\d+)/);
  return m ? parseInt(m[1]) : null;
}

function val(id)    { const el = document.getElementById(id); return el ? el.value : ''; }
function numVal(id) { const v = parseFloat(val(id)); return isNaN(v) ? null : v; }

function esc(text) {
  if (!text) return '';
  const d = document.createElement('div');
  d.textContent = text;
  return d.innerHTML;
}

// ─── DETAIL MODAL ──────────────────────────────────────────
function showDishDetail(e) {
  const card = e.currentTarget;
  const data = JSON.parse(card.querySelector('div[style*="display:none"]').textContent);
  const html = `
    <h2 style="margin:0 0 16px;font-size:20px;color:var(--fg)">${esc(data.dish_name)}</h2>

    <div class="detail-section">
      <div class="detail-title">Thông tin cơ bản</div>
      <div class="detail-info">
        <div class="detail-info-label">🏥 Mục tiêu:</div>
        <div class="detail-info-value">${esc(data.health_goal || '—')}</div>
      </div>
      <div class="detail-info">
        <div class="detail-info-label">📊 Độ khó:</div>
        <div class="detail-info-value">${esc(data.level || '—')}</div>
      </div>
      <div class="detail-info">
        <div class="detail-info-label">⏱️ Thời gian:</div>
        <div class="detail-info-value">${esc(String(data.cooking_time || '?'))} phút</div>
      </div>
      <div class="detail-info">
        <div class="detail-info-label">🔥 Calo:</div>
        <div class="detail-info-value">${data.calories ? Math.round(data.calories) : '?'} kcal</div>
      </div>
      <div class="detail-info">
        <div class="detail-info-label">🍽️ Suất:</div>
        <div class="detail-info-value">${esc(data.servings || '—')}</div>
      </div>
    </div>

    ${data.rag_context ? `
      <div class="detail-section">
        <div class="detail-title">RAG context</div>
        <div class="detail-content detail-rag-context">${esc(data.rag_context)}</div>
      </div>
    ` : ''}

    ${data.recipe && data.recipe.ingredients ? `
      <div class="detail-section">
        <div class="detail-title">Nguyên liệu (${data.recipe.ingredients.length})</div>
        <div class="detail-ingredients">
          ${data.recipe.ingredients.map(i => `<span class="detail-tag">✓ ${esc(i)}</span>`).join('')}
        </div>
      </div>
    ` : ''}

    ${data.recipe && data.recipe.preparation ? `
      <div class="detail-section">
        <div class="detail-title">Chuẩn bị</div>
        <div class="detail-content">${esc(data.recipe.preparation)}</div>
      </div>
    ` : ''}

    ${data.recipe && data.recipe.steps ? `
      <div class="detail-section">
        <div class="detail-title">Các bước thực hiện</div>
        <div class="detail-content">${esc(data.recipe.steps)}</div>
      </div>
    ` : ''}

    ${data.recipe && data.recipe.serving_tips ? `
      <div class="detail-section">
        <div class="detail-title">Mẹo thưởng thức</div>
        <div class="detail-content">${esc(data.recipe.serving_tips)}</div>
      </div>
    ` : ''}
  `;

  document.getElementById('detailBody').innerHTML = html;
  document.getElementById('detailModal').style.display = 'block';
}

function showShopDetail(e) {
  const card = e.currentTarget;
  const data = JSON.parse(card.querySelector('div[style*="display:none"]').textContent);
  const rating = data.avr_rating ? `⭐ ${data.avr_rating}/5` : '—';
  const html = `
    <h2 style="margin:0 0 16px;font-size:20px;color:var(--fg)">${esc(data.stall_name)}</h2>

    <div class="detail-section">
      <div class="detail-title">Thông tin cửa hàng</div>
      <div class="detail-info">
        <div class="detail-info-label">⭐ Đánh giá:</div>
        <div class="detail-info-value">${rating}</div>
      </div>
      <div class="detail-info">
        <div class="detail-info-label">📍 Địa chỉ:</div>
        <div class="detail-info-value">${esc(data.stall_location || '—')}</div>
      </div>
      <div class="detail-info">
        <div class="detail-info-label">📦 Sản phẩm:</div>
        <div class="detail-info-value">${data.total_goods || 0} mặt hàng</div>
      </div>
    </div>

    ${data.goods && data.goods.length > 0 ? `
      <div class="detail-section">
        <div class="detail-title">Mặt hàng bán (${data.goods.length})</div>
        <div class="detail-ingredients">
          ${data.goods.map(g => `
            <div style="width:100%;padding:8px;background:var(--bg);border-radius:6px;font-size:12px">
              <div style="font-weight:500;color:var(--fg)">${esc(g.ingredient_name)}</div>
              <div style="color:var(--muted);font-size:11px;margin-top:3px">
                💰 ${g.price ? (g.price/1000).toFixed(0) + 'k' : '?'} / ${esc(g.unit || 'cái')}
                ${g.discount ? ` | Giảm: ${g.discount}%` : ''}
              </div>
            </div>
          `).join('')}
        </div>
      </div>
    ` : ''}
  `;

  document.getElementById('detailBody').innerHTML = html;
  document.getElementById('detailModal').style.display = 'block';
}

function closeDetail() {
  document.getElementById('detailModal').style.display = 'none';
}
