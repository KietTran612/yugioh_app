"""
Yu-Gi-Oh! Card Data Collector
Fetches all card data from YGOPRODeck API and saves to JSON.
Output: ../assets/data/cards.json (used by Flutter app)
"""

import requests
import json
import os
import time
from tqdm import tqdm

# ── Config ────────────────────────────────────────────────────────────────────
API_BASE = "https://db.ygoprodeck.com/api/v7"
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "yugioh_card_app", "assets", "data")
OUTPUT_FILE = os.path.join(OUTPUT_DIR, "cards.json")
OUTPUT_ARCHETYPES_FILE = os.path.join(OUTPUT_DIR, "archetypes.json")

# Card image base URL (used in Flutter app)
IMAGE_BASE_URL = "https://images.ygoprodeck.com/images/cards"
IMAGE_SMALL_BASE_URL = "https://images.ygoprodeck.com/images/cards_small"

# ── Helpers ───────────────────────────────────────────────────────────────────

def fetch_all_cards() -> list[dict]:
    """Fetch all cards from YGOPRODeck API."""
    print("📡 Fetching all cards from YGOPRODeck API...")
    url = f"{API_BASE}/cardinfo.php"
    params = {
        "misc": "yes",       # include misc info (formats, tcg_date, etc.)
    }

    resp = requests.get(url, params=params, timeout=60)
    resp.raise_for_status()
    data = resp.json()
    cards = data.get("data", [])
    print(f"✅ Fetched {len(cards)} cards.")
    return cards


def fetch_archetypes() -> list[str]:
    """Fetch all archetypes."""
    print("📡 Fetching archetypes...")
    url = f"{API_BASE}/archetypes.php"
    resp = requests.get(url, timeout=30)
    resp.raise_for_status()
    archetypes = [a["archetype_name"] for a in resp.json()]
    print(f"✅ Fetched {len(archetypes)} archetypes.")
    return archetypes


def normalize_card(card: dict) -> dict:
    """
    Normalize raw API card data into a clean structure for the Flutter app.
    Keeps only fields we actually use.
    """
    # Get first card image (some cards have multiple artworks)
    images = card.get("card_images", [])
    card_id = images[0]["id"] if images else card.get("id", 0)

    # Card prices (take the first set)
    prices = {}
    card_prices = card.get("card_prices", [])
    if card_prices:
        p = card_prices[0]
        prices = {
            "tcgplayer": p.get("tcgplayer_price", "0.00"),
            "cardmarket": p.get("cardmarket_price", "0.00"),
            "ebay": p.get("ebay_price", "0.00"),
            "amazon": p.get("amazon_price", "0.00"),
        }

    # Card sets
    sets = []
    for s in card.get("card_sets", []):
        sets.append({
            "set_name": s.get("set_name", ""),
            "set_code": s.get("set_code", ""),
            "set_rarity": s.get("set_rarity", ""),
            "set_rarity_code": s.get("set_rarity_code", ""),
        })

    # Misc info
    misc = {}
    misc_list = card.get("misc_info", [])
    if misc_list:
        m = misc_list[0]
        misc = {
            "formats": m.get("formats", []),
            "tcg_date": m.get("tcg_date", ""),
            "ocg_date": m.get("ocg_date", ""),
            "views": m.get("views", 0),
        }

    normalized = {
        "id": card.get("id"),
        "name": card.get("name", ""),
        "type": card.get("type", ""),           # e.g. "Effect Monster", "Spell Card"
        "frame_type": card.get("frameType", ""), # e.g. "effect", "spell", "trap"
        "desc": card.get("desc", ""),
        "race": card.get("race", ""),            # monster type OR spell/trap type
        "archetype": card.get("archetype", ""),
        "image_url": f"{IMAGE_BASE_URL}/{card_id}.jpg",
        "image_url_small": f"{IMAGE_SMALL_BASE_URL}/{card_id}.jpg",
        "card_images": [
            {
                "id": img["id"],
                "image_url": f"{IMAGE_BASE_URL}/{img['id']}.jpg",
                "image_url_small": f"{IMAGE_SMALL_BASE_URL}/{img['id']}.jpg",
            }
            for img in images
        ],
        "prices": prices,
        "sets": sets,
        "misc": misc,
    }

    # Monster-specific fields
    if "Monster" in card.get("type", "") or card.get("frameType", "") not in ("spell", "trap"):
        normalized["atk"] = card.get("atk")          # can be None (? ATK)
        normalized["def"] = card.get("def")           # can be None
        normalized["level"] = card.get("level")       # Level / Rank
        normalized["attribute"] = card.get("attribute", "")  # DARK, LIGHT, etc.
        normalized["scale"] = card.get("scale")       # Pendulum scale
        normalized["link_val"] = card.get("linkval")  # Link rating
        normalized["link_markers"] = card.get("linkmarkers", [])

    return normalized


def build_filter_index(cards: list[dict]) -> dict:
    """
    Build a filter index with all unique values for each filterable field.
    Used by the Flutter app to populate filter dropdowns.
    """
    types = set()
    frame_types = set()
    races = set()
    attributes = set()
    archetypes = set()
    levels = set()

    for c in cards:
        if c.get("type"): types.add(c["type"])
        if c.get("frame_type"): frame_types.add(c["frame_type"])
        if c.get("race"): races.add(c["race"])
        if c.get("attribute"): attributes.add(c["attribute"])
        if c.get("archetype"): archetypes.add(c["archetype"])
        if c.get("level") is not None: levels.add(c["level"])

    return {
        "types": sorted(types),
        "frame_types": sorted(frame_types),
        "races": sorted(races),
        "attributes": sorted(attributes),
        "archetypes": sorted(archetypes),
        "levels": sorted(levels),
    }


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # 1. Fetch cards
    raw_cards = fetch_all_cards()

    # 2. Normalize
    print("🔄 Normalizing card data...")
    normalized = []
    for card in tqdm(raw_cards, desc="Processing"):
        normalized.append(normalize_card(card))

    # 3. Build filter index
    print("🗂️  Building filter index...")
    filter_index = build_filter_index(normalized)

    # 4. Save cards.json
    output = {
        "version": "1.0.0",
        "fetched_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "total": len(normalized),
        "filter_index": filter_index,
        "cards": normalized,
    }

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(output, f, ensure_ascii=False, separators=(",", ":"))

    size_mb = os.path.getsize(OUTPUT_FILE) / (1024 * 1024)
    print(f"\n✅ Saved {len(normalized)} cards → {OUTPUT_FILE} ({size_mb:.1f} MB)")

    # 5. Save archetypes.json
    archetypes = fetch_archetypes()
    with open(OUTPUT_ARCHETYPES_FILE, "w", encoding="utf-8") as f:
        json.dump(archetypes, f, ensure_ascii=False, separators=(",", ":"))
    print(f"✅ Saved {len(archetypes)} archetypes → {OUTPUT_ARCHETYPES_FILE}")

    # 6. Print summary
    print("\n📊 Summary:")
    print(f"   Total cards     : {len(normalized)}")
    print(f"   Types           : {len(filter_index['types'])}")
    print(f"   Frame types     : {len(filter_index['frame_types'])}")
    print(f"   Races           : {len(filter_index['races'])}")
    print(f"   Attributes      : {len(filter_index['attributes'])}")
    print(f"   Archetypes      : {len(filter_index['archetypes'])}")
    print(f"   Levels/Ranks    : {len(filter_index['levels'])}")


if __name__ == "__main__":
    main()
