// Tests for Edit.prepare() legacy-layout migration.
//
// Run with:
//   node tests/edit-prepare-legacy.test.js
//
// The QML JS files are loaded verbatim except for `.pragma` / `.import`
// directives (QML-only syntax), into a VM context providing the two QML globals
// the library files use: `console` (via Node's sandbox) and the imported
// namespaces wired up by this harness. No source logic is stubbed out.
'use strict';

const assert = require('node:assert');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const UI = path.join(__dirname, '..', 'package', 'contents', 'ui');

function loadLibrary(fileName, context) {
    const source = fs.readFileSync(path.join(UI, fileName), 'utf8')
        .replace(/^\s*\.(?:pragma|import)\b.*$/gm, '');
    vm.runInNewContext(source, context, { filename: fileName });
    return context;
}

const metrics = loadLibrary('metrics.js', { console });
const layout = loadLibrary('Layout.js', { console, Metrics: metrics });
const edit = loadLibrary('Edit.js', { console, Metrics: metrics, Layout: layout });
const { prepare, forStorage, normalizeGroup } = edit;

// ---------------------------------------------------------------------------
// Minimal test runner (no dependencies)

const tests = [];
function test(name, fn) {
    tests.push({ name, fn });
}

function columnsOf(config) {
    return layout.configColumns(config).map(groups =>
        groups.map(group => group.title || ''));
}

// Group titles in prepare()'s result, by column.
function preparedColumns(config) {
    return config.columns.map(column => column.groups.map(group => group.title || ''));
}

// ---------------------------------------------------------------------------
// Legacy grouping semantics

test('legacy groups with x are grouped by position', () => {
    const input = { groups: [
        { x: 1, title: 'right', tiles: [] },
        { x: 0, title: 'left', tiles: [] }
    ] };
    assert.deepEqual(preparedColumns(prepare(input)), [['left'], ['right']]);
});

test('legacy groups with column are grouped by column index', () => {
    const input = { groups: [
        { column: 2, title: 'third', tiles: [] },
        { column: 0, title: 'first', tiles: [] },
        { column: 1, title: 'second', tiles: [] }
    ] };
    assert.deepEqual(preparedColumns(prepare(input)), [['first'], ['second'], ['third']]);
});

test('groups with no position field land in column 0', () => {
    const input = { groups: [
        { title: 'no position', tiles: [] },
        { title: 'also none', tiles: [] },
        { column: 0, title: 'explicit zero', tiles: [] }
    ] };
    assert.deepEqual(preparedColumns(prepare(input)),
                     [['no position', 'also none', 'explicit zero']]);
});

test('multiple columns sort keys numerically with parseFloat', () => {
    const input = { groups: [
        { x: 10, title: 'ten', tiles: [] },
        { x: 2, title: 'two', tiles: [] },
        { x: 1, title: 'one', tiles: [] }
    ] };
    assert.deepEqual(preparedColumns(prepare(input)), [['one'], ['two'], ['ten']]);
    // String keys with decimals too: parseFloat governs the order, not string order.
    const stringKeys = { groups: [
        { x: '10', title: 'ten', tiles: [] },
        { x: '2.5', title: 'two point five', tiles: [] },
        { x: '2', title: 'two', tiles: [] }
    ] };
    assert.deepEqual(preparedColumns(prepare(stringKeys)),
                     [['two'], ['two point five'], ['ten']]);
});

test('mixed column and x fields share the same keys', () => {
    const input = { groups: [
        { x: 1, title: 'x one', tiles: [] },
        { column: 0, title: 'column zero', tiles: [] },
        { column: 1, title: 'column one', tiles: [] },
        { x: 0, title: 'x zero', tiles: [] }
    ] };
    assert.deepEqual(preparedColumns(prepare(input)),
                     [['column zero', 'x zero'], ['x one', 'column one']]);
});

test('column takes precedence over x when both are present', () => {
    const input = { groups: [{ column: 0, x: 9, title: 'both', tiles: [] }] };
    assert.deepEqual(preparedColumns(prepare(input)), [['both']]);
});

