// Layout editing: the mutable side of the tile layout.
//
// The config keeps explicit cell coordinates (col/row) so that groups can have
// holes, but a group must never contain a completely empty row and never end
// with one: `normalizeGroup()` removes those rows and shifts the rest up. Tile
// and group ids are added on load; they only exist in memory and give the
// renderer a stable identity to animate between two layouts.
.pragma library
.import "metrics.js" as Metrics
.import "Layout.js" as Layout

function clone(value) {
    return JSON.parse(JSON.stringify(value))
}

function tileCells(tile) {
    return Layout.sizeToCells(tile.size)
}

// ---------------------------------------------------------------------------
// Normalising

function occupancy(tiles) {
    var used = {}
    for (var i = 0; i < tiles.length; ++i) {
        var cells = tileCells(tiles[i])
        for (var r = tiles[i].row; r < tiles[i].row + cells.rows; ++r)
            for (var c = tiles[i].col; c < tiles[i].col + cells.cols; ++c)
                used[r + ":" + c] = true
    }
    return used
}

function hasOverlap(tiles) {
    var used = {}
    for (var i = 0; i < tiles.length; ++i) {
        var cells = tileCells(tiles[i])
        for (var r = tiles[i].row; r < tiles[i].row + cells.rows; ++r)
            for (var c = tiles[i].col; c < tiles[i].col + cells.cols; ++c) {
                if (used[r + ":" + c])
                    return true
                used[r + ":" + c] = true
            }
    }
    return false
}

function maxRowOf(tiles) {
    var maxRow = 0
    for (var i = 0; i < tiles.length; ++i) {
        var cells = tileCells(tiles[i])
        maxRow = Math.max(maxRow, tiles[i].row + cells.rows)
    }
    return maxRow
}

function maxColOf(tiles) {
    var maxCol = 0
    for (var i = 0; i < tiles.length; ++i) {
        var cells = tileCells(tiles[i])
        maxCol = Math.max(maxCol, tiles[i].col + cells.cols)
    }
    return maxCol
}

// Drop every row that no tile touches; the rows below move up. A row that a
// 2x2 tile only clips counts as used (the tile is in it).
function normalizeGroup(group) {
    if (!group.tiles)
        group.tiles = []
    for (;;) {
        var used = occupancy(group.tiles)
        var maxRow = maxRowOf(group.tiles)
        var empty = -1
        for (var r = 0; r < maxRow && empty < 0; ++r) {
            var any = false
            for (var c = 0; c < 16 && !any; ++c)
                any = used[r + ":" + c] === true
            if (!any)
                empty = r
        }
        if (empty < 0)
            return group
        for (var i = 0; i < group.tiles.length; ++i) {
            if (group.tiles[i].row > empty)
                group.tiles[i].row -= 1
        }
    }
}

// Reading order: top row first, then left to right.
function sortReadingOrder(tiles) {
    tiles.sort(function (a, b) {
        return a.row !== b.row ? a.row - b.row : a.col - b.col
    })
    return tiles
}

// ---------------------------------------------------------------------------
// Identity

// Older layouts keep a flat `groups` list; group them into columns the same way
// Layout.configColumns() does so the resolver sees the original arrangement.
// The returned config is a fresh copy: neither the groups nor their tiles are
// shared with the input, so the id pass below cannot mutate the caller's data.
function legacyColumns(config) {
    var groups = config && config.groups ? config.groups : []
    var keys = []
    var byKey = {}
    for (var g = 0; g < groups.length; ++g) {
        var group = clone(groups[g])
        var key = group.column
        if (key === undefined)
            key = group.x !== undefined ? group.x : 0
        key = String(key)
        if (!byKey[key]) {
            byKey[key] = []
            keys.push(key)
        }
        byKey[key].push(group)
    }
    // x positions and column indices both sort numerically
    keys.sort(function (a, b) { return parseFloat(a) - parseFloat(b) })
    var columns = []
    for (var k = 0; k < keys.length; ++k)
        columns.push({ groups: byKey[keys[k]] })
    return { columns: columns }
}

function prepare(config) {
    var source = config && config.columns ? config : legacyColumns(config)
    var copy = clone(source)
    var groupSeq = 0
    var tileSeq = 0
    for (var c = 0; c < copy.columns.length; ++c) {
        var column = copy.columns[c]
        column.id = "c" + c
        if (!column.groups)
            column.groups = []
        for (var g = 0; g < column.groups.length; ++g) {
            var group = column.groups[g]
            group.id = group.id || ("g" + (groupSeq++))
            if (!group.tiles)
                group.tiles = []
            for (var t = 0; t < group.tiles.length; ++t) {
                var tile = group.tiles[t]
                tile.id = tile.id || ("t" + (tileSeq++))
            }
            normalizeGroup(group)
        }
    }
    return copy
}

