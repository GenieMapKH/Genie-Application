# Tilomnov Frontend Architecture Guideline

Welcome to the Tilomnov Frontend Guideline! This document serves as your map to navigate the newly refactored, highly modular Flutter codebase. It is designed following Clean Code principles (Robert C. Martin), ensuring that every file has a single responsibility, stays under 200 lines, and is easy to maintain.

---

## 🏗 Directory Structure Overview

The project follows a **Feature-First Architecture**. Instead of grouping by technical layers (e.g., all models together, all screens together), code is grouped by the business feature it supports.

```text
lib/
├── core/                   # Global configuration, routing, theme, and errors
├── shared/                 # Reusable widgets (buttons, dialogs) and utilities used across features
├── features/
│   ├── auth/               # Login, Sign Up, Token management
│   ├── home/               # Main Map, Drawing mode, Map controls, Bottom Nav
│   ├── property/           # Creating properties, viewing my properties, property lists
│   └── profile/            # User profile, settings, account management
```

---

## 🗺 Feature Breakdown & File Responsibilities

### 1. Home Feature (`lib/features/home/`)
Handles the primary Google Map experience, drawing polygons, clustering, and the property card carousel.

| File | What it handles | Essential Concepts to Learn | When to look here for errors |
|------|----------------|---------------------------|------------------------------|
| `providers/map_state_provider.dart` | The central state machine for the map. Holds drawing points, zoom levels, and the highlighted local polygon. | **Riverpod `StateNotifier`**, Immutable State | When drawing mode gets stuck, polygons don't update, or the map camera acts erratically. |
| `providers/main_nav_provider.dart` | Manages the active tab on the Bottom Navigation Bar. | **Riverpod `Notifier`** | When the wrong page is displayed after tapping a bottom tab. |
| `providers/map_properties_provider.dart` | Merges the user's own properties with the public map feed into one deduplicated list, tracking which ids the user owns. | **Provider composition** | When a property is missing from the map, duplicated, or wrongly shows an edit marker. |
| `providers/property_carousel_provider.dart` | Which property is selected and the distance-sorted list of neighbours the card carousel swipes through. | **Riverpod `Notifier`**, distance sorting | When tapping a dot opens the wrong card, or swiping doesn't move to nearby properties. |
| `screens/main_layout.dart` | The root Scaffold. Composes the Map, UI controls, card carousel, and Bottom Nav. | **Widget Composition** | When the overall layout is broken or overlapping weirdly. |
| `widgets/map/main_map_view.dart` | Embeds the `GoogleMap` widget and manages its `Completer`. Delegates layer building and camera focus. | **Google Maps Flutter**, Completers | When the map fails to load, crashes on startup, or camera animations fail. |
| `widgets/map/property_carousel.dart` | The horizontally swipeable strip of property cards above the bottom nav, plus its swipe-up-to-open gesture. | **PageView**, `PageController` sync | When cards open on the wrong index, don't slide in, or swiping up doesn't open detail. |
| `widgets/layout/main_layout_pages.dart` | The full-screen pages that slide over the map for the My Properties and User tabs. | **AnimatedSwitcher** | When tab transitions slide the wrong way or the map is wrongly covered. |
| `widgets/map/map_top_controls.dart` | The search bar, map skin toggle, and the floating property type filters. | **Stateless UI** | When the top search bar UI is misaligned. |
| `widgets/map/property_type_filters.dart` | The horizontal scrollable list of property types (House, Land, etc.). | **Local State (`StatefulWidget`)** | When filter selection doesn't highlight properly. |
| `utils/map_overlay_builder.dart` | Turns property data plus map state into the marker/polygon/polyline sets for one render pass. | Sets, zoom bands | When the wrong layer renders for a zoom level, or selection highlighting is off. |
| `utils/map_layer_builder.dart` | Pure static functions that calculate where to place markers, how to cluster them, and how to draw polygons. | **Geometry**, Sets, Markers | When markers disappear, clustering logic fails, or polygon areas are calculated incorrectly. |
| `utils/map_camera_focus.dart` | Zoom-to-fit and the camera offset that keeps a selected property clear of the card carousel. | **Web Mercator projection** | When a selected property sits behind the card or is framed too tightly. |
| `utils/map_location_service.dart` | Geolocator permission handling and "fly to" camera helpers. | **Geolocator permissions** | When the current-location button fails or permission prompts misbehave. |
| `utils/document_scanner_service.dart` | Handles camera access, image cropping, and Google ML Kit OCR to extract UTM coordinates. | **ImageCropper**, **Google ML Kit** | When the document scanner crashes, camera permissions fail, or OCR returns nothing. |

