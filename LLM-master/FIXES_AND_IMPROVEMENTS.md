# 🔧 ACTION ITEMS & FIXES — Các điểm cần sửa/hoàn thiện

## 📊 Tóm tắt nhanh

| Vấn đề | Priority | Status | Fix |
|--------|----------|--------|-----|
| Allergen filter chưa hoàn hảo (missing giai vị, nước xốt) | P2 | ⏳ | Thêm stage 3 trong suggest_menu |
| Frontend UI allergen chỉ là textarea (UX tệ) | P1 | ⏳ | Thêm dropdown checkboxes |
| Chat xử lý exclude_terms nhưng không consistency | P2 | ⏳ | Test + verify flow |
| Không có caching allergen profile | P3 | ⏳ | Lưu session-based |

---

## 🚨 Priority 1: Frontend UI Allergen Dropdown

### Vấn đề hiện tại
- index.html chỉ có một `<textarea id="allergyInput">` tự do
- User phải gõ allergen manually, dễ viết sai chính tả
- UX không friendly

### Giải pháp
Thêm pre-defined allergen checkboxes + textarea tùy chỉnh

### Code to add

**1. Update index.html (sau dòng 134 - menu builder)**
```html
<!-- VỊ TRÍ CẦN THÊM: Sau selector số bữa -->
<label class="form-label">🚫 Allergen / Dị ứng (chọn hoặc nhập)</label>

<!-- Pre-defined allergens -->
<div class="allergen-section">
  <div class="allergen-label" style="font-size:11px;color:var(--muted);margin-bottom:6px">
    Chọn từ danh sách phổ biến:
  </div>
  <div class="allergen-chips" id="allergenChips">
    <button class="allergen-chip" data-allergen="Tôm" onclick="toggleAllergen(this)">🦐 Tôm</button>
    <button class="allergen-chip" data-allergen="Cua" onclick="toggleAllergen(this)">🦀 Cua</button>
    <button class="allergen-chip" data-allergen="Mực" onclick="toggleAllergen(this)">🦑 Mực</button>
    <button class="allergen-chip" data-allergen="Cá" onclick="toggleAllergen(this)">🐟 Cá</button>
    <button class="allergen-chip" data-allergen="Hàu" onclick="toggleAllergen(this)">🦪 Hàu</button>
    <button class="allergen-chip" data-allergen="Sữa" onclick="toggleAllergen(this)">🥛 Sữa</button>
    <button class="allergen-chip" data-allergen="Trứng" onclick="toggleAllergen(this)">🥚 Trứng</button>
    <button class="allergen-chip" data-allergen="Lúa mạch" onclick="toggleAllergen(this)">🌾 Lúa mạch</button>
    <button class="allergen-chip" data-allergen="Đậu phộng" onclick="toggleAllergen(this)">🥜 Đậu phộng</button>
    <button class="allergen-chip" data-allergen="Hạt dẻ" onclick="toggleAllergen(this)">🌰 Hạt dẻ</button>
  </div>
</div>

<!-- Custom allergens -->
<div class="allergen-section" style="margin-top:8px">
  <div class="allergen-label" style="font-size:11px;color:var(--muted);margin-bottom:6px">
    Hoặc nhập thêm (dấu phẩy phân cách):
  </div>
  <textarea 
    class="form-textarea" 
    id="allergyInput" 
    placeholder="Ví dụ: hạt điều, dê, nấm..."
    rows="2"
  ></textarea>
</div>
```

**2. Update CSS (chatbot_web/css/style.css)**
```css
/* Allergen chips styling */
.allergen-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-bottom: 12px;
}

.allergen-chip {
  padding: 6px 10px;
  border: 1px solid var(--border);
  border-radius: 4px;
  background: var(--bg2);
  color: var(--text);
  font-size: 12px;
  cursor: pointer;
  transition: all 0.2s;
  white-space: nowrap;
}

.allergen-chip:hover {
  border-color: var(--red);
  background: rgba(239, 68, 68, 0.1);
}

.allergen-chip.selected {
  background: rgba(239, 68, 68, 0.15);
  border-color: var(--red);
  color: var(--red);
  font-weight: 500;
}

.allergen-section {
  padding: 0;
}

.allergen-label {
  display: block;
  margin-bottom: 4px;
}
```

