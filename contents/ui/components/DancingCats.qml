import QtQuick
import Qt.labs.folderlistmodel

// Gatos bailando en posiciones/tamaños random; se regeneran al cambiar `trigger`.
Item {
    id: root

    property string trigger: ""     // p. ej. el título; cambia -> re-randomiza
    property string mode: "party"   // "party" | "big" | "none"
    property int minCats: 28
    property int maxCats: 45

    property var placements: []

    onModeChanged: regenerate()

    FolderListModel {
        id: fm
        folder: Qt.resolvedUrl("../assets/cats")
        nameFilters: ["*.gif"]
        showDirs: false
        onCountChanged: root.regenerate()
    }

    function regenerate() {
        const n = fm.count;
        if (n <= 0 || width <= 0 || height <= 0) { placements = []; return; }

        if (mode === "none") {
            placements = [];
            return;
        }

        if (mode === "big") {
            const name = fm.get(Math.floor(Math.random() * n), "fileName");
            const size = Math.min(width, height) * 0.8;
            placements = [{
                src: "../assets/cats/" + name,
                x: (width - size) / 2,
                y: (height - size) / 2,
                size: size,
                mirror: false
            }];
            return;
        }

        // party
        const k = root.minCats + Math.floor(Math.random() * (root.maxCats - root.minCats + 1));
        const arr = [];
        for (let i = 0; i < k; i++) {
            const name = fm.get(Math.floor(Math.random() * n), "fileName");
            const size = (0.16 + Math.random() * 0.24) * Math.min(width, height);
            arr.push({
                src: "../assets/cats/" + name,
                x: Math.random() * width - size * 0.35,
                y: Math.random() * height - size * 0.35,
                size: size,
                mirror: Math.random() < 0.5
            });
        }
        placements = arr;
    }

    onTriggerChanged: regenerate()
    onWidthChanged: if (!placements.length) regenerate()
    onHeightChanged: if (!placements.length) regenerate()

    Repeater {
        model: root.placements
        delegate: AnimatedImage {
            required property var modelData
            source: Qt.resolvedUrl(modelData.src)
            x: modelData.x
            y: modelData.y
            width: modelData.size
            height: modelData.size
            fillMode: Image.PreserveAspectFit
            mirror: modelData.mirror
            playing: true
            asynchronous: true
        }
    }
}
