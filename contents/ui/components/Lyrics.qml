import QtQuick
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

// Letras: sincronizadas (resaltan línea actual) o planas como fallback. Fuente: lrclib.net
Item {
    id: root

    property string title: ""
    property string artist: ""
    property string album: ""
    property real duration: 0
    property real position: 0

    property var lines: []          // sincronizadas: [{t, text}]
    property var plainLines: []     // planas: [string]
    property bool synced: false
    property bool loading: false
    property string _key: ""

    readonly property bool hasPlain: plainLines.length > 0

    readonly property int currentIndex: {
        if (!synced || !lines.length) return -1;
        let idx = -1;
        for (let i = 0; i < lines.length; i++) {
            if (lines[i].t <= position + 0.3) idx = i; else break;
        }
        return idx;
    }

    onTitleChanged: refetch()
    onArtistChanged: refetch()

    function esc(s) { return (s || "").replace(/'/g, ""); }

    function refetch() {
        const k = artist + "|" + title;
        if (k === _key || title.length === 0) return;
        _key = k;
        lines = [];
        plainLines = [];
        synced = false;
        loading = true;
        src.connectSource("curl -s --max-time 8 -G 'https://lrclib.net/api/get'" +
            " --data-urlencode 'artist_name=" + esc(artist) + "'" +
            " --data-urlencode 'track_name=" + esc(title) + "'" +
            " --data-urlencode 'duration=" + Math.round(duration) + "'");
    }

    function search() {
        src.connectSource("curl -s --max-time 8 -G 'https://lrclib.net/api/search'" +
            " --data-urlencode 'artist_name=" + esc(artist) + "'" +
            " --data-urlencode 'track_name=" + esc(title) + "'");
    }

    function parseLrc(lrc) {
        const arr = [];
        for (const row of lrc.split("\n")) {
            const times = [];
            const rx = /\[(\d+):(\d+(?:\.\d+)?)\]/g;
            let m;
            while ((m = rx.exec(row)) !== null)
                times.push(parseInt(m[1]) * 60 + parseFloat(m[2]));
            const text = row.replace(/\[[^\]]*\]/g, "").trim();
            for (const t of times) arr.push({ t: t, text: text });
        }
        arr.sort((a, b) => a.t - b.t);
        return arr;
    }

    function toPlain(txt) {
        return (txt || "").split("\n").map(l => l.trim());
    }

    function useSynced(lrc) {
        lines = parseLrc(lrc);
        synced = lines.length > 0;
    }

    P5Support.DataSource {
        id: src
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            src.disconnectSource(source);
            const out = data["stdout"] || "";
            const isSearch = source.indexOf("api/search") !== -1;
            let j = null;
            try { j = JSON.parse(out); } catch (e) { j = null; }

            if (isSearch) {
                root.loading = false;
                if (Array.isArray(j)) {
                    const s = j.find(r => r.syncedLyrics);
                    if (s) { root.useSynced(s.syncedLyrics); return; }
                    if (!root.hasPlain) {
                        const p = j.find(r => r.plainLyrics);
                        if (p) root.plainLines = root.toPlain(p.plainLyrics);
                    }
                }
                return;
            }

            // get
            if (j && j.syncedLyrics) {
                root.loading = false;
                root.useSynced(j.syncedLyrics);
            } else {
                if (j && j.plainLyrics)
                    root.plainLines = root.toPlain(j.plainLyrics); // fallback tentativo
                root.search(); // seguimos buscando sync
            }
        }
    }

    // Sincronizadas (auto-centrado animado vía highlightRange)
    ListView {
        id: syncedList
        anchors.fill: parent
        visible: root.synced
        clip: true
        interactive: false
        model: root.lines
        spacing: Kirigami.Units.smallSpacing

        currentIndex: root.currentIndex
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: height * 0.22
        preferredHighlightEnd: height * 0.36
        highlightMoveDuration: 450
        highlightMoveVelocity: -1
        highlight: Item {}

        delegate: PC3.Label {
            required property int index
            required property var modelData
            readonly property bool active: index === root.currentIndex
            width: ListView.view.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: modelData.text
            color: Kirigami.Theme.textColor
            opacity: active ? 1 : 0.3
            font.weight: active ? Font.DemiBold : Font.Normal
            font.pixelSize: active ? Kirigami.Theme.defaultFont.pixelSize * 1.4
                                   : Kirigami.Theme.defaultFont.pixelSize
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on font.pixelSize { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        }
    }

    // Planas (scrolleables, sin resaltado)
    ListView {
        anchors.fill: parent
        visible: !root.synced && root.hasPlain
        clip: true
        interactive: true
        model: root.plainLines
        spacing: Kirigami.Units.smallSpacing
        delegate: PC3.Label {
            required property var modelData
            width: ListView.view.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: modelData
            color: Kirigami.Theme.textColor
            opacity: 0.92
        }
    }

    PC3.Label {
        anchors.centerIn: parent
        visible: !root.synced && !root.hasPlain
        text: root.loading ? i18n("Buscando letra…") : i18n("Sin letra")
        opacity: 0.5
        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
    }
}