// Copy without the in-memory ids: what gets written to layout.json.
function forStorage(config) {
    var copy = clone(config)
    for (var c = 0; c < copy.columns.length; ++c) {
        delete copy.columns[c].id
        var groups = copy.columns[c].groups
        for (var g = 0; g < groups.length; ++g) {
            delete groups[g].id
            delete groups[g].placeholder
            for (var t = 0; t < groups[g].tiles.length; ++t)
                delete groups[g].tiles[t].id
        }
    }
    return copy
}

function findTile(config, tileId) {
    for (var c = 0; c < config.columns.length; ++c) {
        var groups = config.columns[c].groups
        for (var g = 0; g < groups.length; ++g) {
            for (var t = 0; t < groups[g].tiles.length; ++t) {
                if (groups[g].tiles[t].id === tileId)
                    return { column: c, group: g, tile: t }
            }
        }
    }
    return null
}

// ---------------------------------------------------------------------------
// Placing tiles

// Move a tile inside its group to the cell under the pointer.
//
// Windows keeps the grid absolute: a tile is dropped into the cell it was
// dropped on, holes stay where they are (nothing slides left or up to fill
// them, small tiles do not nestle into the gaps of large ones) and when the
// target is taken the group opens a row underneath the tiles in the way and
// pushes everything below it down. Dropping past the last row appends a row.
// Place a tile in a group's grid. `allowSwap` reorders within a row (a tile
// dropped on another tile of the same row swaps with it); otherwise the tile
// opens a row below whatever is in the way.
function placeTileInGroup(group, tile, col, row, allowSwap) {
    var cells = tileCells(tile)
    var width = Math.max(Metrics.groupMinCells, maxColOf(group.tiles), col + cells.cols)
    var fromRow = tile.row
    var fromCol = tile.col
    col = Math.max(0, Math.min(col, width - cells.cols))
    row = Math.max(0, row)
    if (allowSwap)
        row = Math.min(row, maxRowOf(group.tiles))

    var occupant = null
    for (var k = 0; k < group.tiles.length; ++k) {
        var other = group.tiles[k]
        var size = tileCells(other)
        var overlapX = col < other.col + size.cols && other.col < col + cells.cols
        var overlapY = row < other.row + size.rows && other.row < row + cells.rows
        if (overlapX && overlapY && occupant === null)
            occupant = other
    }

    if (occupant !== null && allowSwap && occupant.row === fromRow) {
        // same row: swap, so nothing is pushed into another row
        var oldCol = occupant.col, oldRow = occupant.row
        occupant.col = fromCol
        occupant.row = fromRow
        tile.col = col
        tile.row = row
        group.tiles.push(tile)
        if (!hasOverlap(group.tiles) && maxColOf(group.tiles) <= Math.max(width, 8)) {
            normalizeGroup(group)
            return true
        }
        occupant.col = oldCol
        occupant.row = oldRow
        group.tiles.splice(group.tiles.indexOf(tile), 1)
    }

    if (occupant !== null) {
        // open a row right below the tile in the way
        var insertRow = occupant.row + tileCells(occupant).rows
        for (var t = 0; t < group.tiles.length; ++t) {
            if (group.tiles[t].row >= insertRow)
                group.tiles[t].row += cells.rows
        }
        row = insertRow
    }

    tile.col = col
    tile.row = row
    group.tiles.push(tile)
    normalizeGroup(group)
    return true
}

function moveTileWithinGroup(config, tileId, col, row) {
    var where = findTile(config, tileId)
    if (where === null)
        return null
    var next = clone(config)
    var group = next.columns[where.column].groups[where.group]
    var tile = null
    for (var i = 0; i < group.tiles.length; ++i) {
        if (group.tiles[i].id === tileId) {
            tile = group.tiles.splice(i, 1)[0]
            break
        }
    }
    if (tile === null)
        return null
    // The tile leaves its cells behind; only rows that became completely empty
    // disappear (a group must not contain an empty row).
    normalizeGroup(group)
    placeTileInGroup(group, tile, col, row, true)
    return next
}

