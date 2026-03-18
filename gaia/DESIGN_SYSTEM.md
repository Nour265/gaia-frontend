# GAIA Flutter Design System Reference

This file is a scanned reference of the current Flutter UI implementation in `gaia/`.
Use this as the source of truth when adding new pages or UI components.

Last scanned: 2026-03-18

## 1) Theme and Colors

### Theme setup
- App entry uses `MaterialApp(theme: app_theme.lightThemeData, routes: Routes.map)`.
- Main theme source: `lib/app/theme.dart`.
- Active theme mode: light only.
- Dark theme: not defined.

```dart
ThemeData lightThemeData = themeData(_lightColorScheme, _lightFocusColor);
```

### Color system
Defined in `lib/values/colors.dart` as `AppColors`.

#### Brand `MaterialColor`s
- `AppColors.purple` base `#8C30F5`
  - `100: #F1E4FF`
  - `800: #D6B1FF`
- `AppColors.turquoise` base `#2EC5CE`
  - `100: #D5FAFC`
  - `800: #75E3EA`
- `AppColors.orange` base `#FE9A22`
  - `100: #FFE3C1`
  - `800: #FFC278`
- `AppColors.pink` base `#F22BB2`
  - `100: #FFB1E6`
  - `800: #FF72D2`

#### Gray text palette (`MaterialColor`)
- Base `#18191F`
- `900: #18191F`
- `800: #474A57`
- `700: #969BAB`
- `300: #D9DBE1`
- `200: #EEEFF4`
- `100: #F4F5F7`

#### Neutrals
- `AppColors.white = #FFFFFF`
- `AppColors.black = #0B0D17`

#### Accent colors
- `AppColors.pastelGreen = #C1E5C0`
- `AppColors.pastelBlue = #C0DAE5`
- `AppColors.peach = #F39F9F`
- `AppColors.lightPeach = #FDD9D9`
- `AppColors.cottonCandy = #FFC3D8`
- `AppColors.cyan = #A0DCFF`

### Light `ColorScheme`
From `lib/app/theme.dart`:
- `primary: AppColors.purple`
- `primaryContainer: AppColors.purple.shade800`
- `secondary: AppColors.turquoise`
- `secondaryContainer: AppColors.turquoise.shade800`
- `surface: AppColors.white`
- `onSurface: AppColors.gray`
- `onSecondary: AppColors.white`
- `brightness: Brightness.light`

## 2) Typography

### Font family
- Global typography uses `GoogleFonts.inter(...)`.
- No custom font families in `pubspec.yaml`.

### Named `TextTheme` styles (`lib/app/theme.dart`)
- `displayLarge`: 72, w900, gray
- `displayMedium`: 48, w900, gray
- `displaySmall`: 40, w900, gray
- `headlineMedium`: 28, w900, gray
- `headlineSmall`: 24, w600, gray
- `titleLarge`: 20, w500, gray
- `titleMedium`: 18, w700, gray
- `titleSmall`: 18, w500, gray
- `bodyLarge`: 16, w400, gray
- `bodyMedium`: 14, w400, gray

### Additional named text styles
- `lead1`: 18, w400, gray
- `lead2`: 14, w500, gray
- `largeLabel`: 20, w600, black
- `mediumLabel`: 14, w600, gray
- `smallLabel`: 12, w600, gray

### Text usage pattern
- Most widgets use `final textTheme = Theme.of(context).textTheme;`.
- Component-specific style variations use `.copyWith(...)`.

## 3) Spacing and Layout

### Spacing tokens (`lib/values/spacing.dart`)
- `AppSpacing.xs = 4`
- `AppSpacing.sm = 8`
- `AppSpacing.md = 16`
- `AppSpacing.lg = 24`
- `AppSpacing.xl = 32`
- `AppSpacing.xxl = 48`

### Radius tokens (`lib/values/radius.dart`)
- `AppRadius.sm = 6`
- `AppRadius.md = 12`
- `AppRadius.lg = 16`
- `AppRadius.xl = 24`