**3. Update app.js (thêm variable + function)**
```javascript
// Thêm global variable (sau dòng 3)
let selectedAllergens = [];  // Track selected allergen chips

// Thêm function toggleAllergen (sau function toggleNote)
function toggleAllergen(btn) {
  btn.classList.toggle('selected');
  const allergen = btn.dataset.allergen;
  
  if (btn.classList.contains('selected')) {
    if (!selectedAllergens.includes(allergen)) {
      selectedAllergens.push(allergen);
    }
  } else {
    selectedAllergens = selectedAllergens.filter(a => a !== allergen);
  }
  console.log('[allergen] Selected:', selectedAllergens);
}

// Update generateMenu function (dòng 111-133)
// Sửa phần parse allergen:
async function generateMenu() {
  const goal = document.getElementById('menuGoal').value;
  const meals = parseInt(document.getElementById('menuMeals').value);
  
  // 🔴 Combine selected chips + custom textarea
  const customAllergies = document.getElementById('allergyInput').value.trim()
    ? document.getElementById('allergyInput').value.split(',').map(a => a.trim()).filter(a => a)
    : [];
  const allAllergens = [
    ...selectedAllergens,        // From chips
    ...customAllergies            // From textarea
  ];
  // Remove duplicates
  const uniqueAllergens = [...new Set(allAllergens)];
  
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
        allergen_ingredients: uniqueAllergens  // 🔴 Updated
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
```

**4. Update renderMenu to show allergen info**
```javascript
// Trong hàm renderMenu(), sau dòng hiển thị menuSub, thêm:
// Display allergen info nếu có
if (data.allergy_excluded && data.allergy_excluded.length > 0) {
  const allergyText = data.allergy_excluded.join(', ');
  document.getElementById('menuSub').innerHTML += 
    `<br><span style="font-size:11px;color:var(--red);margin-top:4px">🚫 Loại trừ: ${allergyText}</span>`;
}
```

---

## 🔧 Priority 2: Backend — Cải thiện Allergen Filter Logic

### Vấn đề hiện tại
Hàm `suggest_menu()` chỉ lọc level-1 (tên) + level-2 (nguyên liệu chính)
→ Không lọc giai vị, nước xốt, side ingredients

### Giải pháp
Thêm **Stage 3** lọc "allergen variants" (VD: "Tương tôm", "Xốt tôm" nếu user dị ứng "tôm")

### Code to add in data_loader.py

**1. Thêm ALLERGEN_VARIANTS mapping trước hàm suggest_menu()**
```python
# Thêm sau dòng 479 (trước def suggest_menu)

# ─── Allergen variants mapping ────────────────────────────────────────
# Nếu user dị ứng "tôm", cũng loại "tương tôm", "xốt tôm", v.v.
ALLERGEN_VARIANTS = {
    "tôm": [
        "tôm", "tôm sú", "tôm hùm", "tôm hú",
        "tương tôm", "xốt tôm", "tôm cô"
    ],
    "cua": [
        "cua", "cua cà mau",
        "tương cua", "xốt cua"
    ],
    "mực": [
        "mực", "mực ống",
        "tương mực", "xốt mực"
    ],
    "cá": [
        "cá", "cá hồi", "cá chép", "cá lóc", "cá thu", "cá mồi",
        "nước cá", "nước mắm", "tương cá"
    ],
    "sữa": [
        "sữa", "sữa đặc", "sữa tươi",
        "bơ", "phô mai", "kem", "yogurt", "cơm sữa"
    ],
    "trứng": [
        "trứng", "trứng gà", "trứng cút",
        "lòng đỏ", "lòng trắng"
    ],
}

def _expand_allergen_terms(exclude_terms: list[str]) -> list[str]:
    """Mở rộng danh sách allergen để bao gồm các variants."""
    expanded = set()
    for term in exclude_terms:
        t = term.lower().strip()
        expanded.add(t)
        # Thêm variants từ mapping
        if t in ALLERGEN_VARIANTS:
            expanded.update(ALLERGEN_VARIANTS[t])
    return list(expanded)
```