### 2. Property Feature (`lib/features/property/`)
Handles displaying lists of properties, the property detail view, and the flow to create new ones.

| File | What it handles | Essential Concepts to Learn | When to look here for errors |
|------|----------------|---------------------------|------------------------------|
| `view_models/property_providers.dart` | Fetches and caches the user's properties and public properties from the backend API. | **Riverpod `AsyncValue`**, Error handling | When properties fail to load from the server or show "Offline" constantly. |
| `view_models/property_recommendations_provider.dart` | The "Similar Property" and "Property for you" lists, derived from already-loaded map data. | **`Provider.family`** | When recommendations are empty, duplicated, or include the viewed property. |
| `utils/property_format.dart` | Shared price, size and spec-line formatting plus the property type icon map. | Pure functions, `intl` | When a price, size or "4 bds \| 5 ba" line renders inconsistently. |
| `screens/my_properties_page.dart` | The root page for viewing "My Properties". | **RefreshIndicator**, Async UI | When pulling to refresh doesn't work or the page gets stuck loading. |
| `widgets/property_item_card.dart` | The map card: photo gallery, type pill, favourite, price and owner. | Layered `Stack` UI | When the map card's content or badges look wrong. |
| `widgets/property_image_gallery.dart` | Swipeable image gallery with a windowed dot indicator, shared by cards and tiles. | **PageView**, local state | When images don't swipe or the dot indicator overflows. |
| `widgets/detail/property_detail_sheet.dart` | The full detail view: a two-stage draggable sheet (brief → full) composing every detail section. | **DraggableScrollableSheet**, snap sizes | When the sheet won't expand, snaps oddly, or the contact bar floats. |
| `widgets/detail/` (sections) | Summary, highlights, map preview, QR share, recommendation grids and the contact bar. | Section composition | When one section of the detail view renders incorrectly. |
| `widgets/my_properties/property_tabs.dart` | The top row of tabs (Active, Pending, Draft, Sold) showing counts. | **List Filtering** | When the count of properties in a tab is mathematically wrong. |
| `widgets/my_properties/property_options_sheet.dart` | The bottom sheet that slides up when tapping options (Publish, Draft, Delete). | **ModalBottomSheet** | When tapping "Delete" or "Publish" crashes or does nothing. |

### 3. Profile Feature (`lib/features/profile/`)
Handles user account settings.

| File | What it handles | Essential Concepts to Learn | When to look here for errors |
|------|----------------|---------------------------|------------------------------|
| `view_models/user_providers.dart` | Fetches the current user's profile data. | **Riverpod `FutureProvider`** | When the profile name or phone number is outdated. |
| `screens/user_profile_page.dart` | The root page for the user's settings. | **Scaffold Layout** | When the profile page layout is broken. |
| `widgets/profile_info_section.dart` | Renders the list of settings rows and the Logout button. | **ListView** | When tapping a setting row does nothing, or Logout fails. |
| `widgets/profile_edit_dialog.dart` | The popup dialog used to edit a username or phone number. Handles the API call internally. | **TextEditingController**, Forms | When saving a new phone number fails, or validation errors don't show up. |

---

## 🛠 Core Technologies You Must Know

If you are new to this codebase, you must understand these three core concepts:

1. **Riverpod (`flutter_riverpod`)**:
   - We strictly avoid `setState` for business logic.
   - We use `ref.watch()` to rebuild UI when data changes.
   - We use `ref.read().notifier` to trigger actions (like deleting a property).
   - If UI isn't updating, you probably used `ref.read` inside a `build` method instead of `ref.watch`.

