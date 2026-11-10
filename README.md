# MetroStart

A Windows 10 style tile Start menu for KDE Plasma 6, written as a Plasma applet.

The design (80 % dark backdrop over the wallpaper, translucent tiles on a 90 px
grid, collapsible sidebar, three column application list) is reproduced from a
reference capture; the applet itself only contains the implementation. All
machine specific data - applications, icons, tile layout, wallpaper and avatar -
is provided by Plasma or read from a configuration file outside this repository.

Tested on **Plasma 6.6** / **Qt 6.10** (Wayland).

## What works

* Pinned tiles from a JSON layout file, launched on click.
* "All applications" built from the same desktop entries the application
  launcher uses (Plasma `apps` data engine).
* Collapsible sidebar, power and user flyouts, group titles.
* Icons from the icon theme; the user's avatar from the account settings.
* Full-screen menu without dialog padding: the applet opens its own
  layer-shell overlay window instead of using the Plasma popup.
* Windows-accurate 80 % backdrop; the sidebar asks KWin for a blur-behind
  region through the helper plugin.

## Build and install

The applet has a small C++ QML plugin for compositor effects (blur behind,
slide), so the build needs Qt 6 and KF6 WindowSystem development files:

```bash
cmake -B build
cmake --build build
cmake --install build --prefix ~/.local
```

The package is installed to
`~/.local/share/plasma/plasmoids/org.kde.plasma.metrostart`; the helper plugin
lives inside it (`contents/ui/effects`).

Then add **MetroStart** from *Add Widgets*. Nothing else in the system
configuration is touched; removing the applet is enough to undo it.

The menu stops above a 60 px panel by default. It is computed from
`Screen.availableGeometry` when the compositor reports a work area, otherwise
60 px is assumed.

### Blur

The sidebar uses KWin's blur-behind effect. No window rule is needed: the
applet requests the region itself. KWin's *Blur* desktop effect must be enabled
(System Settings → Desktop Effects). If it is disabled the sidebar falls back
to a flat tint; the main menu area is intentionally not blurred, matching the
reference (80 % tint, no backdrop blur).

## Layout file

Tiles are read from `~/.config/metrostart/layout.json`:

```json
{
  "version": 1,
  "columns": 3,
  "groups": [
    {
      "title": "",
      "tiles": [
        { "app": "org.kde.dolphin.desktop", "size": "2x2" },
        { "app": "org.kde.konsole.desktop", "size": "1x1" },
        { "label": "KiCad", "icon": "kicad",
          "exec": "kicad", "size": "2x2" }
      ]
    }
  ]
}
```

* `app` - desktop file name (menu id) from the application menu; its name and
  icon are used automatically.
* `label`, `icon` - optional overrides. `icon` may be an absolute path or an
  icon theme name.
* `size` - `1x1`, `2x2`, `4x2` or `4x4` (Windows 10 tile sizes).
* `col` / `row` - optional, pin a tile to an explicit cell inside the group.
* Tiles whose `app` is not installed are skipped.
* group `title` - shown above the group, empty by default.
* group `x` / `y` - optional, pin a group to an explicit position.

Tiles are packed left to right, top to bottom in a six cell wide group. Groups
flow into `columns` columns. Without a layout file the menu shows only the
application list.

## Repository layout

```
package/contents/ui/
  main.qml          Plasma applet entry (panel button + popup)
  MetroMenu.qml     the menu surface; accepts an injected `context`
  TilesView.qml     groups and tiles
  AppListView.qml   the "all applications" list
  Sidebar.qml       left rail
  Flyout.qml        power / user flyouts
  Runtime.qml       live data: home, layout file, applications, user
  Avatar.qml        circular avatar (photo or fallback)
  effects/          QML plugin: KWindowEffects blur/slide
  AppIndex.qml      application menu enumeration (apps data engine)
  Layout.js         layout file -> pixel geometry
  Paths.js          XDG paths
  metrics.js        design constants
package/contents/assets/ui/   UI glyphs (hamburger, grid, list, power, ...)
plugin/plugin.cpp             QML plugin implementation
```

`MetroMenu` takes a single `context` object so that a render harness can inject
its own applications, layout, icons, wallpaper and avatar while still using the
applet's rendering code.

## Licence

GPL-2.0-or-later.