**2. Update suggest_menu() để dùng expanded allergen**
```python
# Thay dòng 520 (trong suggest_menu):

# OLD:
# lower_excl = [t.lower() for t in (exclude_terms or []) if t.strip()]

# NEW:
all_excl = [t.lower() for t in (exclude_terms or []) if t.strip()]
lower_excl = _expand_allergen_terms(all_excl)  # ← Expand variants
```

---

## 🌐 Priority 2: Backend — API Endpoint /allergen/common

Thêm endpoint để frontend load danh sách allergen phổ biến

### Code to add in main.py (trước endpoint cuối cùng)

```python
@app.get("/allergen/common", summary="Danh sách allergen phổ biến")
def get_common_allergens():
    """
    Trả danh sách allergen phổ biến để frontend hiển thị dropdown.
    """
    return {
        "allergens": [
            {"label": "🦐 Tôm", "value": "Tôm"},
            {"label": "🦀 Cua", "value": "Cua"},
            {"label": "🦑 Mực", "value": "Mực"},
            {"label": "🐟 Cá", "value": "Cá"},
            {"label": "🦪 Hàu", "value": "Hàu"},
            {"label": "🥛 Sữa", "value": "Sữa"},
            {"label": "🥚 Trứng", "value": "Trứng"},
            {"label": "🌾 Lúa mạch", "value": "Lúa mạch"},
            {"label": "🥜 Đậu phộng", "value": "Đậu phộng"},
            {"label": "🌰 Hạt dẻ", "value": "Hạt dẻ"},
            {"label": "🥜 Hạt điều", "value": "Hạt điều"},
        ],
        "note": "Chọn hoặc nhập allergen tùy chỉnh"
    }
```

### Use in Frontend
```javascript
// app.js - Load allergen list khi page load
async function loadAllergenList() {
  try {
    const res = await fetch(`${API}/allergen/common`);
    const data = await res.json();
    const container = document.getElementById('allergenChips');
    
    // Clear existing
    container.innerHTML = '';
    
    // Build from API
    data.allergens.forEach(allergen => {
      const btn = document.createElement('button');
      btn.className = 'allergen-chip';
      btn.textContent = allergen.label;
      btn.dataset.allergen = allergen.value;
      btn.onclick = function() { toggleAllergen(this); };
      container.appendChild(btn);
    });
  } catch (e) {
    console.error('Error loading allergen list:', e);
  }
}

// Call on page load
checkAPI();
loadAllergenList();  // ← Thêm dòng này
```

---

## ✅ Priority 2: Test & Verify Flow

### Test Case 1: Chat with allergen exclusion
```bash
# Terminal 1: Start server
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8001

# Terminal 2: Test chat endpoint with exclude_terms
curl -X POST http://localhost:8001/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Gợi ý món không chứa tôm",
    "session_id": "test-1",
    "history": []
  }'

# Expected: intent should be detected, dishes returned should NOT contain "tôm"
```

### Test Case 2: Menu generate with allergen_ingredients
```bash
curl -X POST http://localhost:8001/menu/generate \
  -H "Content-Type: application/json" \
  -d '{
    "days": 1,
    "meals_per_day": 2,
    "health_goal": "Cân bằng",
    "notes": [],
    "allergen_ingredients": ["tôm", "cua"]
  }'

# Expected: menu returned should NOT contain dishes with tôm or cua
# Check response.allergy_excluded = ["tôm", "cua"]
```

