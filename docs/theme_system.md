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

| Token | Value |
|-------|-------|
| `success` / `successSubtle` | `#4CAF50` / `#E8F5E9` |
| `warning` / `warningSubtle` | `#FF9800` / `#FFF3E0` |
| `error` / `errorSubtle` | `#EF233C` / `#FCE4EC` |
| `info` / `infoSubtle` | `#2196F3` / `#E3F2FD` |

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
- `AppTheme.dark` — full `ThemeData` for dark mode
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

// ❌ Raw hex in widget files
color: Color(0xffF5F5F5)
color: Color(0xff8C8C8C)
```

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

```dart
MaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  themeMode: ref.watch(themeModeProvider),
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

1. Use `Theme.of(context).colorScheme.*` for all color decisions
2. Use `CrucueTokens.brandPrimary` for brand accents
3. Use `CrucueTokens.success/warning/error/info` for semantic feedback
4. Do not add new `Color(0xff...)` literals — map to existing tokens or add a named token in `CrucueTokens`
5. Test in both light and dark mode before merging