// Take a tile out of its group; a group that loses its last tile disappears
// (and a column that loses its last group). Returns the new config and the
// removed tile.
function takeTile(config, tileId) {
    var where = findTile(config, tileId)
    if (where === null)
        return null
    var next = clone(config)
    var groups = next.columns[where.column].groups
    var group = groups[where.group]
    var index = -1
    for (var i = 0; i < group.tiles.length; ++i) {
        if (group.tiles[i].id === tileId) {
            index = i
            break
        }
    }
    if (index < 0)
        return null
    var tile = group.tiles.splice(index, 1)[0]
    normalizeGroup(group)
    if (group.tiles.length === 0)
        groups.splice(where.group, 1)
    if (groups.length === 0)
        next.columns.splice(where.column, 1)
    return { config: next, tile: tile }
}

// Move a tile into another group: it leaves a hole in the source group and is
// placed in the target by the same grid rules (no swap across groups).
function moveTileToGroup(config, tileId, targetGroupId, col, row) {
    var where = findTile(config, tileId)
    if (where === null)
        return null
    var sourceId = config.columns[where.column].groups[where.group].id
    if (sourceId === targetGroupId)
        return moveTileWithinGroup(config, tileId, col, row)
    var taken = takeTile(config, tileId)
    if (taken === null)
        return null
    var target = findGroup(taken.config, targetGroupId)
    if (target === null)
        return null
    placeTileInGroup(target.group, taken.tile, col, row, false)
    return taken.config
}

function nextGroupId(config) {
    var max = -1
    for (var c = 0; c < config.columns.length; ++c) {
        for (var g = 0; g < config.columns[c].groups.length; ++g) {
            var id = config.columns[c].groups[g].id || ""
            var n = parseInt(id.replace(/^g/, ""), 10)
            if (!isNaN(n) && n > max)
                max = n
        }
    }
    return "g" + (max + 1)
}

// While dragging over empty space only the candidate bar is shown: the group is
// inserted empty (the view draws the bar because of the placeholder marker) and
// the tile itself is not in the layout, so no tile height is reserved.
function previewNewGroup(config, tileId, column, index) {
    if (findTile(config, tileId) === null)
        return null
    // The tile stays in its group (hidden by the view, so it reads as a hole);
    // the new group is inserted empty so only its candidate bar takes space.
    var group = { id: nextGroupId(config), title: "", placeholder: true, tiles: [] }
    return insertGroup(config, group, column, index)
}

// Drop a tile between groups (or at the end of a column): a new group is
// created there, holding only that tile.
function newGroupWithTile(config, tileId, column, index) {
    var where = findTile(config, tileId)
    if (where === null)
        return null
    var fromColumn = where.column
    var taken = takeTile(config, tileId)
    if (taken === null)
        return null
    var tile = taken.tile
    tile.col = 0
    tile.row = 0
    var group = { id: nextGroupId(taken.config), title: "", placeholder: true, tiles: [tile] }
    // a source column that disappeared shifts the target left
    var target = column
    if (taken.config.columns.length < config.columns.length && column > fromColumn)
        target = column - 1
    return insertGroup(taken.config, group, target, index)
}

// Committed drop: the placeholder marker must not survive into the layout.
function finalize(config) {
    var copy = clone(config)
    for (var c = 0; c < copy.columns.length; ++c) {
        for (var g = 0; g < copy.columns[c].groups.length; ++g)
            delete copy.columns[c].groups[g].placeholder
    }
    return copy
}

// ---------------------------------------------------------------------------
// Groups

function findGroup(config, groupId) {
    for (var c = 0; c < config.columns.length; ++c) {
        var groups = config.columns[c].groups
        for (var g = 0; g < groups.length; ++g) {
            if (groups[g].id === groupId)
                return { column: c, index: g, group: groups[g] }
        }
    }
    return null
}

function removeGroup(config, groupId) {
    var where = findGroup(config, groupId)
    if (where === null)
        return null
    var next = clone(config)
    next.columns[where.column].groups.splice(where.index, 1)
    // a column that lost its last group disappears
    if (next.columns[where.column].groups.length === 0)
        next.columns.splice(where.column, 1)
    return next
}

// Insert a group (already prepared) into `column` at `index`. The column index
// is clamped, so dropping past the last column appends to the last one.
function insertGroup(config, group, column, index) {
    var next = clone(config)
    if (next.columns.length === 0)
        next.columns.push({ groups: [] })
    var c = Math.max(0, Math.min(column, next.columns.length - 1))
    var groups = next.columns[c].groups
    var at = Math.max(0, Math.min(index, groups.length))
    groups.splice(at, 0, clone(group))
    return next
}

