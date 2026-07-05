import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.plasma5support as P5Support
import org.kde.ksysguard.sensors as Sensors
import org.kde.plasma.workspace.calendar as Calendar
import org.kde.kirigami as Kirigami
import "../components" as C

Item {
    id: root

    property date now: new Date()

    // ---------- Fuentes de datos ----------
    Sensors.Sensor {
        id: cpuSensor
        sensorId: "cpu/all/usage"
    }
    Sensors.Sensor {
        id: memSensor
        sensorId: "memory/physical/usedPercent"
    }

    property string kernel: ""
    property string distro: ""
    property string uptime: ""
    property real volume: 0

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            const out = (data["stdout"] || "").trim();
            if (source.indexOf("uname") !== -1)
                root.kernel = out;
            else if (source.indexOf("os-release") !== -1) {
                const m = out.match(/PRETTY_NAME="?([^"\n]+)"?/);
                root.distro = m ? m[1] : out;
            } else if (source.indexOf("uptime") !== -1)
                root.uptime = out;
            else if (source.indexOf("wpctl") !== -1) {
                const m = out.match(/Volume:\s*([0-9.]+)/);
                root.volume = m ? parseFloat(m[1]) : 0;
            }
            exec.disconnectSource(source);
        }
    }

    function poll() {
        exec.connectSource("uptime -p");
        exec.connectSource("wpctl get-volume @DEFAULT_AUDIO_SINK@");
    }

    Component.onCompleted: {
        exec.connectSource("uname -r");
        exec.connectSource("cat /etc/os-release");
        poll();
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.poll()
    }

    // ---------- Layout ----------
    RowLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        // ===== Columna izquierda =====
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.horizontalStretchFactor: 42
            Layout.minimumWidth: Kirigami.Units.gridUnit * 10
            spacing: Kirigami.Units.largeSpacing

            // Reloj + fecha
            C.Card {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 6

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0

                    PC3.Label {
                        text: Qt.formatDateTime(root.now, "hh:mm")
                        font.pixelSize: Kirigami.Units.gridUnit * 2.6
                        font.bold: true
                        color: Kirigami.Theme.highlightColor
                    }
                    PC3.Label {
                        text: Qt.formatDateTime(root.now, "dddd")
                        font.capitalization: Font.Capitalize
                        opacity: 0.9
                    }
                    PC3.Label {
                        text: Qt.formatDateTime(root.now, "d MMM yyyy")
                        opacity: 0.7
                        font: Kirigami.Theme.smallFont
                    }
                }
            }

            // Info del sistema
            C.Card {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Kirigami.Units.smallSpacing

                    InfoRow { icon: "computer"; label: root.distro }
                    InfoRow { icon: "utilities-terminal"; label: "Linux " + root.kernel }
                    InfoRow { icon: "chronometer"; label: root.uptime }
                    Item { Layout.fillHeight: true }
                }
            }

            // Barras CPU / RAM / Volumen
            C.Card {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 8

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Kirigami.Units.largeSpacing * 2

                    C.VerticalMeter {
                        label: "CPU"
                        value: (cpuSensor.value || 0) / 100
                        fillColor: Kirigami.Theme.highlightColor
                    }
                    C.VerticalMeter {
                        label: "RAM"
                        value: (memSensor.value || 0) / 100
                        fillColor: Kirigami.Theme.positiveTextColor
                    }
                    C.VerticalMeter {
                        label: "VOL"
                        value: root.volume
                        fillColor: Kirigami.Theme.neutralTextColor
                    }
                }
            }
        }

        // ===== Columna derecha: calendario =====
        C.Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.horizontalStretchFactor: 58
            Layout.minimumWidth: Kirigami.Units.gridUnit * 13

            Calendar.MonthView {
                anchors.fill: parent
                today: root.now
            }
        }
    }

    // Fila de info con icono
    component InfoRow: RowLayout {
        id: infoRow
        property string icon: ""
        property string label: ""
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing
        visible: infoRow.label.length > 0

        Kirigami.Icon {
            source: infoRow.icon
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
        }
        PC3.Label {
            text: infoRow.label
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }
}
