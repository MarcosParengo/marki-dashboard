import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import "../components" as C

Item {
    id: root

    property string status: "Stopped"
    property string title: ""
    property string artist: ""
    property string album: ""
    property string artUrl: ""
    property string playerName: ""
    property real length: 0
    property real position: 0

    property var players: []
    property string selectedPlayer: ""
    readonly property string targetPlayer: selectedPlayer.length ? selectedPlayer : "playerctld"

    property bool shuffle: false
    property string loop: "None"
    property real volume: 0

    property string catMode: "big"   // "big" | "party" | "none"

    readonly property bool hasDuration: length > 0 && length < 86400
    readonly property bool playing: status === "Playing"
    readonly property bool hasPlayer: title.length > 0 || artist.length > 0

    property string sep: "␄"

    function fmtTime(sec) {
        if (!(sec > 0)) return "0:00";
        const s = Math.floor(sec) % 60;
        const m = Math.floor(sec / 60);
        return m + ":" + (s < 10 ? "0" + s : s);
    }

    onPlayersChanged: {
        if (selectedPlayer.length && players.indexOf(selectedPlayer) === -1)
            selectedPlayer = "";
    }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            const out = (data["stdout"] || "");
            const s = source;
            if (s.indexOf(" -l") !== -1) {
                const list = out.trim();
                root.players = list.length ? list.split("\n") : [];
            } else if (s.endsWith("position")) {
                const pos = parseFloat(out.trim());
                if (!isNaN(pos)) root.position = pos;
            } else if (s.endsWith("shuffle")) {
                root.shuffle = out.trim() === "On";
            } else if (s.endsWith("loop")) {
                const l = out.trim();
                if (l.length) root.loop = l;
            } else if (s.endsWith("volume")) {
                const v = parseFloat(out.trim());
                if (!isNaN(v)) root.volume = v;
            } else if (s.indexOf("metadata") !== -1) {
                const meta = out.replace(/\n$/, "");
                if (data["exit code"] !== 0 || meta.length === 0) {
                    root.title = ""; root.artist = ""; root.status = "Stopped"; root.length = 0;
                } else {
                    const p = meta.split(root.sep);
                    root.status = p[0] || "Stopped";
                    root.title = p[1] || "";
                    root.artist = p[2] || "";
                    root.album = p[3] || "";
                    root.artUrl = p[4] || "";
                    const len = parseFloat(p[5]);
                    root.length = isNaN(len) ? 0 : len / 1e6;
                    root.playerName = p[6] || "";
                }
            }
            exec.disconnectSource(source);
        }
    }

    function pctl(sub) { return "playerctl -p " + targetPlayer + " " + sub; }
    function run(cmd) { exec.connectSource(pctl(cmd)); }
    function poll() {
        exec.connectSource(pctl("metadata --format '{{status}}" + sep +
                           "{{title}}" + sep + "{{artist}}" + sep +
                           "{{album}}" + sep + "{{mpris:artUrl}}" + sep +
                           "{{mpris:length}}" + sep + "{{playerName}}'"));
    }
    function pollPosition() { exec.connectSource(pctl("position")); }
    function pollState() {
        exec.connectSource(pctl("shuffle"));
        exec.connectSource(pctl("loop"));
        exec.connectSource(pctl("volume"));
    }
    function pollPlayers() { exec.connectSource("playerctl -l"); }
    function cycleLoop() {
        const next = loop === "None" ? "Track" : (loop === "Track" ? "Playlist" : "None");
        run("loop " + next);
        loop = next;
    }

    Component.onCompleted: { pollPlayers(); poll(); pollState(); }
    Timer {
        interval: 1000; running: true; repeat: true
        property int tick: 0
        onTriggered: {
            root.poll();
            root.pollPosition();
            if (tick % 2 === 0) root.pollState();
            if (tick % 3 === 0) root.pollPlayers();
            tick++;
        }
    }

    // ---- Fondo: gatos bailando random (cambian por tema) ----
    C.DancingCats {
        anchors.fill: parent
        visible: root.hasPlayer
        opacity: 0.55
        trigger: root.title
        mode: root.catMode
    }

    // ---- Sin reproductor ----
    ColumnLayout {
        anchors.centerIn: parent
        visible: !root.hasPlayer
        spacing: Kirigami.Units.largeSpacing
        Kirigami.Icon {
            Layout.alignment: Qt.AlignHCenter
            source: "media-playback-stopped"
            Layout.preferredWidth: Kirigami.Units.iconSizes.huge
            Layout.preferredHeight: Kirigami.Units.iconSizes.huge
            opacity: 0.5
        }
        PC3.Label {
            Layout.alignment: Qt.AlignHCenter
            text: i18n("No hay nada reproduciéndose")
            opacity: 0.7
        }
    }

    // ---- Reproductor ----
    RowLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing
        visible: root.hasPlayer

        // ===== Columna izquierda: tabs · thumbnail · controles · timeline · volumen =====
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: false
            Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            Layout.minimumWidth: Kirigami.Units.gridUnit * 12
            Layout.maximumWidth: Kirigami.Units.gridUnit * 12
            Layout.topMargin: Kirigami.Units.largeSpacing
            Layout.bottomMargin: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            // Thumbnail (cuadrado, se expande en vertical) con controles superpuestos
            Item {
                id: coverItem
                Layout.fillHeight: true
                Layout.preferredWidth: height
                Layout.maximumWidth: parent.width
                Layout.alignment: Qt.AlignHCenter
                readonly property real coverRadius: Kirigami.Units.cornerRadius * 2

                Rectangle {
                    anchors.fill: parent
                    radius: coverItem.coverRadius
                    visible: cover.status !== Image.Ready
                    color: Qt.rgba(Kirigami.Theme.textColor.r,
                                   Kirigami.Theme.textColor.g,
                                   Kirigami.Theme.textColor.b, 0.08)
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        source: "audio-x-generic"
                        width: Kirigami.Units.iconSizes.large
                        height: width
                        opacity: 0.5
                    }
                }
                Image {
                    id: cover
                    anchors.fill: parent
                    source: root.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                }
                Rectangle {
                    id: coverMask
                    anchors.fill: parent
                    radius: coverItem.coverRadius
                    visible: false
                }
                OpacityMask {
                    anchors.fill: parent
                    source: cover
                    maskSource: coverMask
                    visible: cover.status === Image.Ready
                }

                // Barra de controles flotante sobre la carátula
                Rectangle {
                    id: ctrlBar
                    readonly property real pad: Kirigami.Units.smallSpacing
                    readonly property real btnRadius: Kirigami.Units.cornerRadius * 2

                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: Kirigami.Units.largeSpacing * 1.5
                    // outer r = inner r + padding
                    radius: btnRadius + pad
                    implicitWidth: ctrlRow.implicitWidth + pad * 2
                    implicitHeight: ctrlRow.implicitHeight + pad * 2
                    color: Qt.rgba(Kirigami.Theme.backgroundColor.r,
                                   Kirigami.Theme.backgroundColor.g,
                                   Kirigami.Theme.backgroundColor.b, 0.7)

                    RowLayout {
                        id: ctrlRow
                        anchors.centerIn: parent
                        spacing: 0

                        component Ctrl: PC3.ToolButton {
                            id: ctrlBtn
                            implicitWidth: Kirigami.Units.gridUnit * 1.6
                            implicitHeight: Kirigami.Units.gridUnit * 1.6
                            icon.width: Kirigami.Units.iconSizes.small
                            icon.height: Kirigami.Units.iconSizes.small
                            background: Rectangle {
                                radius: ctrlBar.btnRadius
                                color: ctrlBtn.pressed ? Qt.rgba(Kirigami.Theme.textColor.r,
                                                                 Kirigami.Theme.textColor.g,
                                                                 Kirigami.Theme.textColor.b, 0.2)
                                     : ctrlBtn.hovered ? Qt.rgba(Kirigami.Theme.textColor.r,
                                                                 Kirigami.Theme.textColor.g,
                                                                 Kirigami.Theme.textColor.b, 0.1)
                                     : "transparent"
                            }
                        }

                        Ctrl {
                            icon.name: "media-playlist-shuffle"
                            opacity: root.shuffle ? 1 : 0.4
                            onClicked: root.run("shuffle toggle")
                        }
                        Ctrl {
                            icon.name: "media-skip-backward"
                            onClicked: root.run("previous")
                        }
                        Ctrl {
                            icon.name: root.playing ? "media-playback-pause" : "media-playback-start"
                            onClicked: root.run("play-pause")
                        }
                        Ctrl {
                            icon.name: "media-skip-forward"
                            onClicked: root.run("next")
                        }
                        Ctrl {
                            icon.name: root.loop === "Track" ? "media-playlist-repeat-song"
                                                              : "media-playlist-repeat"
                            opacity: root.loop === "None" ? 0.4 : 1
                            onClicked: root.cycleLoop()
                        }
                    }
                }
            }

            // Timeline
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                visible: root.hasDuration

                PC3.Label {
                    text: root.fmtTime(root.position)
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    font.features: { "tnum": 1 }
                    opacity: 0.8
                }
                C.SeekBar {
                    Layout.fillWidth: true
                    value: root.length > 0 ? root.position / root.length : 0
                    onSeek: frac => { if (root.length > 0) root.run("position " + (frac * root.length)); }
                }
                PC3.Label {
                    text: "-" + root.fmtTime(Math.max(0, root.length - root.position))
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    font.features: { "tnum": 1 }
                    opacity: 0.8
                }
            }

            // Volumen
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: root.volume <= 0 ? "audio-volume-muted" : "audio-volume-high"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    opacity: 0.8
                }
                C.SeekBar {
                    Layout.fillWidth: true
                    value: root.volume
                    onSeek: frac => root.run("volume " + frac.toFixed(2))
                }
            }
        }

        // ===== Columna derecha: título · artista · álbum · letra =====
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: Kirigami.Units.largeSpacing * 1.5
            Layout.bottomMargin: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            C.Marquee {
                Layout.fillWidth: true
                text: root.title
                pixelSize: Kirigami.Units.gridUnit * 1.2
            }
            // Artista · Álbum en la misma línea
            PC3.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: root.artist + (root.album.length > 0 ? "  ·  " + root.album : "")
                opacity: 0.75
                font.weight: Font.Medium
                elide: Text.ElideRight
                visible: root.artist.length > 0 || root.album.length > 0
            }

            C.Lyrics {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                title: root.title
                artist: root.artist
                album: root.album
                duration: root.length
                position: root.position
            }
        }
    }

    // Capa para cerrar el menú al clickear afuera
    MouseArea {
        anchors.fill: parent
        z: 50
        visible: dropdown.visible
        onClicked: dropdown.visible = false
    }

    // Menú hamburguesa (selector de player) arriba a la derecha
    PC3.ToolButton {
        id: menuBtn
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Kirigami.Units.smallSpacing
        z: 60
        visible: root.hasPlayer && root.players.length > 0
        icon.name: "application-menu"
        onClicked: dropdown.visible = !dropdown.visible
    }

    Rectangle {
        id: dropdown
        visible: false
        z: 60
        anchors.top: menuBtn.bottom
        anchors.right: parent.right
        anchors.rightMargin: Kirigami.Units.smallSpacing
        anchors.topMargin: Kirigami.Units.smallSpacing / 2
        width: Math.max(col.implicitWidth, Kirigami.Units.gridUnit * 9)
        height: col.implicitHeight + Kirigami.Units.smallSpacing * 2
        radius: Kirigami.Units.cornerRadius * 2
        color: Kirigami.Theme.backgroundColor
        border.width: 1
        border.color: Qt.rgba(Kirigami.Theme.textColor.r,
                              Kirigami.Theme.textColor.g,
                              Kirigami.Theme.textColor.b, 0.15)

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: 0

            MenuRow {
                Layout.fillWidth: true
                label: i18n("Automático (activo)")
                on: root.selectedPlayer === ""
                onClicked: { root.selectedPlayer = ""; dropdown.visible = false; }
            }
            Repeater {
                model: root.players
                delegate: MenuRow {
                    required property int index
                    Layout.fillWidth: true
                    label: {
                        const p = root.players[index] || "";
                        const b = p.split(".")[0];
                        if (b === "plasma-browser-integration") return "Navegador";
                        return b.length ? b.charAt(0).toUpperCase() + b.slice(1) : p;
                    }
                    on: root.selectedPlayer === (root.players[index] || "")
                    onClicked: { root.selectedPlayer = root.players[index] || ""; dropdown.visible = false; }
                }
            }

            // Separador
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing / 2
                Layout.bottomMargin: Kirigami.Units.smallSpacing / 2
                implicitHeight: 1
                color: Qt.rgba(Kirigami.Theme.textColor.r,
                               Kirigami.Theme.textColor.g,
                               Kirigami.Theme.textColor.b, 0.12)
            }

            // Modos de gato
            MenuRow {
                Layout.fillWidth: true
                label: i18n("1 big catto")
                on: root.catMode === "big"
                onClicked: { root.catMode = "big"; dropdown.visible = false; }
            }
            MenuRow {
                Layout.fillWidth: true
                label: i18n("catto party")
                on: root.catMode === "party"
                onClicked: { root.catMode = "party"; dropdown.visible = false; }
            }
            MenuRow {
                Layout.fillWidth: true
                label: i18n("no cattos (pussy)")
                on: root.catMode === "none"
                onClicked: { root.catMode = "none"; dropdown.visible = false; }
            }
        }
    }

    component MenuRow: Rectangle {
        id: rrow
        property string label: ""
        property bool on: false
        signal clicked()

        implicitWidth: rowLay.implicitWidth
        implicitHeight: Kirigami.Units.gridUnit * 1.9
        radius: Kirigami.Units.cornerRadius
        color: hov.hovered ? Qt.rgba(Kirigami.Theme.textColor.r,
                                     Kirigami.Theme.textColor.g,
                                     Kirigami.Theme.textColor.b, 0.1)
                           : "transparent"

        RowLayout {
            id: rowLay
            anchors.fill: parent
            anchors.leftMargin: Kirigami.Units.smallSpacing
            anchors.rightMargin: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: "checkmark"
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                opacity: rrow.on ? 1 : 0
            }
            PC3.Label {
                Layout.fillWidth: true
                text: rrow.label
                font.weight: rrow.on ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
            }
        }

        HoverHandler { id: hov }
        TapHandler { onTapped: rrow.clicked() }
    }
}