// Where the dragged group would land, as a collapsed placeholder: the group
// keeps its id (so the view can draw the placeholder bar) but loses its tiles.
function previewGroupDrop(config, groupId, column, index) {
    var where = findGroup(config, groupId)
    if (where === null)
        return null
    var group = where.group
    var collapsed = clone(group)
    collapsed.tiles = []
    var without = removeGroup(config, groupId)
    if (without === null)
        return null
    // removing the source column may shift the target column left
    var target = column
    if (without.columns.length < config.columns.length && column > where.column)
        target = column - 1
    return insertGroup(without, collapsed, target, index)
}

// Commit: move the real group to the drop position.
function moveGroup(config, groupId, column, index) {
    var where = findGroup(config, groupId)
    if (where === null)
        return null
    var group = where.group
    var without = removeGroup(config, groupId)
    if (without === null)
        return null
    var target = column
    if (without.columns.length < config.columns.length && column > where.column)
        target = column - 1
    return insertGroup(without, group, target, index)
}

// ---------------------------------------------------------------------------
// Context menu edits

// Change a tile's size, keeping its top-left cell. The tile is taken out of the
// grid first so the group re-flows around the new footprint (the reference lets
// a grown tile push the tiles below it down, it never shrinks them).
function setTileSize(config, tileId, size) {
    var where = findTile(config, tileId)
    if (where === null)
        return null
    var next = clone(config)
    var group = next.columns[where.column].groups[where.group]
    var tile = null
    for (var i = 0; i < group.tiles.length; ++i) {
        if (group.tiles[i].id === tileId) {
            tile = group.tiles.splice(i, 1)[0]
            break
        }
    }
    if (tile === null)
        return null
    var col = tile.col
    var row = tile.row
    normalizeGroup(group)
    tile.size = size
    tile.col = col
    tile.row = row
    placeTileInGroup(group, tile, col, row, false)
    return next
}

// Change a tile's size the way the shell does: a grown tile takes the cells
// around it when they are free; if they are taken it is moved to the first
// free spot (like a newly added tile) and fades in there.
function resizeTile(config, tileId, size) {
    var where = findTile(config, tileId)
    if (where === null)
        return null
    var next = clone(config)
    var group = next.columns[where.column].groups[where.group]
    var tile = group.tiles[where.tile]
    var cells = tileCells({ size: size })
    var col = tile.col
    var row = tile.row

    // Is the new footprint free where the tile sits? (ignore the tile itself)
    var grid = {}
    for (var i = 0; i < group.tiles.length; ++i) {
        var other = group.tiles[i]
        if (other === tile)
            continue
        var oc = tileCells(other)
        for (var r = other.row; r < other.row + oc.rows; ++r) {
            for (var c = other.col; c < other.col + oc.cols; ++c)
                grid[r + ":" + c] = true
        }
    }
    var fits = true
    for (var rr = row; rr < row + cells.rows && fits; ++rr) {
        for (var cc = col; cc < col + cells.cols && fits; ++cc)
            fits = grid[rr + ":" + cc] !== true
    }
    if (fits) {
        tile.size = size
        normalizeGroup(group)
        return next
    }

    // No room here: take the tile out and give it the first free spot of the
    // group, otherwise a new group at the end of the last column.
    group.tiles.splice(group.tiles.indexOf(tile), 1)
    normalizeGroup(group)
    var spot = firstFreeSpot(group, cells)
    if (spot !== null) {
        tile.col = spot.col
        tile.row = spot.row
        tile.size = size
        group.tiles.push(tile)
        normalizeGroup(group)
        return next
    }
    if (group.tiles.length === 0) {
        // the group is now empty: reuse it
        tile.col = 0
        tile.row = 0
        tile.size = size
        group.tiles.push(tile)
        return next
    }
    var column = next.columns[next.columns.length - 1]
    tile.col = 0
    tile.row = 0
    tile.size = size
    column.groups.push({ title: "", tiles: [tile] })
    return next
}

// First cell of a group that can hold a `cells` footprint (columns of the
// group only, like the newly added tiles).
function firstFreeSpot(group, cells) {
    var grid = {}
    for (var i = 0; i < group.tiles.length; ++i) {
        var other = group.tiles[i]
        var oc = tileCells(other)
        for (var r = other.row; r < other.row + oc.rows; ++r) {
            for (var c = other.col; c < other.col + oc.cols; ++c)
                grid[r + ":" + c] = true
        }
    }
    for (var row = 0; row < 12; ++row) {
        for (var col = 0; col < 8; ++col) {
            var free = true
            for (var rr = row; rr < row + cells.rows && free; ++rr) {
                for (var cc = col; cc < col + cells.cols && free; ++cc)
                    free = grid[rr + ":" + cc] !== true
            }
            if (free)
                return { col: col, row: row }
        }
    }
    return null
}