test('empty configurations produce an empty columns array', () => {
    assert.deepEqual(prepare(null), { columns: [] });
    assert.deepEqual(prepare(undefined), { columns: [] });
    assert.deepEqual(prepare({}), { columns: [] });
    assert.deepEqual(prepare({ groups: [] }), { columns: [] });
    assert.deepEqual(prepare({ columns: [] }), { columns: [] });
    assert.deepEqual(prepare({ columns: null }), { columns: [] });
});

test('current-format configurations are preserved', () => {
    const input = { version: 2, columns: [
        { groups: [{ title: 'A', tiles: [{ app: 'a', size: '2x2', col: 0, row: 0 }] }] },
        { groups: [{ title: 'B', tiles: [] }, { title: 'C', tiles: [] }] }
    ] };
    const result = prepare(input);
    assert.deepEqual(preparedColumns(result), [['A'], ['B', 'C']]);
    assert.equal(result.version, 2);
    assert.equal(result.columns[0].id, 'c0');
    assert.equal(result.columns[1].id, 'c1');
});

test('current-format columns without groups get an empty groups array and ids', () => {
    const result = prepare({ columns: [{}, {}] });
    assert.deepEqual(result.columns.map(c => c.groups), [[], []]);
    assert.deepEqual(result.columns.map(c => c.id), ['c0', 'c1']);
});

test('tile sizes, positions, group titles and optional metadata are preserved', () => {
    const input = { version: 7, groups: [
        { x: 0, title: 'Tools', custom: 'group-meta', tiles: [
            { app: 'org.kde.dolphin.desktop', size: '4x2', col: 0, row: 0,
              style: 3, color: '#123456', fgColor: '#ffffff', iconTint: 'red',
              live: { type: 'clock' }, iconRect: [0, 0, 16, 16], custom: 'tile-meta' },
            { label: 'KiCad', icon: '/path/kicad.png', exec: 'kicad', size: '1x1',
              col: 2, row: 3 }
        ] },
        { column: 1, title: '', tiles: [{ app: 'b', size: '4x4', col: 0, row: 2 }] }
    ] };
    const result = prepare(input);
    const group = result.columns[0].groups[0];
    // prepare() rebuilds legacy configs as { columns: [...] }, as it did for
    // { columns: [] } before migration; top-level metadata is not carried over.
    assert.equal(result.version, undefined);
    assert.equal(group.title, 'Tools');
    assert.equal(group.custom, 'group-meta');
    assert.equal(group.tiles[0].size, '4x2');
    assert.equal(group.tiles[0].col, 0);
    assert.equal(group.tiles[0].row, 0);
    assert.equal(group.tiles[0].style, 3);
    assert.equal(group.tiles[0].color, '#123456');
    assert.equal(group.tiles[0].fgColor, '#ffffff');
    assert.equal(group.tiles[0].iconTint, 'red');
    assert.deepEqual(group.tiles[0].live, { type: 'clock' });
    assert.deepEqual(group.tiles[0].iconRect, [0, 0, 16, 16]);
    assert.equal(group.tiles[0].custom, 'tile-meta');
    assert.equal(group.tiles[1].label, 'KiCad');
    assert.equal(group.tiles[1].icon, '/path/kicad.png');
    assert.equal(group.tiles[1].exec, 'kicad');
    assert.equal(group.tiles[1].size, '1x1');
    assert.equal(group.tiles[1].col, 2);
    // normalizeGroup() removes the empty row between the two tiles.
    assert.equal(group.tiles[1].row, 2);
    // Single tile at row 2: normalizeGroup() shifts it to row 0.
    assert.deepEqual(result.columns[1].groups[0].tiles[0],
                     { app: 'b', size: '4x4', col: 0, row: 0, id: 't2' });
    assert.equal(result.columns[0].groups[0].tiles[0].id, 't0');
    assert.equal(result.columns[0].groups[0].tiles[1].id, 't1');
});

test('existing ids are preserved; missing ids are assigned in column/group/tile order', () => {
    const input = { groups: [
        { x: 0, id: 'keep-group', tiles: [{ id: 'keep-tile', app: 'a' }, { app: 'b' }] },
        { x: 1, tiles: [{ app: 'c' }] }
    ] };
    const result = prepare(input);
    assert.equal(result.columns[0].id, 'c0');
    assert.equal(result.columns[0].groups[0].id, 'keep-group');
    assert.equal(result.columns[0].groups[0].tiles[0].id, 'keep-tile');
    assert.equal(result.columns[0].groups[0].tiles[1].id, 't0');
    assert.equal(result.columns[1].groups[0].id, 'g0');
    assert.equal(result.columns[1].groups[0].tiles[0].id, 't1');
});

