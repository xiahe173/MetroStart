# MetroStart

[中文](README.zh-cn.md) | English

A Windows 10 style tile Start menu for KDE Plasma 6, as a Plasma applet.

MetroStart reproduces the Windows 10 Start menu: pinned tiles with group
titles, an "all applications" list with a letter column and letter grid, and
the collapsible left rail with its power and user menus. It opens as a
full-screen overlay above the panel instead of a Plasma popup; a windowed
(non-full-screen) Start menu is available as well.

Everything machine specific — applications, icons, tile arrangement, wallpaper
and avatar — comes from Plasma or from a layout file in your home directory.
Nothing else on the system is modified.

Tested on **Plasma 6.6** / **Qt 6.10** (Wayland).

## Screenshots

| | |
|---|---|
| ![Pinned tiles](docs/tiles.webp) | ![All applications](docs/all_applications.webp) |
| Pinned tiles | All applications |
| ![Sidebar](docs/side_bar.webp) | ![Windowed](docs/windowed.webp) |
| Left rail expanded | Windowed Start menu |

## Features

- **Two layouts** — full-screen Start or a windowed menu whose width and height
  you can drag.
- **Tiles** — Windows 10 sizes (small and medium from the tile menu, wide and
  large through the layout file), group titles, and drag and drop for tiles and
  whole groups. The arrangement is saved as you edit it.
- **Applications** — the "all applications" list with letter headers, the
  letter grid, and a "recently added" section in the windowed menu.
- **Left rail** — expands on hover, with hibernate, shut down and restart, plus
  account, lock and sign out.
- **Context menus** — pin, unpin, resize, rename a group, open the file location
  or launch an application as administrator.
- **Looks and motion** — the cross-fade on open and close, the row-by-row tile
  entrance, the pointer-lit hover frames and the press ripples, all fitted to
  the Windows 10 reference.
- **Display aware** — the menu keeps its size relative to the rest of the
  desktop at any display scale factor, fills the work area and stops above the
  panel; the number of tile columns follows the screen width.
- **Experimental, off by default** — the coloured "early Windows" tile skin with
  its palettes and icon styles, live tiles (clock, battery, date, calendar,
  weather, photos) and their content-swap animations.

## Install

### From a release file

Download `MetroStart-<version>.plasmoid` from the [Release page](https://github.com/xiahe173/MetroStart/releases/latest), then choose *Add Widgets → Install
from File*, or install it from a terminal:

```bash
kpackagetool6 -t Plasma/Applet -i MetroStart-<version>.plasmoid
```

Then add **MetroStart** from *Add Widgets*. The applet sits in the panel and
opens the menu above it; the panel is never covered.

### From source

The applet is pure QML — there is nothing to compile:

```bash
cmake -B build
cmake --install build --prefix ~/.local
```

### Uninstall

```bash
kpackagetool6 -t Plasma/Applet -r org.kde.plasma.metrostart
```

Removing the applet from the panel is enough to undo it.

## Settings

*Appearance* page:

- **Icon** — the icon of the panel button (defaults to the Windows grid).
- **Accent colour** — used by the pressed group title, the drag placeholder and
  the rail marker.
- **Start menu layout** — full-screen or windowed.
- **Icon fill ratio** — icon themes pad their artwork, so tiles draw the icon in
  a slightly larger box. Lower it if the icons look too small, raise it if they
  overflow the tile. Default 85%.
- **Experimental options** — after ticking the switch: tile style and palette,
  weather source, live tile cycling and animation variants, the icon style of
  the early skin, and using the application's own colour as a tile background.
  While the switch is off, every one of these stays at its default, tiles ignore
  the colour and live-tile records of the layout file, and the tile context
  menu hides those entries.

*Language* page: the interface language of this applet alone — follow the
session, English or Simplified Chinese. It applies immediately, without restarting
plasmashell or changing the rest of the desktop.

## Layout file

The arrangement is stored in `~/.config/metrostart/layout.json`. You own it: a
column holds as many groups as you drag into it, and no group or column carries
a position.

```json
{
  "version": 2,
  "columns": [
    {
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
  ]
}
```

| Key | Meaning |
|---|---|
| `app` | The application's desktop file name; its name and icon are used automatically. Tiles whose application is not installed are skipped. |
| `label`, `icon` | Optional overrides. `icon` may be a theme icon name or an absolute path. |
| `size` | `1x1`, `2x2`, `4x2` or `4x4`. |
| `col`, `row` | Optional: pin the tile to an explicit cell inside its group. |
| group `title` | Shown above the group; empty by default. |

Tiles are packed left to right, top to bottom inside a group, and the tile area
scrolls downwards as it grows. The file does not record how many columns the
menu shows — the screen decides how many fit, so groups are reflowed into that
count when the menu opens on a display with room for a different number. Older
layout files that keep a flat `groups` list are migrated on load and keep their
arrangement. Without a layout file the menu starts with only the application
list; pinning your first application creates it.

## Licence

GPL-2.0-or-later.

<details>
<summary>Repository layout</summary>

```
package/contents/
  ui/       the applet: main.qml (entry and overlay window), MetroMenu.qml (the
            menu surface), TilesView/Tile, AppListView/CapitalView,
            Sidebar/Flyout, ContextMenu, Runtime (plasma data and the layout
            file), AppIndex (application menu), Layout.js/Edit.js (the layout
            file and its editing), Persistence.js (loading and saving it),
            metrics.js/CompactMetrics.js/motion.js (design constants and motion),
            Translations.qml with i18n/
  config/   main.xml (the settings) and their pages
  assets/   UI glyphs and the avatar's circular cut (circle.frag.qsb)
docs/       screenshots used by this README
tests/      the layout persistence tests
```
</details>

<details>
<summary>Technical notes</summary>

- **Design scale.** The menu is authored in design pixels of a 2560×1440 desktop
  at 150% scaling, i.e. one design pixel is 2/3 of a device-independent pixel;
  Qt maps the result to the display with the device pixel ratio. At 150% the
  rendering matches the reference exactly.
- **Rendering harness.** `MetroMenu` takes a single `context` object, so the
  out-of-tree render tooling can inject its own applications, layout, icons,
  wallpaper and avatar while still using the applet's own drawing code.
- **Wallpaper and rail.** The menu paints and dims the current wallpaper itself,
  and the rail blurs the content behind it in-app. No compositor effect is used,
  so the applet cannot affect other windows and looks the same with compositor
  blur disabled.
- **Avatar shader.** The circular cut is a fragment shader; after editing
  `circle.frag`, rebuild it with the Qt Shader Tools:
  `qsb --qt6 -o circle.frag.qsb circle.frag`.
- **Tests.** `node tests/persistence.test.js` covers first-run pinning, the
  layout file states and the save command, using the real libraries and real
  shell commands in temporary directories.
</details>