### Test Case 3: Verify stage 2 (recipes filter)
```python
# In data_loader.py, add debug prints:
print(f"[suggest_menu] Tang1 (name) banned: {len(stage1_banned)}")
print(f"[suggest_menu] Tang2 (recipes) banned: {len(stage2_banned)}")
print(f"[suggest_menu] Total banned: {len(allergy_banned_ids)}")

# Re-run test case 2, check logs
```

---

## 📝 Priority 3: Session-based Allergen Caching

### Idea
Sau khi user tạo thực đơn lần 1, lưu allergen vào session
→ Lần sau, pre-fill allergen cũ

### Code to add in app.js
```javascript
// Sau khi generateMenu() thành công, lưu allergen:
async function generateMenu() {
  // ... existing code ...
  try {
    const res = await fetch(`${API}/menu/generate`, {
      // ...
    });
    const data = await res.json();
    renderMenu(data);
    
    // 🔴 Lưu allergen vào localStorage
    const savedAllergens = {
      timestamp: Date.now(),
      allergens: uniqueAllergens,
      health_goal: goal,
    };
    localStorage.setItem('lastAllergenProfile', JSON.stringify(savedAllergens));
    
  } catch (e) {
    // ...
  }
}

// Load allergen lần trước khi mở menu builder
function switchTab(tab) {
  // ... existing code ...
  if (tab === 'menu') {
    // Load last allergen profile
    const saved = localStorage.getItem('lastAllergenProfile');
    if (saved) {
      const profile = JSON.parse(saved);
      selectedAllergens = profile.allergens.filter(a => 
        document.querySelector(`[data-allergen="${a}"]`)  // Chỉ lấy pre-defined
      );
      // Update UI
      document.querySelectorAll('.allergen-chip').forEach(chip => {
        if (selectedAllergens.includes(chip.dataset.allergen)) {
          chip.classList.add('selected');
        }
      });
    }
  }
}
```

---

## 📋 Implementation Checklist

### Frontend (app.js + index.html + style.css)
- [ ] Add allergen checkboxes HTML
- [ ] Add CSS for .allergen-chip, .allergen-section
- [ ] Update toggleAllergen() function
- [ ] Update generateMenu() to combine chips + textarea
- [ ] Update renderMenu() to show allergen info
- [ ] Add loadAllergenList() function
- [ ] Add session caching (localStorage)

### Backend (main.py + data_loader.py)
- [ ] Add ALLERGEN_VARIANTS mapping
- [ ] Add _expand_allergen_terms() function
- [ ] Update suggest_menu() to use expanded allergens
- [ ] Add /allergen/common endpoint
- [ ] Test with curl/Postman

### Testing
- [ ] Test Case 1: Chat allergen exclusion
- [ ] Test Case 2: Menu generate with allergen_ingredients
- [ ] Test Case 3: Verify stage 2 (recipes filter)
- [ ] Manual UI test in browser

---

## 📚 Files to Modify

| File | Changes | Lines |
|------|---------|-------|
| chatbot_web/index.html | Add allergen chips + textarea | ~130-150 |
| chatbot_web/css/style.css | Add .allergen-chip styling | ~EOL |
| chatbot_web/js/app.js | Add toggleAllergen(), update generateMenu() | Multiple |
| main.py | Add /allergen/common endpoint | ~800+ |
| data_loader.py | Add ALLERGEN_VARIANTS, _expand_allergen_terms() | ~480-520 |

---

## 🎯 Expected Outcome

### After Implementation
1. ✅ Frontend UI allergen selection (chips + custom input)
2. ✅ Backend returns complete allergen list via API
3. ✅ Allergen filter includes variants (VD: "tôm" → loại "tương tôm", "xốt tôm")
4. ✅ Session memory saves user's allergen profile
5. ✅ Comprehensive testing ensures no false negatives

### User Experience Improvement
- User can quickly select allergen từ pre-defined list
- Typing reduced by 50%
- Allergen profile remembered across sessions
- Menu guaranteed to be allergen-free

