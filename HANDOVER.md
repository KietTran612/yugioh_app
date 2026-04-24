# Yu-Gi-Oh! Card App — Handover Document

## Tổng quan

Flutter app hiển thị thông tin toàn bộ card game Yu-Gi-Oh! (~14,000+ cards), hỗ trợ Android, iOS và Web. Data được lấy từ [YGOPRODeck API](https://ygoprodeck.com/api-guide/) miễn phí.

---

## Cấu trúc dự án

```
yugioh-card-app/
├── HANDOVER.md                      # Tài liệu này
├── run_web.bat                      # Script chạy app trên Chrome (double-click)
├── data-collector/                  # Python script thu thập data
│   ├── fetch_cards.py               # Fetch từ API, lưu ra cards.json
│   └── requirements.txt             # requests, tqdm
│
└── yugioh_card_app/                 # Flutter app
    ├── assets/
    │   └── data/
    │       ├── cards.json           # Placeholder (rỗng) — data fetch lúc runtime
    │       └── archetypes.json      # Placeholder
    ├── lib/
    │   ├── main.dart                # Entry point, MaterialApp + ProviderScope
    │   ├── models/
    │   │   ├── card_model.dart      # YugiohCard, CardImage, CardPrices, CardSet, CardMisc, FilterIndex
    │   │   └── filter_state.dart    # FilterState (multi-select), FilterStateNotifier, SortOption
    │   ├── providers/
    │   │   └── card_provider.dart   # cardDataProvider, filterStateProvider, filteredCardsProvider, filterIndexProvider
    │   ├── screens/
    │   │   ├── main_shell.dart      # Bottom navigation shell (5 tabs)
    │   │   ├── home_screen.dart     # Card grid, search bar, quick filter, pagination
    │   │   ├── card_detail_screen.dart  # Chi tiết card: ảnh, stats, sets, prices
    │   │   ├── sets_screen.dart     # Card Sets (placeholder)
    │   │   ├── collection_screen.dart   # My Collection (placeholder)
    │   │   ├── watchlist_screen.dart    # Watchlist (placeholder)
    │   │   └── more_screen.dart     # Settings, Refresh, About
    │   ├── services/
    │   │   └── card_data_service.dart   # Load/cache/fetch logic
    │   ├── utils/
    │   │   └── card_colors.dart     # Màu theo frame type và attribute
    │   └── widgets/
    │       ├── card_image.dart      # Cross-platform image widget (CORS-safe)
    │       ├── card_item.dart       # Card thumbnail trong grid (ảnh thuần)
    │       ├── filter_panel.dart    # Bottom sheet filter popup (multi-select)
    │       └── quick_filter_bar.dart # Inline expandable filter bar (multi-select, auto-collapse)
    ├── android/
    ├── ios/
    ├── web/
    └── pubspec.yaml
```

---

## Tech Stack

| Thành phần | Package | Mục đích |
|---|---|---|
| State management | `flutter_riverpod 2.6.1` | Provider, StateNotifier |
| HTTP client | `dio 5.9.2` | Fetch từ YGOPRODeck API |
| Image cache | `cached_network_image 3.4.1` | Load ảnh card từ CDN (mobile/desktop) |
| Local cache | `shared_preferences 2.5.5` | Cache JSON data |
| Navigation | `go_router 14.8.1` | (setup sẵn, chưa dùng) |
| Loading skeleton | `shimmer 3.0.0` | Placeholder khi load ảnh |

---

## Data Flow

```
App khởi động
    │
    ▼
1. Load assets/data/cards.json
   (placeholder rỗng → skip)
    │
    ▼
2. Load SharedPreferences cache
   (lần đầu chưa có → skip)
   (lần 2+ → load ngay, nhanh)
    │
    ▼
3. Fetch từ YGOPRODeck API
   GET https://db.ygoprodeck.com/api/v7/cardinfo.php?misc=yes
   (~14,000+ cards, ~3-5s)
    │
    ▼
4. Parse & normalize data (full data: desc, sets, prices, misc)
    │
    ▼
5. Lưu vào SharedPreferences cache
   (web: có thể fail do localStorage 5MB limit — non-fatal)
    │
    ▼
6. Hiển thị card grid
```

---

## Tính năng hiện tại

### Navigation (Bottom Bar)
- **Home** — card grid chính
- **Sets** — placeholder (coming soon)
- **Collection** — placeholder (coming soon)
- **Watchlist** — placeholder (coming soon)
- **More** — Refresh Data, About
- Dùng `IndexedStack` — giữ state từng tab khi switch

### Card Grid (Home Screen)
- Grid responsive (2-6 cột tùy màn hình)
- Card hiển thị ảnh thuần, không text bên dưới
- **Pagination**: load 50 cards đầu, scroll xuống load thêm 50
- Hiển thị số lượng card đang filter

### Search
- Tìm kiếm theo tên card hoặc card text
- Real-time filter khi gõ

### Quick Filter Bar (inline, dưới search)
- Đóng/mở bằng tap vào header bar
- **8 sections** đều có thể đóng/mở riêng: Type, Attribute, Race, Level/Rank, Archetype, ATK Range, DEF Range, Sort By
- **Auto-collapse**: khi mở section mới vượt quá available height của device → tự đóng section đầu tiên từ trên xuống
- Height threshold đo bằng `GlobalKey + RenderBox` — không hardcode
- Badge số trên mỗi section khi có filter active
- Summary bar hiển thị tất cả filter đang chọn

### Filter — Multi-select
- **Type, Attribute, Race, Level** → chọn nhiều giá trị (OR logic)
- **Archetype** → single-select
- Chip 2 hàng scroll ngang cho danh sách dài (Race 80+, Archetype 640+)
- Đồng bộ giữa Quick Filter Bar và Filter Panel popup

### Filter Panel (Bottom Sheet popup)
- Tương tự Quick Filter Bar nhưng dạng popup
- Mỗi filter là ConsumerWidget riêng — chỉ rebuild khi giá trị đó thay đổi

### Card Detail Screen
- Ảnh card — **tap để xem full screen** với pinch-to-zoom, Hero animation
- Frame type badge màu sắc theo loại card
- Attribute badge (DARK/LIGHT/FIRE...)
- ATK / DEF stats badge
- Race, Level/Rank/Link, Archetype, Pendulum Scale, Link Markers
- Card text — **có thể bôi đen và copy** (`SelectableText`)
- Formats (TCG/OCG/Master Duel)
- Card Sets (tên set, mã set, rarity)
- Giá (TCGPlayer, Cardmarket, eBay, Amazon)

### Refresh Data
- Nút Refresh (🔄) trên AppBar Home + tab More
- Confirm dialog → clear cache → re-fetch từ API

---

## Cách chạy

### Cách nhanh nhất — double-click `run_web.bat`
File `run_web.bat` ở root folder, tự động:
1. Chạy `flutter pub get`
2. Mở Chrome tại `http://localhost:8080` với `--disable-web-security` (bypass CORS cho ảnh)

### Chạy thủ công trên Web
```bash
cd yugioh-card-app/yugioh_card_app
flutter run -d chrome --web-port 8080 --web-browser-flag "--disable-web-security"
```

### Chạy trên Android
```bash
flutter run -d <device-id>
# Xem danh sách device: flutter devices
```

### Build APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Thu thập data thủ công (optional)
```bash
cd yugioh-card-app/data-collector
pip install -r requirements.txt
python fetch_cards.py
# Output: yugioh_card_app/assets/data/cards.json (~19MB)
```
> Nếu bundle `cards.json` vào app, app sẽ load từ assets thay vì fetch API.

---

## Flutter Path (Windows)

Flutter SDK: `D:\Download\flutter\bin\flutter.bat`

Thêm vào PATH để dùng lệnh `flutter` trực tiếp:
```
D:\Download\flutter\bin
```

Android Studio: `D:\soflware\Android\Android Studio`
```bash
flutter config --android-studio-dir "D:\soflware\Android\Android Studio"
```

---

## Vấn đề đã biết

| Vấn đề | Nguyên nhân | Trạng thái |
|---|---|---|
| Cache fail trên Web | localStorage giới hạn ~5MB, data ~20MB | Non-fatal — app vẫn chạy, fetch lại mỗi lần mở |
| `compute()` không dùng trên Web | Web không hỗ trợ Dart isolates | Đã fix — parse trực tiếp trên web |
| CORS block ảnh trên Web | Browser chặn cross-origin image request | Đã fix — `--disable-web-security` cho dev |
| Visual Studio warning | Thiếu C++ workload | Chỉ ảnh hưởng Windows desktop build |
| Quick Filter auto-collapse | Height estimate dựa trên giá trị xấp xỉ | Hoạt động tốt, có thể fine-tune `_sectionHeights` |

---

## Changelog

### v0.4 (April 2026)
- **Bottom Navigation Bar** — 5 tabs: Home, Sets, Collection, Watchlist, More
- **Multi-select filter** — Type, Attribute, Race, Level có thể chọn nhiều giá trị
- **Quick Filter Bar** — inline expandable filter dưới search box
  - 8 sections đóng/mở riêng
  - Auto-collapse khi vượt device height (đo bằng RenderBox, không hardcode)
  - Chip 2 hàng scroll ngang
- Card grid: bỏ tên và badge dưới ảnh, chỉ hiển thị ảnh thuần
- Filter panel popup đồng bộ multi-select

### v0.3 (April 2026)
- Fix CORS block ảnh trên web
- Tạo `CardNetworkImage` widget cross-platform
- Fix Card Detail Screen: bỏ tinted overlay, fix giá, tap ảnh full screen, SelectableText

### v0.2 (April 2026)
- Performance: pagination, filter ConsumerWidget riêng
- Fetch đầy đủ data, cache SharedPreferences
- Nút Refresh, `run_web.bat`

### v0.1 (April 2026)
- Initial Flutter project (Android + iOS + Web)
- Card grid, filter/search/sort, card detail
- Python data collector, auto-fetch từ API

---

## Hướng phát triển tiếp theo

- [ ] **Sets** — danh sách card sets, filter theo set
- [ ] **Collection** — quản lý bộ sưu tập cá nhân
- [ ] **Watchlist** — theo dõi giá card
- [ ] **Web cache** — dùng IndexedDB thay localStorage
- [ ] **Dark/Light theme toggle**
- [ ] **Deck Builder** — tạo và lưu deck
- [ ] **Multiple artworks** — swipe qua các artwork khác nhau
- [ ] **Offline mode** — bundle data vào app khi release

---

## API Reference

Base URL: `https://db.ygoprodeck.com/api/v7`

| Endpoint | Mô tả |
|---|---|
| `GET /cardinfo.php?misc=yes` | Toàn bộ card data |
| `GET /cardinfo.php?name=Dark+Magician` | Card theo tên |
| `GET /archetypes.php` | Danh sách archetypes |
| `GET /cardsets.php` | Danh sách card sets |

Image CDN:
- Full: `https://images.ygoprodeck.com/images/cards/{id}.jpg`
- Small: `https://images.ygoprodeck.com/images/cards_small/{id}.jpg`

---

*Last updated: April 2026 — v0.4*