// Rename a group (empty string clears the title).
// Style slot of one tile (-1 = "auto", derived from the app name in
// TileColors.js). Keeps the rest of the layout untouched.
function setTileStyle(config, tileId, style) {
    var where = findTile(config, tileId)
    if (where === null)
        return null
    var next = clone(config)
    var tile = next.columns[where.column].groups[where.group].tiles[where.tile]
    if (style === undefined || style === null || style < 0)
        delete tile.style
    else
        tile.style = style
    return next
}

// Custom background / text colour of one tile; "" removes the override.
function setTileColor(config, tileId, color, fg) {
    var where = findTile(config, tileId)
    if (where === null)
        return null
    var next = clone(config)
    var tile = next.columns[where.column].groups[where.group].tiles[where.tile]
    if (color === undefined || color === null || color === "")
        delete tile.color
    else
        tile.color = color
    if (fg === undefined || fg === null || fg === "")
        delete tile.fgColor
    else
        tile.fgColor = fg
    return next
}

// Live content of one tile: null removes it, otherwise { type: "clock" } and
// so on (see LiveTile.qml).
function setTileLive(config, tileId, type) {
    var where = findTile(config, tileId)
    if (where === null)
        return null
    var next = clone(config)
    var tile = next.columns[where.column].groups[where.group].tiles[where.tile]
    if (!type || type === "")
        delete tile.live
    else
        tile.live = { type: type }
    return next
}

function setGroupTitle(config, groupId, title) {
    var next = clone(config)
    var found = null
    for (var c = 0; c < next.columns.length && found === null; ++c) {
        var groups = next.columns[c].groups
        for (var g = 0; g < groups.length; ++g) {
            if (groups[g].id === groupId) {
                found = groups[g]
                break
            }
        }
    }
    if (found === null)
        return null
    found.title = title
    return next
}

// Remove a tile from the start menu ("从开始屏幕取消固定"). A group that loses
// its last tile disappears, as does a column that loses its last group.
function removeTile(config, tileId) {
    var taken = takeTile(config, tileId)
    return taken === null ? null : taken.config
}

// Fresh in-memory id for a tile created at runtime. Ids are not stored (see
// forStorage), but every tile needs one while it is on screen: the tile model
// keys on it, so a tile without an id would render with no data (an empty
// icon).
function nextTileId(config) {
    var max = -1
    for (var c = 0; c < config.columns.length; ++c) {
        var groups = config.columns[c].groups
        for (var g = 0; g < groups.length; ++g) {
            var tiles = groups[g].tiles || []
            for (var t = 0; t < tiles.length; ++t) {
                var m = /^t(\d+)$/.exec(tiles[t].id || "")
                if (m !== null)
                    max = Math.max(max, parseInt(m[1], 10))
            }
        }
    }
    return "t" + (max + 1)
}

// Add an application to the start menu ("固定到开始屏幕"): the last group that
// still has room, otherwise a new group in the last column (as the reference
// appends to the end of the menu).
function addTile(config, appId, size) {
    var next = clone(config)
    var tileSize = size || "2x2"
    var cells = tileCells({ size: tileSize })
    if (next.columns.length === 0)
        next.columns.push({ groups: [] })
    for (var c = next.columns.length - 1; c >= 0; --c) {
        var groups = next.columns[c].groups
        for (var g = groups.length - 1; g >= 0; --g) {
            var grid = occupancy(groups[g].tiles)
            var spot = null
            for (var r = 0; r < 8 && spot === null; ++r) {
                for (var col = 0; col < Metrics.groupMinCells; ++col) {
                    var free = true
                    for (var rr = r; rr < r + cells.rows && free; ++rr) {
                        for (var cc = col; cc < col + cells.cols && free; ++cc)
                            free = grid[rr + ":" + cc] !== true
                    }
                    if (free) {
                        spot = { col: col, row: r }
                        break
                    }
                }
            }
            if (spot !== null) {
                groups[g].tiles.push({ id: nextTileId(next), app: appId, size: tileSize,
                                       col: spot.col, row: spot.row })
                normalizeGroup(groups[g])
                return next
            }
        }
        break   // only the last column gets new groups
    }
    var column = next.columns[next.columns.length - 1]
    // The tile is pinned to an explicit cell: a tile without col/row is placed
    // by the resolver alone, so the next pin would see an empty grid and stack
    // on top of it (occupancy() cannot count implicit cells).
    column.groups.push({ title: "", tiles: [{ id: nextTileId(next), app: appId,
                                             size: tileSize, col: 0, row: 0 }] })
    return next
}
