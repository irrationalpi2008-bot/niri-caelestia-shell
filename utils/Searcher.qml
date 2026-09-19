import Quickshell
import Caelestia

import "scripts/fzf.js" as Fzf
import QtQuick

Singleton {
    required property list<QtObject> list
    property string key: "name"
    property bool useFuzzy: false
    property var extraOpts: ({})

    // Extra stuff for fuzzy
    property list<string> keys: [key]
    property list<real> weights: [1]

    readonly property var fzf: useFuzzy ? [] : new Fzf.Finder(list, Object.assign({
        selector
    }, extraOpts))

    function transformSearch(search: string): string {
        return search;
    }

    function selector(item: var): string {
        // Only for fzf
        return item[key];
    }

    function query(search: string): list<var> {
        search = transformSearch(search);
        if (!search)
            return [...list];

        if (useFuzzy)
            return CUtils.fuzzySearch(search, list, keys, weights);

        return fzf.find(search).sort((a, b) => {
            if (a.score === b.score)
                return selector(a.item).trim().length - selector(b.item).trim().length;
            return b.score - a.score;
        }).map(r => r.item);
    }
}
