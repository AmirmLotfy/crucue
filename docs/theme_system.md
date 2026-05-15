# Theme System

## Principles

Crucue's visual design reflects its product values: calm, premium, trustworthy, and human.

- **Orange-first identity.** The brand primary `#FF4F00` is the singular visual anchor. It appears on actions, active states, and key UI accents. It is never swapped, softened, or replaced.
- **Semantic tokens.** All UI code uses named tokens, never raw hex values. This makes theme changes, dark mode, and consistency enforceable.
- **True dark mode.** Both light and dark themes are first-class. Dark mode does not invert — it uses a purpose-designed dark surface palette.
- **Quiet backgrounds.** Backgrounds are near-white in light mode, near-black in dark. The orange speaks clearly against both.

---

## Token system (`CrucueTokens`)

Defined in `lib/core/theme.dart`. All tokens are `static const`.

### Brand

| Token | Value | Use |
|-------|-------|-----|
| `brandPrimary` | `#FF4F00` | Filled buttons, active tabs, key icons |
| `brandPrimaryLight` | `#FF6A2A` | Hover / pressed state |
| `brandPrimaryDark` | `#CC3F00` | Darker variant |
| `brandPrimarySubtle` | `#FFF0E6` | Light-mode background tint (onboarding, etc.) |

### Surfaces — light

| Token | Value |
|-------|-------|
| `surfaceLight` | `#FFFFFF` |
| `surfaceAltLight` | `#FAFAFA` |
| `backgroundLight` | `#F5F5F5` |
| `inputSurfaceLight` | `#FAFAFA` |

### Surfaces — dark

| Token | Value |
|-------|-------|
| `backgroundDark` | `#121212` |
| `surfaceDark` | `#1E1E1E` |
| `surfaceAltDark` | `#242424` |
| `inputSurfaceDark` | `#2A2A2A` |

### Text

| Token | Light | Dark |
|-------|-------|------|
| `textPrimaryLight/Dark` | `#191919` | `#E8E8E8` |
| `textSecondaryLight/Dark` | `#8C8C8C` | `#9CA3AF` |
| `textMutedLight/Dark` | `#AAAAAA` | `#666666` |

### Borders

| Token | Light | Dark |
|-------|-------|------|
| `borderLight/Dark` | `#EEEEEE` | `#333333` |
| `borderStrongLight/Dark` | `#D1D5DB` | `#555555` |

### Semantic

| Token | Value | Notes |
|-------|-------|--------|
| `success` / `successSubtle` | `#4CAF50` / `#E8F5E9` | Accent colors are shared; **pastel fills** for UI also exist as dark variants on [`CrucueDecorColors`](lib/core/theme.dart). |
| `warning` / `warningSubtle` | `#FF9800` / `#FFF3E0` | Use `context.decor.warningSubtle` in widgets, not `CrucueTokens.warningSubtle`. |
| `error` / `errorSubtle` | `#EF233C` / `#FCE4EC` | Same — `context.decor.errorSubtle`. |
| `info` / `infoSubtle` | `#2196F3` / `#E3F2FD` | Same — `context.decor.infoSubtle`. |

### Plan card tints (light definitions)

| Token | Value | Widget usage |
|-------|-------|----------------|
| `planWhatHappening` … `planReflect` | pastels | **Do not** reference these in feature/view code for backgrounds. Use `context.decor.planWhatHappening` (etc.) so dark mode gets the matching dark tint. |

### Persona swatches

Each of 9 persona types has a card background color:

| Persona | Token | Color |
|---------|-------|-------|
| child | `personaChild` | `#A6B2EE` |
| teenager | `personaTeenager` | `#FFC2B8` |
| baby | `personaBaby` | `#FBB0FF` |
| parent | `personaParent` | `#7FD2F2` |
| partner | `personaPartner` | `#F3AEAF` |
| sibling | `personaSibling` | `#BADED8` |
| friend | `personaFriend` | `#FEDEA5` |
| pet | `personaPet` | `#C2D6FE` |
| myself | `personaMyself` | `#D4F5C0` |

---

## AppTheme class

`AppTheme` in `lib/core/theme.dart` provides:

- `AppTheme.light` — full `ThemeData` for light mode
- `AppTheme.dark` — full `ThemeData` for dark mode (includes `ThemeExtension<CrucueDecorColors>`)
- `AppTheme.primary` — brand color alias (`CrucueTokens.brandPrimary`)
- `AppTheme.radius` / `AppTheme.radiusLarge` — shared border radii
- `AppTheme.fontFamily` — `'Roboto'`
- `AppTheme.fontFamily2` — `'Montserrat'` (headings)

### Light-only aliases (for backward compatibility)

`AppTheme` also exposes these light-only static constants:
```dart
static const surface = CrucueTokens.surfaceLight;
static const background = CrucueTokens.backgroundLight;
static const textPrimary = CrucueTokens.textPrimaryLight;
// etc.
```