2. **Google Maps (`google_maps_flutter`)**:
   - The map requires a `Set<Marker>` and `Set<Polygon>`.
   - Modifying these sets triggers the map to redraw. This is heavy! That is why we extract this logic into `MapLayerBuilder.dart` to keep it testable and fast.

3. **Clean Architecture / Modularity**:
   - No single file should exceed ~200 lines. 
   - If a file grows, identify what independent widget or logic can be extracted into a new file.

---

## ✨ Motion, Shape & Glass

The app moves and is shaped the way Apple's apps are. Reuse these instead of writing new durations, curves or radii.

- **Springs, not timed curves** (`lib/core/theme/app_motion.dart`). They are described like SwiftUI's springs (a duration and a bounce):
  - `smooth` (0.5 s, no bounce): things that arrive, such as pages, sheets and panels.
  - `snappy` (0.35 s, 0.15): direct answers to a touch.
  - `bouncy` (0.45 s, 0.3): only for small celebrations, such as a listing being saved.
  - `press`: following a finger down.
  - `selection`: the tab droplet.

  Drive springs with `controller.animateWith(SpringSimulation(spring, value, target, controller.velocity))`, so an interrupted motion carries on from where it is. Use `AnimationController.unbounded` when the spring may overshoot.
- **Reduce Motion**: always check `AppMotion.reduceMotionOf(context)`. Never check only `MediaQuery.disableAnimationsOf`, which misses iOS's setting. With reduced motion, motion becomes an instant change or a fade; haptics stay.
- **Presses**: wrap tappable custom surfaces in `TactileButton`. It sinks at once on touch, holds while pressed, and springs back on release.
- **Haptics** (`lib/core/device/app_haptics.dart`): use them for a choice or an outcome, never on every touch.
  - `selection()`: a tab or option was picked.
  - `lightTap()`: something was saved or sent.
- **Continuous corners** (`lib/core/theme/app_shapes.dart`):
  - Cards, sheets and dialogs use `RoundedSuperellipseBorder` / `ClipRSuperellipse`, so curvature eases into the edge. Shadows may keep a plain `BorderRadius`, which is quicker.
  - An inner shape inset by `p` uses `AppShapes.concentric(outer, p)`.
- **Glass** (`lib/features/home/presentation/widgets/glass/`):
  - **Who gets it:** only phones whose own interface is glass: iOS 26+, and Xiaomi/Redmi/POCO on HyperOS 3+ that are not low-RAM (`GlassCapability`).
  - **Opting out:** users can turn it off in Settings. It also falls back to the solid look with Reduce Transparency or increased contrast.
  - **Where:** glass is only for the navigation layer (bottom bar, map buttons), never for content such as cards, sheets or chat.
  - **Blur:** one plain `ImageFilter.blur`, shared through the `BackdropGroup` in `MainLayout`. iOS can apply nothing else over the map.
  - **Painting:** paint selection and highlights on the glass, never glass on glass, and don't animate the blur.
  - **Testing:** try it on any device with `--dart-define=FORCE_GLASS=true`.

---

## 🚨 Troubleshooting Guide

- **Error: "ConsumerStatefulWidget requires a ConsumerState"**
  - *Fix:* You likely changed a `StatefulWidget` to a `ConsumerStatefulWidget` but forgot to change the accompanying `State` class to `ConsumerState`.

- **Error: UI is janky or slow when panning the map**
  - *Fix:* Check `main_map_view.dart`. Are you recreating all icons synchronously inside the build method? Ensure `DynamicMapMarkers` are awaited properly or cached in state.

- **Error: "Target of URI doesn't exist" after moving files**
  - *Fix:* Update your imports. Use the VS Code / IDE auto-import feature to quickly fix broken paths.

- **Error: A widget is not updating when State changes**
  - *Fix:* Ensure the widget is a `ConsumerWidget` and you are using `ref.watch(provider)` instead of just reading it once.

Always remember: **Keep it small, keep it focused, keep it clean.**
