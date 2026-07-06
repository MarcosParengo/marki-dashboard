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
    readonly property bool playing: status === "Playing"
    readonly property bool hasPlayer: title.length > 0 || artist.length > 0

    property string sep: "␄" // separador improbable en metadatos

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            if (source.indexOf("metadata") !== -1) {
                const out = (data["stdout"] || "").replace(/\n$/, "");
                if (data["exit code"] !== 0 || out.length === 0) {
                    root.title = "";
                    root.artist = "";
                    root.status = "Stopped";
                } else {
                    const p = out.split(root.sep);
                    root.status = p[0] || "Stopped";
                    root.title = p[1] || "";
                    root.artist = p[2] || "";
                    root.album = p[3] || "";
                    root.artUrl = p[4] || "";
                }
            }
            exec.disconnectSource(source);
        }
    }

    // -p playerctld sigue siempre al reproductor activo
    readonly property string pctl: "playerctl -p playerctld "

    function run(cmd) { exec.connectSource(pctl + cmd); }
    function poll() {
        exec.connectSource(pctl + "metadata --format '{{status}}" + sep +
                           "{{title}}" + sep + "{{artist}}" + sep +
                           "{{album}}" + sep + "{{mpris:artUrl}}'");
    }

    Component.onCompleted: poll()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.poll() }

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
        spacing: Kirigami.Units.largeSpacing * 2
        visible: root.hasPlayer

        // Carátula (recortada con el mismo radius que la card)
        C.Card {
            id: coverCard
            Layout.preferredWidth: root.height * 0.9
            Layout.fillHeight: true
            padding: 0

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
                radius: coverCard.radius
                visible: false
            }
            OpacityMask {
                anchors.fill: parent
                source: cover
                maskSource: coverMask
                visible: cover.status === Image.Ready
            }
            Kirigami.Icon {
                anchors.centerIn: parent
                source: "audio-x-generic"
                width: Kirigami.Units.iconSizes.large
                height: width
                visible: cover.status !== Image.Ready
                opacity: 0.5
            }
        }

        // Detalles + controles
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing

            Item { Layout.fillHeight: true }

            C.Marquee {
                Layout.fillWidth: true
                text: root.title
                pixelSize: Kirigami.Units.gridUnit * 1.4
            }
            PC3.Label {
                Layout.fillWidth: true
                text: root.artist
                opacity: 0.8
                elide: Text.ElideRight
            }
            PC3.Label {
                Layout.fillWidth: true
                text: root.album
                opacity: 0.6
                font: Kirigami.Theme.smallFont
                elide: Text.ElideRight
                visible: root.album.length > 0
            }

            RowLayout {
                Layout.topMargin: Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.largeSpacing

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

            Item { Layout.fillHeight: true }
        }
    }
}
