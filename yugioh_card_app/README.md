# Yu-Gi-Oh! Card App

Flutter app hiển thị thông tin ~14,000+ cards Yu-Gi-Oh!, hỗ trợ Android, iOS và Web.

## Yêu cầu

- Flutter SDK — [cài đặt](https://docs.flutter.dev/get-started/install)
- Chrome (để chạy Web)
- Android Studio hoặc thiết bị Android (để chạy Android)

**Windows paths (máy dev hiện tại):**
- Flutter SDK: `D:\Download\flutter\bin` — thêm vào PATH
- Android Studio: `D:\soflware\Android\Android Studio`

```bash
flutter config --android-studio-dir "D:\soflware\Android\Android Studio"
```

---

## Chạy app

### Web (nhanh nhất)

Double-click `run_web.bat` ở thư mục gốc, hoặc chạy thủ công:

```bash
flutter run -d chrome --web-port 8080 --web-browser-flag "--disable-web-security"
```

> `--disable-web-security` cần thiết để load ảnh card từ CDN (bypass CORS).

### Android

```bash
flutter devices          # xem danh sách thiết bị
flutter run -d <device-id>
```

### Build APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Lần đầu chạy

App sẽ tự fetch toàn bộ card data từ [YGOPRODeck API](https://ygoprodeck.com/api-guide/) (~3–5 giây). Từ lần sau load từ cache, gần như tức thì.

Nếu muốn bundle data sẵn vào app (offline):

```bash
cd ../data-collector
pip install -r requirements.txt
python fetch_cards.py
# Tạo ra assets/data/cards.json (~19MB)
```

---

## Tính năng chính

- **Card grid** — ~14,000 cards, search, filter đa dạng (Type, Attribute, Race, Level, Archetype, Banlist, Format...)
- **Card Detail** — stats, card text, dịch 11 ngôn ngữ, giá, card sets
- **Sets** — ~700+ card sets, search/sort, xem card trong từng set
- **Watchlist** — lưu card yêu thích local
- **Dark UI** — Duel Terminal theme

Xem chi tiết tại [`../HANDOVER.md`](../HANDOVER.md).