### Repeated raw spacing patterns
- Header height: `72.0`
- Common card/form paddings: `16`, `20`, `24`, `32`
- Common control heights: `44`, `46`, `52`
- Common content width container: `size.width * 0.7`

### Responsive patterns
- Width checks:
  - `size.width > 800` for web/tablet split (admin pages)
  - `constraints.maxWidth >= 1000` wide layout split (results page)
  - `size.width < 900` alternate content widths (blog)
- Pattern:
  - `ConstrainedBox(maxWidth: ...)` for auth/profile forms
  - `Wrap` for adaptive card rows
  - `SingleChildScrollView` around most long pages

## 4) Reusable Component Patterns (`lib/widgets`)

### `NavBar`
- Constructor: `const NavBar({Key? key, this.showLogin = false})`
- Purpose: Top navigation shell with logo, menu items, and optional auth/admin actions.
- Usage:
```dart
const NavBar(showLogin: true)
```

### `ImageLinks`
- Constructor: `const ImageLinks({Key? key})`
- Purpose: Right-side auth section, driven by `AuthSession.userNotifier`.
- Behavior:
  - Logged out: Login/Sign Up
  - Logged in user: Profile/Logout
  - Admin: Dashboard/Doctors/Profile/Logout

### `Logo`
- Constructor: `const Logo({Key? key})`
- Purpose: Brand mark (`ImagePath.logo`) + "GAIA" text.

### `NavItem`
- Constructor:
```dart
const NavItem({
  Key? key,
  required this.label,
  required this.style,
  this.onTap,
  this.trailing,
})
```
- Purpose: Hoverable top-nav text item with animated underline and optional trailing icon.

### `Heros`
- Constructor: `const Heros({Key? key})`
- Purpose: Landing hero with background image, primary headline, CTA button, and desktop mockup image.

### `Features` and `FeatureItem`
- `Features`: section wrapper for feature cards.
- `FeatureItem` constructor:
```dart
const FeatureItem({
  Key? key,
  required this.icon,
  required this.title,
  required this.description,
  this.width,
  this.height,
})
```
- Purpose: Reusable icon + title + description card.

### `Testimonials` and `Testimony`
- `Testimonials`: section wrapper with quote background style.
- `Testimony` constructor:
```dart
const Testimony({
  Key? key,
  required this.icon,
  required this.message,
  required this.steptitle,
  this.width,
  this.height,
})
```

### `Stats` and `StatsSegment`
- `Stats`: KPIs block (headline + metric pairs).
- `StatsSegment` constructor:
```dart
const StatsSegment({
  Key? key,
  required this.icon,
  required this.title,
  required this.subtitle,
})
```

### `Cta`
- Constructor: `const Cta({Key? key})`
- Purpose: Primary conversion section with short text and "Start Symptom Check" button.

### `Footer`
- Constructor: `const Footer({Key? key})`
- Purpose: Global footer with gradient background, navigation links, support/legal columns, and disclaimer.

### Composition example (from landing page)
```dart
Column(
  children: [
    const Heros(),
    const Features(),
    const Testimonials(),
    const Stats(),
    const Cta(),
    const Footer(),
  ],
)
```

## 5) Page/Screen Structure

### Folder structure
- `lib/screens/landing`
- `lib/screens/about`
- `lib/screens/blog`
- `lib/screens/wizard`
- `lib/screens/results`
- `lib/screens/auth`
- `lib/screens/profile`
- `lib/screens/admin`

### Common scaffold patterns
- Marketing pages (`landing`, `about`, `blog`):
  - `Scaffold` + custom `PreferredSize` app bar container + centered `NavBar`
  - `SingleChildScrollView` body
  - `Footer` at bottom
- Auth/profile/admin pages:
  - `Scaffold` with direct `AppBar` or centered form cards
  - Form-based `TextFormField` + validators
  - Loading and error states via local state flags
