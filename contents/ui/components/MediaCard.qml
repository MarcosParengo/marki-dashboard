import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

// Reproductor compacto (vertical) con selector de players, vía playerctl/MPRIS.
Item {
    id: root

    property string status: "Stopped"
    property string title: ""
    property string artist: ""
    property string album: ""
    property string artUrl: ""
    property real length: 0     // duración en segundos
    property real position: 0   // posición en segundos
    // Radio del thumbnail; se ata a la fórmula concéntrica desde afuera.
    property real coverRadius: Kirigami.Units.cornerRadius

    function fmtTime(sec) {
        if (!(sec > 0)) return "0:00";
        const s = Math.floor(sec) % 60;
        const m = Math.floor(sec / 60);
        return m + ":" + (s < 10 ? "0" + s : s);
    }

    property var players: []
    // "" => seguir al player activo (playerctld); si no, uno fijo.
    property string selectedPlayer: ""
    readonly property string targetPlayer: selectedPlayer.length ? selectedPlayer : "playerctld"

    readonly property bool playing: status === "Playing"
    readonly property bool hasPlayer: title.length > 0 || artist.length > 0

    property string sep: "␄"

    onPlayersChanged: {
        // si el player fijado ya no existe, volver a "activo"
        if (selectedPlayer.length && players.indexOf(selectedPlayer) === -1)
            selectedPlayer = "";
    }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            const out = (data["stdout"] || "");
            // Lista de players
            if (source.indexOf(" -l") !== -1) {
                const list = out.trim();
                root.players = list.length ? list.split("\n") : [];
                exec.disconnectSource(source);
                return;
            }
            // Posición (segundos)
            if (source.indexOf("position") !== -1) {
                const pos = parseFloat(out.trim());
                if (!isNaN(pos)) root.position = pos;
                exec.disconnectSource(source);
                return;
            }
            // Solo metadata actualiza el estado; los comandos no borran nada
            if (source.indexOf("metadata") === -1) {
                exec.disconnectSource(source);
                return;
            }
            const meta = out.replace(/\n$/, "");
            if (data["exit code"] !== 0 || meta.length === 0) {
                root.title = "";
                root.artist = "";
                root.status = "Stopped";
                root.length = 0;
            } else {
                const p = meta.split(root.sep);
                root.status = p[0] || "Stopped";
                root.title = p[1] || "";
                root.artist = p[2] || "";
                root.album = p[3] || "";
                root.artUrl = p[4] || "";
                const len = parseFloat(p[5]);
                root.length = isNaN(len) ? 0 : len / 1e6; // microseg -> seg
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
                           "{{mpris:length}}'"));
    }
    function pollPosition() { exec.connectSource(pctl("position")); }
    function pollPlayers() { exec.connectSource("playerctl -l"); }

    Component.onCompleted: { pollPlayers(); poll(); }
    Timer {
        interval: 1000; running: true; repeat: true
        property int tick: 0
        onTriggered: {
            root.poll();
            root.pollPosition();
            if (tick % 3 === 0) root.pollPlayers();
            tick++;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        // Selector de players (iconos de app), solo si hay más de uno
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: Kirigami.Units.smallSpacing
            visible: root.players.length > 1

            Repeater {
                model: root.players
                delegate: Rectangle {
                    id: tab
                    required property string modelData
                    readonly property bool current: root.selectedPlayer === modelData

                    Layout.preferredWidth: Kirigami.Units.gridUnit * 1.9
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.9
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
                        onClicked: root.selectedPlayer =
                            (tab.current ? "" : tab.modelData)
                    }
                }
            }
        }

        // Carátula (crece para llenar el alto disponible)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: width
            Layout.minimumHeight: width

            // Fondo/placeholder redondeado cuando no hay carátula
            Rectangle {
                anchors.fill: parent
                radius: root.coverRadius
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

            // Carátula recortada con esquinas redondeadas
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
                radius: root.coverRadius
                visible: false
            }
            OpacityMask {
                anchors.fill: parent
                source: cover
                maskSource: coverMask
                visible: cover.status === Image.Ready
            }
        }

        // Título con ticker infinito si no entra (centrado si entra)
        Marquee {
            Layout.fillWidth: true
            text: root.hasPlayer ? root.title : i18n("Nada sonando")
        }
        PC3.Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.artist
            opacity: 0.75
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            visible: root.artist.length > 0
        }

        // Timeline: posición · barra seekable · restante
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing
            visible: root.length > 0

            PC3.Label {
                text: root.fmtTime(root.position)
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                opacity: 0.8
            }
            Item {
                id: seek
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                implicitHeight: Kirigami.Units.gridUnit
                property real frac: 0
                property bool dragging: false

                Rectangle {
                    id: track
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: Kirigami.Units.smallSpacing + 2
                    radius: height / 2
                    color: Qt.rgba(Kirigami.Theme.textColor.r,
                                   Kirigami.Theme.textColor.g,
                                   Kirigami.Theme.textColor.b, 0.2)

                    // Progreso en negro (matchea las barras/tema)
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * Math.max(0, Math.min(1, seek.frac))
                        radius: parent.radius
                        color: Kirigami.Theme.textColor
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    function apply(mx) { seek.frac = Math.max(0, Math.min(1, mx / width)); }
                    onPressed: (m) => { seek.dragging = true; apply(m.x); }
                    onPositionChanged: (m) => { if (pressed) apply(m.x); }
                    onReleased: {
                        seek.dragging = false;
                        if (root.length > 0) root.run("position " + (seek.frac * root.length));
                    }
                }

                Connections {
                    target: root
                    function onPositionChanged() {
                        if (!seek.dragging)
                            seek.frac = root.length > 0 ? root.position / root.length : 0;
                    }
                }
            }
            PC3.Label {
                text: "-" + root.fmtTime(Math.max(0, root.length - root.position))
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                opacity: 0.8
            }
        }

        // Controles
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

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
        }
    }
}
