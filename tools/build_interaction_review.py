# -*- coding: utf-8 -*-
"""Build the review from actual, isolated runtime captures."""
from pathlib import Path
import json

root = Path(__file__).resolve().parents[1]
page = root / 'docs/art-review.html'
archive = root / 'docs/art-review-v41.html'
if not archive.exists():
    archive.write_text(page.read_text())
cards = [
    ('water-contact', 'הנהר המקורי חזר; חיבור העמודים עדיין לבדיקה'),
    ('checkpoint-arrival', 'תגובת הגעה לצ׳קפוינט, ללא טקסט צף'),
    ('cache-and-crate', 'אוצר פתוח עם תוכן, בנפרד מקופסת המדרגה'),
    ('picnic-arrival', 'Moss ונקודת הפיקניק בתוך המשחק'),
    ('finish-practice', 'יעד נראה לעין בסוף האימון'),
    ('roots', 'מיקום עצים וקליטת השורשים בקרקע'),
    ('crank-ready', 'הדגשה סביב הגלגל הפעיל בלבד'),
    ('crank-used', 'אחרי בניית הגשר, ללא הדגשה מתמשכת'),
    ('placement-portrait', 'בחירת מקום לקופסה בתצוגה לאורך'),
    ('placed-portrait', 'אותו מקום לאחר אישור'),
    ('picnic-complete', 'סיום משימה עם התגמולים שנשמרו'),
    ('results-portrait', 'מסך הסיום בתצוגה לאורך'),
    ('water-portrait', 'הגשר בתצוגה לאורך'),
    ('checkpoint', 'דגל שכבר ביקרנו בו אינו מהבהב ברציפות'),
]
gallery = ''
for name, caption in cards:
    assert (root / 'docs/screenshots' / f'readability-{name}.png').exists()
    css = ' class="portrait"' if 'portrait' in name else ''
    gallery += f'<figure><img{css} loading="lazy" src="screenshots/readability-{name}.png?v=287-foam" alt="{caption}"><figcaption>{caption}</figcaption></figure>'
video = '<figure><video controls muted loop playsinline style="width:100%" poster="screenshots/water-foam-desktop.png"><source src="screenshots/water-foam-motion.mp4" type="video/mp4"></video><figcaption>קצף מים בתנועה סביב שלושת העמודים · צילום משחק בקצב סימולציה קבוע</figcaption></figure>'
page.write_text('''<!doctype html><html lang="he" dir="rtl"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>PETOPIA · אינטראקציות וסיום משימה</title><style>body{margin:0;background:#fcf8ed;color:#20372e;font:17px/1.6 system-ui}main{max-width:1300px;margin:auto;padding:24px}header{background:#193c33;color:#fff4d7;padding:24px}h1{margin:0}a{color:#21765c}header a{color:#fff4d7}img{display:block;width:100%;background:#d7e6dd}figure{margin:0}figcaption{font-size:14px;color:#586e61}.grid{display:grid;grid-template-columns:1fr 1fr;gap:22px;margin:24px 0}.notice{background:#fff0cb;padding:16px;border-inline-start:5px solid #bd8833}.portrait{max-height:700px;object-fit:contain}@media(max-width:800px){.grid{grid-template-columns:1fr}}</style><header><h1>PETOPIA · אינטראקציות וסיום משימה</h1><a href="progress.html">התקדמות הפרויקט</a></header><main><p class="notice">מועמדת לבדיקה מתוך המשחק, ללא אישור אמנות סופי. הנהר הכחול השטוח נדחה והוחזר הנהר המקורי עם הסלעים והמפל. חיבורי המים, הדמות החדשה ועיצוב הממשק עדיין פתוחים לבדיקה. 287 בדיקות תפקודיות אינן אישור חזותי.</p><p>לשחק לבד: סגרו חלון משחק ישן באופן רגיל ופתחו את PETOPIA בשולחן העבודה. Adventures מוביל למשימות; River art test הוא אימון ללא פרסים. קופסאות: Bag → Place a crate, בוחרים מקום בנגיעה או בעכבר ומאשרים. Find / Q חושף אוצר; Use / E פותח אותו. החזרת סל הפיקניק ל־Moss מסיימת את הסיפור ומציגה תגמולים שנשמרו בפועל.</p><div class="grid">''' + video + gallery + '''</div><p>צילומים מתוך המשחק עם פרופיל בדיקה נפרד. הדוגמה של 60 מטבעות כוללת 50 על המשימה, אפס איסופים ו־10 על אוצר ראשון. במשחק מוצגים הנתונים בפועל. אין שינוי לקושי של שלב הלימוד ואין טענה לבדיקת טלפון ממשי.</p><p>התפריט הראשי ונכסי הממשק הסופיים לפי V04–V09 עדיין בתוכנית. מסך הסיום הנוכחי מחובר לסיפור ולשמירה.</p><p><a href="verification.json">אימות ומגבלות</a> · <a href="design-amendments.md">החלטות</a> · <a href="resident-production.json">דמות חדשה, מקור ופרומפט</a> · <a href="tooling-evaluation.md">בדיקת הכלים מהפוסט</a> · <a href="art-review-v41.html">תיעוד קודם</a></p></main></html>''')
for name in ['progress', 'verification', 'asset-register', 'resident-production', 'river-water-study-prompt']:
    json.loads((root / 'docs' / f'{name}.json').read_text())
assert 'water-study.png' not in (root / 'scripts/art/meadow_crossing_kit.gd').read_text()
print('14 captures, 5 JSON documents valid; rejected water absent from renderer.')
