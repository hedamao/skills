# Storyboard

**Format:** 1920x1080
**Audio:** TTS-ready narration text in `narration.txt`; preview currently focuses on visual promo timing.
**VO direction:** Calm, reassuring Chinese product spot, steady and clear.
**Style basis:** `DESIGN.md`, captured Ping An mobile insurance page.

## Asset Audit

| Asset | Type | Assign to Beat | Role |
| --- | --- | --- | --- |
| `capture/screenshots/viewport-000.png` | Mobile UI screenshot | 1, 2, 3, 4 | Main product surface |
| `capture/assets/hero-banner.jpg` | Hero banner | 1, 4 | Family protection visual |
| `capture/extracted/visible-text.txt` | Captured text | 2, 3, 4 | Real benefit and CTA copy |

## BEAT 1 — FAMILY PROTECTION (0.00-5.00s)

**VO cue:** 守护家人的医疗保障，不该复杂。
**Concept:** The spot opens in the same warm orange world as the product page. The family banner blooms behind a floating phone, making the insurance product feel protective, immediate, and mobile.
**Assets:** `hero-banner.jpg`, `viewport-000.png`.
**Transition:** Blur-through into beat 2.

## BEAT 2 — MOBILE ENROLLMENT (5.00-10.00s)

**VO cue:** 平安 e 生保百万医疗二零二五版，把核心保障放在手机里。
**Concept:** The phone becomes the stage. Selected plan tabs, disclosure sheet, and CTA details are echoed as clean floating UI cards around it.
**Assets:** `viewport-000.png`.
**Transition:** Whip-pan into the coverage numbers.

## BEAT 3 — COVERAGE PROOF (10.00-15.00s)

**VO cue:** 最高四百万年度赔付限额，一般医疗和特定疾病医疗各二百万。
**Concept:** The promo leaves the screenshot and turns the coverage numbers into hero objects. Big counters land with orange underline sweeps while smaller protection tiles orbit the phone.
**Assets:** `viewport-000.png`.
**Transition:** Upward velocity transition into family discount.

## BEAT 4 — CTA (15.00-20.00s)

**VO cue:** 多人投保还有家庭专属优惠，四人及以上最高百分之十五。阅读提示，确认信息，立即投保。
**Concept:** The final beat resolves from family discount proof to purchase confidence. Legal reading and confirmation appear as trust steps, ending on the bright `立即投保` action.
**Assets:** `hero-banner.jpg`, `viewport-000.png`.
**Transition:** Final orange CTA glow and fade.

## Production Architecture

```
videos/pingan-health-promo/
├── index.html
├── DESIGN.md
├── SCRIPT.md
├── STORYBOARD.md
├── narration.txt
├── transcript.json
└── capture/
    ├── screenshots/
    ├── assets/
    └── extracted/
```
