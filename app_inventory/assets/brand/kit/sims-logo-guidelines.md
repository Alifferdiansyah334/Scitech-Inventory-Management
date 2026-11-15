# SIMS — Logo Guidelines (one page)

## 1. The logo
- **Idea**: Scitech's `>|` prompt face on a carry case: the robot that keeps the kit. It is an endorsed Scitech sub-brand. **Precision Case refinement (2026-11-14)**: low handle, 28-unit body corners, thick even walls, and a rectangular face window, so the mark reads as a briefcase rather than a padlock or camera. The case says what SIMS does: equipment goes out and comes back.
- **Versions**: horizontal lockup (primary) · stacked lockup · symbol · small-size symbol (no face). There is no separate wordmark-only file. The "SIMS" wordmark is Poppins ExtraBold outlined to paths.
- **Files** (`assets/brand/`):

| Use | File |
|---|---|
| Full colour on light surfaces | `sims-symbol.svg`, `sims-horizontal.svg`, `sims-stacked.svg` |
| On navy or dark surfaces (thinned 1/256 for irradiation) | `sims-symbol-white.svg`, `sims-horizontal-white.svg`, `sims-stacked-white.svg` |
| One-colour navy / black | `*-navy.svg`, `*-black.svg` |
| 24 px and below | `sims-symbol-small.svg`, `sims-symbol-small-white.svg` |
| Flutter (raster) | `sims-symbol.png` (1024 px wide), `sims-symbol-white.png`, `sims-symbol-small.png` (256 px) |

## 2. Clear space
Keep a clear zone of **1 × H** on all sides, where **H** is the height of the case handle (body top to handle top, about ¼ of the symbol width). In the lockups this clear space scales with the logo. Never use a fixed distance.

## 3. Minimum size
| Version | Screen | Print |
|---|---|---|
| Horizontal lockup | 96 px wide | 25 mm wide |
| Stacked lockup | 48 px wide | 15 mm wide |
| Symbol with face | 28 px (in-app brand bar) | 8 mm |
| Small-size symbol (no face) | 16–24 px (favicon, small iOS icons) | 5 mm |

## 4. Colour
| Name | HEX | RGB | CMYK* | Role |
|---|---|---|---|---|
| Navy Scitech | `#0F2C59` | 15 44 89 | 83 51 0 65 | case, wordmark, icon backgrounds |
| Kobalt | `#2E5BD0` | 46 91 208 | 78 56 0 18 | prompt face (accent) only |
| Sky container | `#D2E4FF` | 210 228 255 | 18 11 0 0 | light surface behind the full-colour logo |
| White | `#FFFFFF` | 255 255 255 | 0 0 0 0 | reversed logo |

\*CMYK values are straight conversions, not proofed. Match Pantone on a printed proof before any print run.

Contrast: navy on white 13.8:1 · Kobalt on white 5.96:1 · Kobalt vs navy 2.31:1 (the face separates from the case at 32 px) · navy on sky 10.7:1 · Kobalt on sky 4.62:1.

**Approved logo/background pairs**: full colour on white, `#F5F7FB` or sky `#D2E4FF` · white on navy · white on black · navy or black one-colour on white.
**Not approved**: the full-colour logo on navy (the case disappears; use the white version). On photos, use the white or navy version on a calm area, or put the symbol on a navy rounded tile.

## 5. Typography
- Wordmark: Poppins ExtraBold, outlined (supplied as artwork). App UI: Poppins (Regular/Medium/SemiBold/Bold).
- Licence: Poppins is SIL Open Font License 1.1 (`assets/fonts/Poppins-OFL.txt`), which allows logo use.

## 6. Platform icons (generated)
- Android: legacy `mipmap-*/ic_launcher.png` (navy rounded square, white mark). Adaptive `mipmap-anydpi-v26/ic_launcher.xml` uses `@color/ic_launcher_background` (navy), white `ic_launcher_foreground` (ink inside a 31 dp radius, within the 33 dp safe zone) and `ic_launcher_monochrome` for themed icons.
- Android 12+ splash: `drawable-*/splash_icon.png`, white mark inside the 160 dp inner circle.
- Web: `favicon.png` (small cut on a navy tile), `Icon-192/512` (navy rounded tile), `Icon-maskable-*` (full-bleed navy, mark inside the 80 % safe circle).
- iOS: `AppIcon.appiconset` uses navy full bleed with a white mark and no alpha. Icons 40 px and smaller use the small cut.

## 7. Don'ts
Don't stretch, squash or rotate the logo. Don't recolour outside the palette; the prompt stays Kobalt, not orange or any other accent. Don't add shadows, outlines, gradients or effects. Don't rearrange or resize the parts of a lockup, and don't separate the face from the case. Don't use the face version below 24 px. Don't place the logo on a busy background without a container. Don't recreate the wordmark by typing "SIMS" in a font.

## 8. Contact
Master files are in `assets/brand/` (SVG masters) and `assets/brand/kit/` (presentation, overview, test sheet). A trademark search has not been done; do one before external use.
