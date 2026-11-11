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
* The menu paints the desktop wallpaper itself, aligned 1:1 with the screen,
  then applies the Windows 80 % backdrop. No compositor blur is involved.
* Fluent "Reveal": tiles and sidebar buttons get a 3 px border that only lights
  the part of the outline close to the pointer (radial falloff), plus a soft
  interior glow on the hovered control. The light is a pre-rendered radial
  texture, so it does not depend on shader support.

## Build and install

The applet is pure QML:

```bash
cmake -B build
cmake --install build --prefix ~/.local
```

The package is installed to
`~/.local/share/plasma/plasmoids/org.kde.plasma.metrostart`.

Then add **MetroStart** from *Add Widgets*. Nothing else in the system
configuration is touched; removing the applet is enough to undo it.

The menu stops above a 60 px panel by default. It is computed from
`Screen.availableGeometry` when the compositor reports a work area, otherwise
60 px is assumed.

### Wallpaper and acrylic

The menu reads the current desktop wallpaper from Plasma
(`desktops()[0]` wallpaper configuration) and paints it at 2560×1440 design
space, so it always aligns with the real desktop; the taskbar area is simply
clipped away. The content area is the Windows 80 % tint over that image.

The sidebar uses an in-app blurred copy of the same wallpaper (downsampled
2560×1440 → ~27×15 and scaled back up) under an 87 % tint. This gives the
Windows acrylic look without touching KWin's blur effect, so it cannot affect
other windows and works even when the compositor blur is disabled.

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
  RevealEdge.qml    one border edge with the radial pointer falloff
  RevealBorder.qml  the four edges of a control outline
  RevealGlow.qml    interior glow for the hovered control
  Sidebar.qml       left rail
  Flyout.qml        power / user flyouts
  Runtime.qml       live data: home, layout file, wallpaper, applications, user
  Avatar.qml        circular avatar (photo or fallback)
  AppIndex.qml      application menu enumeration (apps data engine)
  Layout.js         layout file -> pixel geometry
  Paths.js          XDG paths
  metrics.js        design constants
package/contents/assets/ui/   UI glyphs (hamburger, grid, list, power, ...)
```

`MetroMenu` takes a single `context` object so that a render harness can inject
its own applications, layout, icons, wallpaper and avatar while still using the
applet's rendering code.

## Licence

GPL-2.0-or-later.