**These should not be used in new widget code.** They exist only as references in `AppTheme` itself. Widget code must use `Theme.of(context).*` for dark-mode-aware access.

---

## Using tokens in widgets

### Correct (theme-aware)

```dart
// Surfaces and backgrounds
color: Theme.of(context).colorScheme.surface
color: Theme.of(context).scaffoldBackgroundColor

// Text colors
color: Theme.of(context).colorScheme.onSurface
color: Theme.of(context).hintColor

// Borders
color: Theme.of(context).dividerColor

// Brand primary (mode-agnostic — always orange)
color: AppTheme.primary
color: CrucueTokens.brandPrimary

// Semantic (mode-agnostic — static colors)
color: CrucueTokens.success
color: CrucueTokens.warning
```

### Incorrect (breaks dark mode)

```dart
// ❌ Light-only statics in widget build methods
color: AppTheme.surface
color: AppTheme.background
color: AppTheme.textPrimary
color: CrucueTokens.textMutedLight
color: CrucueTokens.planWhatToDo
color: CrucueTokens.warningSubtle

// ❌ Raw hex in widget files
color: Color(0xffF5F5F5)
color: Color(0xff8C8C8C)
```

### `Colors.white` / `Colors.black`

Use **`Theme.of(context).colorScheme.onPrimary`** for icons and labels on **primary** (`AppTheme.primary` / `colorScheme.primary`) fills. Reserve `Colors.white` for **theme definitions** inside `lib/core/theme.dart` only (e.g. `onPrimary: Colors.white`). Message snackbars that sit on saturated semantic greens/blues may keep white body text for contrast.

---

## `CrucueDecorColors` (`ThemeExtension`)

Registered on both `AppTheme.light` and `AppTheme.dark` in `lib/core/theme.dart`. Holds **mode-specific** fills:

- Plan section backgrounds (`planWhatHappening`, `planWhatToDo`, …)
- Semantic subtle banners (`successSubtle`, `warningSubtle`, …)
- `quoteInset` — inset surface on tinted cards (e.g. quoted plan text)

Access from widgets:

```dart
final d = context.decor;
color: d.planReflect
color: d.warningSubtle
```

---

## Audit script

Run from repo root:

```bash
./tool/audit_theme.sh
```

This greps `lib/` (excluding `lib/core/theme.dart`) for disallowed `CrucueTokens` light-only and pastel-surface patterns. Add `./tool/audit_theme.sh` to CI if desired.

---

## Dark mode infrastructure

### Provider

```dart
// lib/app/providers.dart
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(...)
```

### Persistence

Theme preference is stored in `SharedPreferences` via `CacheHelper.saveThemeMode()`.

### App wiring (`lib/main.dart`)

`MaterialApp.router` sets `theme`, `darkTheme`, and `themeMode`, and uses a `builder` that wraps the navigator in `AnnotatedRegion<SystemUiOverlayStyle>` so Android status / navigation bar icons track brightness.

```dart
MaterialApp.router(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  themeMode: ref.watch(themeModeProvider),
  builder: (context, child) {
    final overlay = Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light.copyWith(...)
        : SystemUiOverlayStyle.dark.copyWith(...);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: child ?? const SizedBox.shrink(),
    );
  },
)
```

### User control

Settings page → Appearance section → System / Light / Dark selector (`_ThemeSelector` widget).

---

## BuildContext extension

`lib/core/theme.dart` provides a `BuildContext` extension for ergonomic access:

```dart
extension AppColors on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get surface => Theme.of(this).colorScheme.surface;
  Color get onSurface => Theme.of(this).colorScheme.onSurface;
  Color get primaryColor => Theme.of(this).colorScheme.primary;

  /// Plan tints, semantic subtles, quote inset — see CrucueDecorColors.
  CrucueDecorColors get decor =>
      Theme.of(this).extension<CrucueDecorColors>() ?? CrucueDecorColors.light;
}
```

---

## Typography

| Family | Weight | Use |
|--------|--------|-----|
| Roboto (default) | 400, 500, 600 | Body, labels, inputs |
| Montserrat | 700, 800 | Headlines, profile names, card titles |

---

## Adding new UI

When adding new screens or components:

1. Use `Theme.of(context).colorScheme.*` for standard surfaces and typography roles
2. Use **`context.decor`** for plan cards, warning/success subtle banners, and similar tinted surfaces
3. Use `CrucueTokens.brandPrimary` (or `AppTheme.primary`) for brand accents
4. Use `CrucueTokens.success/warning/error/info` for **semantic accents** (icons, borders), not for large pastel fills (use `context.decor` subtles)
5. Do not add new `Color(0xff...)` literals — map to existing tokens, `ColorScheme`, or extend `CrucueDecorColors`
6. Run `./tool/audit_theme.sh` and test light + dark (and system) before merging
