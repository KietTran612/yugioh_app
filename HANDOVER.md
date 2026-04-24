# Yu-Gi-Oh! Card App — Handover Document

## Tổng quan

Flutter app hiển thị thông tin toàn bộ card game Yu-Gi-Oh! (~14,000+ cards), hỗ trợ Android, iOS và Web. Data lấy từ [YGOPRODeck API](https://ygoprodeck.com/api-guide/) miễn phí, cache local bằng SharedPreferences.

---

## Cấu trúc dự án

```
yugioh-card-app/
├── HANDOVER.md
├── run_web.bat                      # Double-click để chạy trên Chrome
├── data-collector/
│   ├── fetch_cards.py               # Fetch API → cards.json
│   └── requirements.txt
└── yugioh_card_app/
    ├── assets/data/
    │   └── cards.json               # Placeholder rỗng — data fetch lúc runtime
    ├── lib/
    │   ├── main.dart
    │   ├── models/
    │   │   ├── card_model.dart      # YugiohCard, CardSet, CardMisc, FilterIndex, BanlistInfo
    │   │   ├── filter_state.dart    # FilterState, FilterStateNotifier, SortOption
    │   │   └── deck_model.dart      # Deck, DeckFormat, DeckFormatConfig
    │   ├── providers/
    │   │   ├── card_provider.dart   # cardDataProvider, filterStateProvider, filteredCardsProvider
    │   │   ├── card_sets_provider.dart  # cardSetsProvider, setsFilterProvider, filteredSetsProvider
    │   │   ├── favorites_provider.dart  # favoritesProvider, favoriteCardsProvider
    │   │   ├── translation_provider.dart
    │   │   └── deck_provider.dart   # deckProvider, deckCardsProvider, masterDuelDecksProvider, duelLinksDecksProvider
    │   ├── screens/
    │   │   ├── main_shell.dart      # Shell: IndexedStack + nested Navigator per tab
    │   │   ├── home_screen.dart     # Card grid, search, quick filter, pagination
    │   │   ├── card_detail_screen.dart
    │   │   ├── sets_screen.dart
    │   │   ├── set_detail_screen.dart
    │   │   ├── collection_screen.dart   # Deck Builder — 2 sub-tab MD/DL
    │   │   ├── deck_detail_screen.dart  # Xem/edit deck, grid card theo zone
    │   │   ├── watchlist_screen.dart
    │   │   └── more_screen.dart
    │   ├── services/
    │   │   ├── card_data_service.dart   # Load/cache/fetch
    │   │   ├── translation_service.dart # Google Translate wrapper + cache
    │   │   └── deck_service.dart        # Persist/load decks via SharedPreferences
    │   └── widgets/
    │       ├── card_image.dart      # Cross-platform image (CORS-safe)
    │       ├── card_item.dart       # Card thumbnail
    │       ├── filter_panel.dart    # Bottom sheet filter
    │       └── quick_filter_bar.dart
    └── pubspec.yaml
```

---

## Tech Stack

| Package | Mục đích |
|---|---|
| `flutter_riverpod 2.6.1` | State management |
| `dio 5.9.2` | HTTP — fetch YGOPRODeck API |
| `translator 1.0.0` | Google Translate (unofficial) |
| `cached_network_image 3.4.1` | Cache ảnh card (mobile/desktop) |
| `shared_preferences 2.5.5` | Cache JSON data local |

---

## Data Flow

App khởi động → load SharedPreferences cache (nếu có) → fetch API nếu chưa có cache → parse → lưu cache → hiển thị.

- Lần đầu: fetch API ~3–5s (~14,000 cards)
- Lần sau: load cache ngay lập tức
- Web: cache có thể fail (localStorage ~5MB < data ~20MB) → non-fatal, fetch lại mỗi lần mở

---

## Tính năng hiện tại

### Navigation
- 5 tabs: **Home, Sets, Collection, Watchlist, More**
- `IndexedStack` — giữ state từng tab khi switch
- **Nested Navigator per tab** — bottom bar luôn hiển thị kể cả khi navigate sâu
- **Tab active state** — chỉ sáng khi ở root screen; dim khi đang ở màn hình con
- **Tap tab đang active** → về root tab ngay (`popUntil`)
- **`tabPush()`** — helper thay `Navigator.push`, dùng trong tất cả screens để shell track depth

### Home — Card Grid
- Grid responsive 2–6 cột
- Pagination 50 cards/lần, scroll để load thêm
- Search theo tên + card text (real-time)
- **Quick Filter Bar** — inline, 8 sections đóng/mở riêng: Type, Attribute, Race, Level, Archetype, ATK/DEF Range, Sort, Banlist, Format
  - Auto-collapse khi vượt device height
  - Badge số khi có filter active
- **Filter Panel** — bottom sheet popup, đồng bộ với Quick Filter Bar
- Filter multi-select: Type/Attribute/Race/Level (OR), Banlist (OR), Format (AND), Archetype (single)

### Card Detail
- Ảnh → tap full screen, pinch-to-zoom, Hero animation
- Badges: frame type, attribute, ATK/DEF, banlist status (đỏ/vàng/xanh)
- Card text — `SelectableText` (bôi đen copy được)
- **Dịch** — 11 ngôn ngữ qua Google Translate, cache local, lock chống dịch chồng
- Formats, Card Sets (tap → Set Detail), Prices

### Sets
- ~700+ sets, derive từ card data (không cần API riêng)
- Search + sort (Name A→Z/Z→A, Most/Fewest Cards)
- Tap set → Set Detail: grid card, filter type/rarity, search trong set

### Deck Builder (Collection tab)
- 2 sub-tab: **Master Duel** và **Duel Links**
- Format config:

| | Master Duel | Duel Links |
|---|---|---|
| Main Deck | 40–60 | 20–30 |
| Extra Deck | max 15 | max 9 |
| Side Deck | max 15 | ❌ |

- Tạo/đổi tên/xóa deck, lưu local (SharedPreferences)
- FAB "New Deck" tạo deck cho tab đang active
- **Card Detail → "Add to Deck"** — bottom sheet chọn deck, mỗi deck có stepper +/− hiển thị số copy hiện tại, nút Save luôn hiển thị (disable khi chưa thay đổi)
  - Chỉnh số lên/xuống → Save → tự tính diff để add thêm hoặc remove bớt
  - Sheet không tự đóng — user có thể update nhiều deck cùng lúc
  - Disable +/− khi đạt giới hạn (max 3 copies hoặc deck full)
- **Deck Detail Screen** — grid card theo zone (Main/Extra/Side), badge số lượng, long-press để xóa
- Validate: báo lỗi nếu main deck chưa đủ, vượt giới hạn, hoặc quá 3 copies/card

### Watchlist
- Favorites lưu local (SharedPreferences)
- Search + filter riêng (độc lập với Home)

### More
- Refresh Data (clear cache + re-fetch), About

---

## Cách chạy

```bash
# Web — double-click run_web.bat, hoặc:
flutter run -d chrome --web-port 8080 --web-browser-flag "--disable-web-security"

# Android
flutter run -d <device-id>

# Build APK
flutter build apk --release
```

**Flutter SDK**: `D:\Download\flutter\bin` (thêm vào PATH)

---

## Vấn đề đã biết

| Vấn đề | Trạng thái |
|---|---|
| Web cache fail (localStorage < data size) | Non-fatal — fetch lại mỗi lần mở |
| CORS block ảnh trên Web | Fix bằng `--disable-web-security` khi dev |
| Visual Studio C++ warning | Chỉ ảnh hưởng Windows desktop build, bỏ qua |

---

## Changelog

### v0.8 (April 2026)
- **Deck Builder** — tab Collection hoàn thiện
  - `deck_model.dart` — `Deck`, `DeckFormat`, `DeckFormatConfig` (MD/DL rules)
  - `deck_service.dart` — persist/load qua SharedPreferences (`decks_v1`)
  - `deck_provider.dart` — `DeckNotifier`, `deckCardsProvider`, format-filtered providers
  - `collection_screen.dart` — 2 sub-tab MD/DL, deck list, FAB "New Deck"
  - `deck_detail_screen.dart` — grid card theo zone, validate errors, rename, long-press xóa
  - **Add to Deck** — button trên Card Detail AppBar → bottom sheet với stepper +/− per deck
    - Stepper hiển thị số copy hiện tại, Save luôn visible (disable khi chưa dirty)
    - Tự tính diff → add thêm hoặc remove bớt, sheet không tự đóng

### v0.7 (April 2026)
- **Persistent bottom nav** — nested Navigator per tab, bottom bar không bị che
- **Tab active state** — 3 trạng thái: active / dim (đang sâu) / muted (tab khác)
- **Depth tracking** — `_DepthScope` (InheritedWidget) + `tabPush()` thay `Navigator.push`
  - Không dùng `NavigatorObserver` (gây assertion crash trên web)

### v0.6 (April 2026)
- **Sets tab** — hoàn thiện: `CardSetInfo`, `cardSetsProvider`, search/sort, Set Detail Screen
- **Translation** — `TranslationService`, cache + lock, 11 ngôn ngữ
- **Navigation** — tap set row trong Card Detail → Set Detail Screen

### v0.5 (April 2026)
- **Dark "Duel Terminal" UI** — `AppTheme` tập trung, navy/teal/gold palette
- **Favorites/Watchlist** — lưu local, search/filter riêng
- **Banlist** — parse + badge + filter (Forbidden/Limited/Semi-Limited)
- **Format filter** — TCG/OCG/Master Duel/GOAT

### v0.1–v0.4 (April 2026)
- Initial project, card grid, filter/search/sort, card detail, pagination, dark theme, bottom nav, multi-select filter, Quick Filter Bar

---

## Hướng phát triển tiếp theo

- [x] **Sets** — danh sách card sets ✅ v0.6
- [x] **Deck Builder** — Master Duel + Duel Links ✅ v0.8
- [ ] **Web cache** — IndexedDB thay localStorage
- [ ] **Multiple artworks** — swipe qua các artwork
- [ ] **Offline mode** — bundle data vào app
- [ ] **Deck export/import** — YDK format

---

## API

Base: `https://db.ygoprodeck.com/api/v7/cardinfo.php?misc=yes`
Images: `https://images.ygoprodeck.com/images/cards/{id}.jpg`

---

*Last updated: April 2026 — v0.8*
