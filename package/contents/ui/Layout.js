// Tile layout: a JSON description is turned into absolute pixel geometry.
//
// Config format (see README):
//   { "version": 1, "columns": 3,
//     "groups": [ { "title": "", "x": 220, "y": 159,
//                   "tiles": [ { "app": "org.kde.dolphin.desktop", "size": "2x2" },
//                              { "label": "KiCad", "icon": "/path/kicad.png",
//                                "exec": "kicad", "size": "2x2", "col": 0, "row": 2 } ] } ] }
//
// Tiles are packed left to right, top to bottom inside a six cell wide group.
// `col`/`row` pin a tile to an explicit cell (used by the reference layouts).
.pragma library

var cell = 90
var gap = 6
var pitch = 96
var groupCols = 6
var groupGapX = 205
var groupGapY = 96
var groupWidth = groupCols * cell + (groupCols - 1) * gap

function sizeToCells(size) {
    switch (size) {
    case "1x1": return { cols: 1, rows: 1 }
    case "4x2": return { cols: 4, rows: 2 }
    case "4x4": return { cols: 4, rows: 4 }
    case "2x2":
    default:    return { cols: 2, rows: 2 }
    }
}

function pixelWidth(cols) {
    return cols * cell + (cols - 1) * gap
}

function pixelHeight(rows) {
    return rows * cell + (rows - 1) * gap
}

function findApp(apps, id) {
    for (var i = 0; i < apps.length; ++i) {
        if (apps[i].id === id)
            return apps[i]
    }
    return null
}

function newGrid() {
    return { used: {}, maxRow: 0 }
}

function isFree(grid, col, row, cols, rows) {
    for (var r = row; r < row + rows; ++r) {
        for (var c = col; c < col + cols; ++c) {
            if (grid.used[r + ":" + c])
                return false
        }
    }
    return true
}

function occupy(grid, col, row, cols, rows) {
    for (var r = row; r < row + rows; ++r) {
        for (var c = col; c < col + cols; ++c)
            grid.used[r + ":" + c] = true
    }
    if (row + rows > grid.maxRow)
        grid.maxRow = row + rows
}

function firstFree(grid, cols, rows) {
    for (var row = 0; row < 64; ++row) {
        for (var col = 0; col + cols <= groupCols; ++col) {
            if (isFree(grid, col, row, cols, rows))
                return { col: col, row: row }
        }
    }
    return { col: 0, row: 0 }
}

// Resolve one tile description into a positioned tile.
function resolveTile(tile, apps, groupX, groupY, grid) {
    var size = sizeToCells(tile.size)
    var pos
    if (tile.col !== undefined && tile.row !== undefined) {
        pos = { col: tile.col, row: tile.row }
    } else {
        pos = firstFree(grid, size.cols, size.rows)
    }
    occupy(grid, pos.col, pos.row, size.cols, size.rows)

    var app = tile.app ? findApp(apps, tile.app) : null
    return {
        x: groupX + pos.col * pitch,
        y: groupY + pos.row * pitch,
        w: pixelWidth(size.cols),
        h: pixelHeight(size.rows),
        label: tile.label !== undefined ? tile.label : (app ? app.name : ""),
        icon: tile.icon !== undefined ? tile.icon : (app ? app.icon : ""),
        exec: tile.exec !== undefined ? tile.exec : (app ? app.exec : ""),
        desktopId: app ? app.id : "",
        iconRect: tile.iconRect ? { x: tile.iconRect[0], y: tile.iconRect[1],
                                    w: tile.iconRect[2], h: tile.iconRect[3] } : null
    }
}

// Resolve the whole layout. `canvas` limits automatic placement.
function resolve(config, apps, canvas) {
    var result = { groups: [], width: 0, height: 0 }
    if (!config || !config.groups)
        return result

    var columns = config.columns || 3
    var auto = { col: 0, y: 0 }
    var colHeights = []

    for (var i = 0; i < config.groups.length; ++i) {
        var group = config.groups[i]
        var grid = newGrid()
        var gx = group.x
        var gy = group.y
        if (gx === undefined || gy === undefined) {
            // place into the next free column slot
            var col = 0
            while (col < columns - 1 && colHeights.length > col)
                col++
            gx = 220 + col * (groupWidth + groupGapX)
            gy = (colHeights.length > col ? colHeights[col] : 159)
            colHeights[col] = gy + 0 // updated below
        }
        var tiles = []
        for (var j = 0; j < group.tiles.length; ++j) {
            var spec = group.tiles[j]
            // an entry that names an unknown application is skipped
            if (spec.app && !findApp(apps, spec.app))
                continue
            tiles.push(resolveTile(spec, apps, gx, gy, grid))
        }
        if (grid.maxRow > 0) {
            var height = grid.maxRow * pitch - gap
            var usedCol = Math.round((gx - 220) / (groupWidth + groupGapX))
            if (usedCol >= 0 && usedCol < columns)
                colHeights[usedCol] = gy + height + groupGapY
            if (gy + height > result.height)
                result.height = gy + height
        }
        result.groups.push({ x: gx, y: gy, title: group.title || "", tiles: tiles })
        if (gx + groupWidth > result.width)
            result.width = gx + groupWidth
    }
    return result
}

// ---------------------------------------------------------------------------
// "All applications": three columns of entries grouped by first letter.
var appTop = 48
var appRowPitch = 66
var appSectionGap = 48
var appColumns = 3

function letterOf(name) {
    var c = name.length > 0 ? name.charAt(0).toUpperCase() : "#"
    return /[A-Z]/.test(c) ? c : "#"
}

function appSections(apps) {
    var sorted = apps.slice(0)
    sorted.sort(function (a, b) { return a.name.localeCompare(b.name) })
    var order = []
    var byLetter = {}
    for (var i = 0; i < sorted.length; ++i) {
        var letter = letterOf(sorted[i].name)
        if (!byLetter[letter]) {
            byLetter[letter] = []
            order.push(letter)
        }
        byLetter[letter].push(sorted[i])
    }
    order.sort()
    var cursor = appTop
    var sections = []
    for (var j = 0; j < order.length; ++j) {
        var entries = byLetter[order[j]]
        var rows = Math.ceil(entries.length / appColumns)
        var placed = []
        for (var k = 0; k < entries.length; ++k) {
            placed.push({
                name: entries[k].name,
                icon: entries[k].icon,
                path: entries[k].path,
                desktopId: entries[k].id,
                col: Math.floor(k / rows),
                row: k % rows
            })
        }
        sections.push({ letter: order[j], y: cursor, entries: placed })
        cursor += rows * appRowPitch + appSectionGap
    }
    return sections
}
