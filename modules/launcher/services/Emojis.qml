pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import "emojidata.js" as EmojiData

QtObject {
    id: root

    // The full list (~12k entries) is kept in emojidata.js; the panel only renders a
    // window of it, so cap what is handed to the list model (it diffs every value).
    readonly property int maxResults: 2000

    // Number of loaded emojis; bindings read it so they re-run once the list is in.
    property int count: 0
    property var frequencies: ({})
    property bool _loaded: false

    property Process reader: Process {
        running: false
        command: ["cat", "/usr/lib/python3.14/site-packages/caelestia/data/emojis.txt"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.count = EmojiData.load(text);
                root._loaded = true;
            }
        }
    }

    property Process freqReader: Process {
        running: false
        command: ["test", "-f", Paths.config + "emoji-frequencies.json", "&&", "cat", Paths.config + "emoji-frequencies.json", "||", "echo", "{}"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.frequencies = JSON.parse(text) || {};
                } catch (e) {
                    root.frequencies = {};
                }
            }
        }
    }

    property Process freqWriter: Process {
        running: false
    }

    function reload(): void {
        if (_loaded)
            return;
        reader.running = true;
        loadFrequencies();
    }

    function loadFrequencies(): void {
        freqReader.running = true;
    }

    function saveFrequencies(): void {
        freqWriter.arguments = ["-echo", JSON.stringify(frequencies), ">", Paths.config + "emoji-frequencies.json"];
        freqWriter.running = true;
    }

    function recordUsage(char: string): void {
        frequencies[char] = (frequencies[char] || 0) + 1;
        saveFrequencies();
    }

    function getSortedItems(): var {
        if (count === 0)
            return [];
        return EmojiData.sorted(GlobalConfig.launcher.favouriteEmojis || [], frequencies, maxResults);
    }

    function search(query: string): var {
        if (count === 0)
            return [];
        return EmojiData.search(query, maxResults);
    }
}