- Wizard/results:
  - Stateful flow with constructor data passing to next page
  - Results uses async API fetch + `FutureBuilder`

### Data flow in pages
- Route map pages are mostly no-arg constructors.
- Data passed by constructor for results:
```dart
ResultsPage(
  age: age,
  gender: gender,
  symptoms: _selectedSymptoms.toList(),
)
```
- Auth/session state consumed via `AuthSession` static state and `userNotifier`.

## 6) Navigation

### Routing approach
- Uses built-in Flutter named routes (`MaterialApp.routes`) and `Navigator`.
- Central route constants and map in `lib/app/routes.dart`.

### Route constants
- `/` (`Routes.landing`)
- `/wizard` (`Routes.wizard`)
- `/results` (`Routes.results`) declared but not registered in `Routes.map`
- `/about`
- `/blog`
- `/login`
- `/signup`
- `/forgot-password`
- `/profile`
- `/admin/dashboard`
- `/admin/doctors`

### Navigation patterns
- Standard named navigation:
  - `Navigator.pushNamed(...)`
  - `Navigator.pushReplacementNamed(...)`
  - `Navigator.pushNamedAndRemoveUntil(...)`
- Constructor route for results:
  - `Navigator.push(context, MaterialPageRoute(builder: ...))`

## 7) State Management

No Provider/Riverpod/Bloc/GetX is used.

Current pattern:
- Local state in `StatefulWidget` + `setState`.
- Global auth session:
  - `AuthSession.token`
  - `AuthSession.user`
  - `AuthSession.userNotifier` (`ValueNotifier<AuthUser?>`)
- UI subscription:
  - `ValueListenableBuilder<AuthUser?>` in navbar auth actions.
- Async UI:
  - `FutureBuilder<Map<String, dynamic>>` in `ResultsPage`.

## 8) Assets and Icons

### Icon systems
- Material Icons (`Icons.*`) throughout UI.
- `cupertino_icons` package exists in dependencies but no active Cupertino icon usage in current UI layer.

### Image assets
- Centralized path constants in `lib/values/images.dart` as `ImagePath`.
- Asset directory: `assets/images/`
- Common usage:
```dart
Image.asset(ImagePath.logo)
Image.asset(ImagePath.background)
Image.asset(ImagePath.featureIcon1)
```

### Map visuals
- Uses `flutter_map` and `latlong2`.
- OSM tiles in results page map:
```dart
TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png')
```

## 9) Code Conventions

### Naming
- File names: `snake_case.dart`.
- Class names: `UpperCamelCase`.
- Private classes/methods: leading underscore (`_`).

### Organization
- Shared constants: `lib/values/*`.
- App bootstrap/routing/theme: `lib/app/*`, `lib/main.dart`.
- Reusable sections/components: `lib/widgets/*`.
- Feature pages: `lib/screens/<feature>/*`.
- API/auth state: `lib/services/*`.

### Build method style
- Large screens split into private section builders:
  - `_buildHero`, `_buildFeatureSection`, `_buildFaqSection`, etc.
- Reusable inline style helper methods on form pages:
  - `_inputDecoration(...)`
  - `_orb(...)`

### Dependency policy (current)
- Existing UI stack: Flutter Material + `google_fonts` + `flutter_map` + HTTP/auth libs already present.
- No state library or router package abstraction currently used.

## 10) New Page Implementation Rules (for future agents)

When adding a page, match these project rules exactly:
- Use `Theme.of(context).textTheme` and `AppColors`/`AppSpacing`/`AppRadius`.
- Reuse `NavBar` and `Footer` for marketing-style pages.
- Use named routes via `Routes` constants and register in `Routes.map` when route is constructor-free.
- If page requires constructor args, follow current pattern with `MaterialPageRoute`.
- Keep file in `lib/screens/<feature>/<page_name>.dart` with snake_case naming.
- Use `StatefulWidget + setState` unless a new page can stay stateless.
- Do not introduce new state-management or routing libraries.