test('normalizeGroup is applied to migrated groups (empty rows removed)', () => {
    // A 1x1 tile sits in row 3; the empty rows 0-2 must be collapsed so this
    // group has the same shape as one written in the current format.
    const input = { groups: [{ x: 0, tiles: [
        { app: 'a', size: '1x1', col: 0, row: 0 },
        { app: 'b', size: '1x1', col: 0, row: 3 }
    ] }] };
    const result = prepare(input);
    assert.deepEqual(result.columns[0].groups[0].tiles.map(t => t.row), [0, 1]);
});

test('input configuration is not mutated', () => {
    const input = { version: 2, groups: [
        { x: 1, id: 'given', tiles: [{ app: 'a', size: '2x2', col: 0, row: 0 }] },
        { x: 0, tiles: [{ app: 'b', size: '2x2', col: 0, row: 0 }] }
    ] };
    const before = JSON.stringify(input);
    const result = prepare(input);
    assert.equal(JSON.stringify(input), before);
    result.columns[0].id = 'changed';
    result.columns[1].groups[0].tiles[0].app = 'changed';
    assert.equal(JSON.stringify(input), before);
});

test('current-format input is also not mutated', () => {
    const input = { columns: [{ groups: [{ title: 'A', tiles: [{ app: 'a', size: '2x2' }] }] }] };
    const before = JSON.stringify(input);
    const result = prepare(input);
    assert.equal(JSON.stringify(input), before);
    result.columns[0].groups[0].tiles[0].app = 'changed';
    assert.equal(JSON.stringify(input), before);
});

test('prepare() -> forStorage() -> prepare() round trip keeps the legacy layout', () => {
    const input = { groups: [
        { x: 1, title: 'right', tiles: [{ app: 'r', size: '4x2', col: 0, row: 0 }] },
        { column: 0, title: 'left', tiles: [
            { app: 'a', size: '2x2', col: 0, row: 0 },
            { app: 'b', size: '1x1', col: 2, row: 2 }
        ] },
        { title: 'default column', tiles: [] }
    ] };
    const first = prepare(input);
    const stored = forStorage(first);
    // Ids are stripped; the migrated columns format is what gets written back.
    assert.equal(JSON.stringify(stored).includes('"id"'), false);
    const second = prepare(stored);
    assert.deepEqual(second, first);
    assert.deepEqual(columnsOf(stored), preparedColumns(first));
});

test('round trip of a current-format layout is stable', () => {
    const input = { version: 2, columns: [
        { groups: [{ title: 'A', tiles: [{ app: 'a', size: '2x2', col: 0, row: 0 }] }] },
        { groups: [] }
    ] };
    const first = prepare(input);
    assert.deepEqual(prepare(forStorage(first)), first);
});

test('migrated layout produces the same grouping as Layout.configColumns()', () => {
    const inputs = [
        { groups: [{ x: 3, title: 'c' }, { x: 1, title: 'a' }, { x: 2, title: 'b' }] },
        { groups: [{ column: 0, title: 'a' }, { x: 5, title: 'b' }, { title: 'z' }] },
        { groups: [{ x: '10', title: 'ten' }, { x: '2', title: 'two' }] },
        { columns: [{ groups: [{ title: 'new' }] }, { groups: [{ title: 'other' }] }] },
        {}, null
    ];
    for (const input of inputs) {
        const expected = columnsOf(input);
        const actual = preparedColumns(prepare(input));
        assert.deepEqual(actual, expected, `grouping mismatch for ${JSON.stringify(input)}`);
    }
});

// ---------------------------------------------------------------------------

let failed = 0;
for (const { name, fn } of tests) {
    try {
        fn();
        console.log(`PASS  ${name}`);
    } catch (error) {
        failed += 1;
        console.log(`FAIL  ${name}\n${error.stack}`);
    }
}
console.log(`\n${tests.length - failed}/${tests.length} passed`);
process.exitCode = failed === 0 ? 0 : 1;
