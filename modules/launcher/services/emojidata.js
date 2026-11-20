.pragma library

// The emoji list (~12k entries) lives here, outside the QML property system.
// Holding it in a `property var` makes every element access convert the object,
// which cost ~800 ms per pass on the main thread. Only the (small) results are
// handed back to QML.

let items = [];

// Display order: Unicode emojis, then Unicode symbols, then Nerd Font icons
// (the data file is ~84% Nerd Font glyphs, which are not emojis).
const GROUP_EMOJI = 0;
const GROUP_SYMBOL = 1;
const GROUP_NERD = 2;

// Emoji_Presentation code points below U+1F000 (the rest are emojis by range or by U+FE0F/U+20E3)
const lowEmoji = /[\u231A\u231B\u23E9-\u23EC\u23F0\u23F3\u25FD\u25FE\u2614\u2615\u2648-\u2653\u267F\u2693\u26A1\u26AA\u26AB\u26BD\u26BE\u26C4\u26C5\u26CE\u26D4\u26EA\u26F2\u26F3\u26F5\u26FA\u26FD\u2705\u270A\u270B\u2728\u274C\u274E\u2753-\u2755\u2757\u2795-\u2797\u27B0\u27BF\u2B1B\u2B1C\u2B50\u2B55\uFE0F\u20E3]/;
const astral = /[\u{1F000}-\u{1FFFF}]/u;
const privateUse = /[\uE000-\uF8FF]|[\u{F0000}-\u{10FFFF}]/u;

// A lone regional indicator (A-Z) has no glyph in the emoji font and renders as an empty
// box; only pairs of them (flags) are real emojis.
const loneRegional = /^[\u{1F1E6}-\u{1F1FF}]$/u;

function groupOf(char, name) {
    if (name.startsWith("nf-") || privateUse.test(char))
        return GROUP_NERD;
    // Kaomoji such as (ง🔥ﾛ🔥)ง are text art, not emojis, even when they contain one
    if (loneRegional.test(char) || /[()\\_\/]/.test(char))
        return GROUP_SYMBOL;
    if (lowEmoji.test(char) || astral.test(char))
        return GROUP_EMOJI;
    return GROUP_SYMBOL;
}

function load(text) {
    const lines = text.split("\n");
    const result = [];
    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        const space = line.indexOf(" ");
        if (space < 0)
            continue;
        const name = line.substring(space + 1).trim();
        result.push({
            char: line.substring(0, space),
            name: name,
            lower: name.toLowerCase(),
            group: 0
        });
        const item = result[result.length - 1];
        item.group = groupOf(item.char, name);
    }
    items = result;
    return result.length;
}

// Favourites first, then the ones used before (most used first), then the rest
// grouped emojis > symbols > Nerd Font icons, each in file order. Only the first
// `max` are needed, so the full list is never sorted.
function sorted(favourites, frequencies, max) {
    const favSet = new Set(favourites);
    // A Map, not `frequencies[char]`: looking up thousands of distinct strings as object
    // keys is extremely slow in QML's JS engine (~850 ms here), Map.get takes ~1 ms.
    const uses = new Map(Object.entries(frequencies));
    const favs = [];
    const used = [];
    const groups = [[], [], []];
    for (let i = 0; i < items.length; i++) {
        const item = items[i];
        if (favSet.has(item.char))
            favs.push(item);
        else if (uses.get(item.char))
            used.push(item);
        else if (groups[item.group].length < max)
            groups[item.group].push(item);
    }
    const byUse = (a, b) => (uses.get(b.char) || 0) - (uses.get(a.char) || 0);
    return favs.sort(byUse).concat(used.sort(byUse), groups[0], groups[1], groups[2]).slice(0, max);
}

// Matches grouped the same way (emojis first), in file order within each group.
function search(query, max) {
    const q = query.toLowerCase();
    const groups = [[], [], []];
    for (let i = 0; i < items.length && groups[0].length < max; i++) {
        const item = items[i];
        if (item.lower.includes(q) && groups[item.group].length < max)
            groups[item.group].push(item);
    }
    return groups[0].concat(groups[1], groups[2]).slice(0, max);
}
