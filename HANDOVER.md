# Yu-Gi-Oh! Card App — Handover Document

## Tổng quan

Flutter app hiển thị thông tin toàn bộ card game Yu-Gi-Oh! (~14,000+ cards), hỗ trợ Android, iOS và Web. Data được lấy từ [YGOPRODeck API](https://ygoprodeck.com/api-guide/) miễn phí.

---

## Cấu trúc dự án

```
yugioh-card-app/
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
    │   │   └── filter_state.dart    # FilterState, FilterStateNotifier, SortOption
    │   ├── providers/
    │   │   └── card_provider.dart   # cardDataProvider, filterStateProvider, filteredCardsProvider, filterIndexProvider
    │   ├── screens/
    │   │   ├── home_screen.dart     # Card grid, search bar, pagination, refresh button
    │   │   └── card_detail_screen.dart  # Chi tiết card: ảnh, stats, sets, prices
    │   ├── services/
    │   │   └── card_data_service.dart   # Load/cache/fetch logic
    │   ├── utils/
    │   │   └── card_colors.dart     # Màu theo frame type và attribute
    │   └── widgets/
    │       ├── card_item.dart       # Card thumbnail trong grid
    │       └── filter_panel.dart    # Bottom sheet filter với các dropdown
    ├── android/                     # Android platform files
    ├── ios/                         # iOS platform files
    ├── web/                         # Web platform files
    └── pubspec.yaml
```

---

## Tech Stack

| Thành phần | Package | Mục đích |
|---|---|---|
| State management | `flutter_riverpod 2.6.1` | Provider, StateNotifier |
| HTTP client | `dio 5.9.2` | Fetch từ YGOPRODeck API |
| Image cache | `cached_network_image 3.4.1` | Load ảnh card từ CDN |
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
   (~14,323 cards, ~3-5s)
    │
    ▼
4. Parse & normalize data
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

### Card Grid (Home Screen)
- Hiển thị card dạng grid responsive (2-6 cột tùy màn hình)
- **Pagination**: load 50 cards đầu, scroll xuống load thêm 50
- Hiển thị ảnh card từ CDN với shimmer placeholder
- Hiển thị ATK/DEF cho monster, badge type cho spell/trap
- Màu nền theo frame type (effect = cam, spell = xanh lá, trap = hồng, xyz = đen...)

### Search
- Tìm kiếm theo tên card hoặc card text (description)
- Real-time filter khi gõ

### Filter Panel (Bottom Sheet)
- Frame Type (effect, fusion, synchro, xyz, link, ritual, pendulum, spell, trap...)
- Attribute (DARK, LIGHT, FIRE, WATER, EARTH, WIND, DIVINE)
- Race / Monster Type (Dragon, Warrior, Spellcaster...)
- Level / Rank (1-12)
- Archetype (640+ archetypes)
- ATK Range (min/max)
- DEF Range (min/max)
- Sort by: Name, ATK, DEF, Level, Type (asc/desc)
- Badge indicator khi có filter đang active
- Nút Reset Filters

### Card Detail Screen
- Ảnh card full size
- Thông tin: Type, Attribute badge, Race, Level/Rank/Link
- ATK / DEF stats
- Archetype, Pendulum Scale, Link Markers
- Card text (description)
- Formats (TCG/OCG)
- Card Sets (tên set, mã set, rarity)
- Giá (TCGPlayer, Cardmarket, eBay, Amazon)

### Refresh Data
- Nút Refresh (🔄) trên AppBar
- Confirm dialog trước khi refresh
- Clear cache → re-fetch toàn bộ từ API

---

## Cách chạy

### Yêu cầu
- Flutter 3.41.5+ (stable)
- Dart 3.11.3+
- Android SDK 36+ (cho Android build)
- Python 3.x (chỉ cần nếu muốn bundle data)

### Chạy trên Web (Chrome)
```bash
cd yugioh-card-app/yugioh_card_app
flutter run -d chrome --web-port 8080
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

Flutter SDK đặt tại `D:\Download\flutter\bin\flutter.bat`.

Để dùng lệnh `flutter` trực tiếp, thêm vào PATH:
```
D:\Download\flutter\bin
```

Android Studio đặt tại `D:\soflware\Android\Android Studio`.
Config đã được set:
```bash
flutter config --android-studio-dir "D:\soflware\Android\Android Studio"
```

---

## Vấn đề đã biết

| Vấn đề | Nguyên nhân | Trạng thái |
|---|---|---|
| Cache fail trên Web | localStorage giới hạn ~5MB, data ~20MB | Non-fatal — app vẫn chạy, fetch lại mỗi lần mở |
| `compute()` không dùng trên Web | Web không hỗ trợ Dart isolates | Đã fix — parse trực tiếp trên web |
| Visual Studio warning | Thiếu C++ workload | Chỉ ảnh hưởng Windows desktop build, không ảnh hưởng Android/Web |

---

## Hướng phát triển tiếp theo

- [ ] **Favorites** — lưu card yêu thích vào local storage
- [ ] **Card Detail đầy đủ** — khi load từ cache thiếu desc, fetch lại detail từ API
- [ ] **Web cache** — dùng IndexedDB thay localStorage để cache data lớn trên web
- [ ] **Dark/Light theme toggle**
- [ ] **Deck Builder** — tạo và lưu deck
- [ ] **Random Card** — xem card ngẫu nhiên
- [ ] **Compare Cards** — so sánh 2 card
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

*Last updated: April 2026*
