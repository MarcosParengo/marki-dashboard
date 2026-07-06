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

    // Player a mostrar en el indicador (el fijado, o el primero real)
    readonly property string displayPlayer: selectedPlayer.length ? selectedPlayer
                                          : (players.length ? players[0] : playerName)
    // Duración válida (evita basura de streams en vivo)
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
    function appName(p) {
        const base = (p || "").split(".")[0];
        if (base === "plasma-browser-integration") return "Navegador";
        if (!base.length) return "";
        return base.charAt(0).toUpperCase() + base.slice(1);
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
    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing
        visible: root.hasPlayer

        // Fila superior: app + tabs de players
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: root.displayPlayer.split(".")[0]
                fallback: "audio-x-generic"
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }
            PC3.Label {
                text: root.appName(root.displayPlayer)
                font.weight: Font.DemiBold
                opacity: 0.8
                elide: Text.ElideRight
            }

            Item { Layout.fillWidth: true }

            // Selector de players (si hay más de uno)
            Repeater {
                model: root.players.length > 1 ? root.players : []
                delegate: Rectangle {
                    id: tab
                    required property string modelData
                    readonly property bool current: root.selectedPlayer === modelData
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 1.8
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.8
                    radius: Kirigami.Units.cornerRadius * 1.6
                    color: tab.current ? Qt.rgba(Kirigami.Theme.textColor.r,
                                                 Kirigami.Theme.textColor.g,
                                                 Kirigami.Theme.textColor.b, 0.15)
                                       : "transparent"
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: Kirigami.Units.iconSizes.small
                        height: width
                        source: tab.modelData.split(".")[0]
                        fallback: "audio-x-generic"
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedPlayer = (tab.current ? "" : tab.modelData)
                    }
                }
            }
        }

        // Fila principal
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.largeSpacing

            // Thumbnail (izquierda)
            Item {
                id: coverItem
                Layout.alignment: Qt.AlignVCenter
                Layout.fillHeight: true
                Layout.maximumHeight: Kirigami.Units.gridUnit * 9
                Layout.preferredWidth: height
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
            }

            // Centro: info + letras + controles + timeline + volumen
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Kirigami.Units.smallSpacing

                C.Marquee {
                    Layout.fillWidth: true
                    text: root.title
                    pixelSize: Kirigami.Units.gridUnit * 1.3
                }
                PC3.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: root.artist
                    opacity: 0.8
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                // Letras sincronizadas
                C.Lyrics {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    title: root.title
                    artist: root.artist
                    album: root.album
                    duration: root.length
                    position: root.position
                }

                // Controles: shuffle | prev | play | next | repeat
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Kirigami.Units.smallSpacing

                    PC3.ToolButton {
                        icon.name: "media-playlist-shuffle"
                        opacity: root.shuffle ? 1 : 0.4
                        onClicked: root.run("shuffle toggle")
                    }
                    PC3.ToolButton {
                        icon.name: "media-skip-backward"
                        onClicked: root.run("previous")
                    }
                    PC3.Button {
                        icon.name: root.playing ? "media-playback-pause" : "media-playback-start"
                        onClicked: root.run("play-pause")
                    }
                    PC3.ToolButton {
                        icon.name: "media-skip-forward"
                        onClicked: root.run("next")
                    }
                    PC3.ToolButton {
                        icon.name: root.loop === "Track" ? "media-playlist-repeat-song"
                                                          : "media-playlist-repeat"
                        opacity: root.loop === "None" ? 0.4 : 1
                        onClicked: root.cycleLoop()
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

            // Gif (derecha)
            AnimatedImage {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillHeight: true
                Layout.maximumHeight: Kirigami.Units.gridUnit * 8
                Layout.preferredWidth: height
                source: Qt.resolvedUrl("../assets/blackcat.gif")
                fillMode: Image.PreserveAspectFit
                playing: true
            }
        }
    }
}
