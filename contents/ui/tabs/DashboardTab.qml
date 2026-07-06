import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.plasma5support as P5Support
import org.kde.ksysguard.sensors as Sensors
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
    property string wm: ""
    property string facePath: ""
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
            else if (source.indexOf("XDG_CURRENT_DESKTOP") !== -1)
                root.wm = out === "KDE" ? "KDE Plasma" : out;
            else if (source.indexOf(".face") !== -1)
                root.facePath = out;
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
        exec.connectSource("printf %s \"$XDG_CURRENT_DESKTOP\"");
        exec.connectSource("sh -c 'test -f \"$HOME/.face\" && printf \"file://%s/.face\" \"$HOME\"'");
        poll();
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.poll()
    }

    // ---------- Layout: regiones anidadas estilo caelestia ----------
    RowLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        // ===== Zona principal (izquierda + centro) =====
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.largeSpacing

            // ---- Fila superior: Clima + Usuario ----
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                Layout.maximumHeight: Kirigami.Units.gridUnit * 5
                spacing: Kirigami.Units.largeSpacing

                C.Card {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 9
                    Layout.fillHeight: true

                    C.WeatherCard { anchors.fill: parent }
                }

                C.Card {
                    id: userCard
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    C.UserCard {
                        anchors.fill: parent
                        distro: root.distro
                        wm: root.wm
                        uptime: root.uptime
                        facePath: Qt.resolvedUrl("../assets/avatar.png")
                        // Mismo redondeo que el thumbnail (concéntrico con la card)
                        imageRadius: Math.max(Kirigami.Units.cornerRadius,
                                              userCard.radius - userCard.padding)
                    }
                }
            }

            // ---- Fila inferior: Reloj + Calendario + Recursos ----
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Kirigami.Units.largeSpacing

                // Reloj vertical (hora ••• minutos)
                C.Card {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        Item { Layout.fillHeight: true }

                        PC3.Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDateTime(root.now, "hh")
                            font.pixelSize: Kirigami.Units.gridUnit * 2.2
                            font.weight: Font.DemiBold
                            color: Kirigami.Theme.textColor
                            lineHeight: 0.95
                        }
                        PC3.Label {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: -Kirigami.Units.smallSpacing
                            Layout.bottomMargin: -Kirigami.Units.smallSpacing
                            text: "•••"
                            font.pixelSize: Kirigami.Units.gridUnit
                            font.weight: Font.DemiBold
                            color: Kirigami.Theme.textColor
                            opacity: 0.7
                        }
                        PC3.Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDateTime(root.now, "mm")
                            font.pixelSize: Kirigami.Units.gridUnit * 2.2
                            font.weight: Font.DemiBold
                            color: Kirigami.Theme.textColor
                            lineHeight: 0.95
                        }
                        PC3.Label {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: Kirigami.Units.smallSpacing
                            text: Qt.formatDateTime(root.now, "ddd, d")
                            opacity: 0.7
                            font: Kirigami.Theme.smallFont
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                // Calendario
                C.Card {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    C.CalendarGrid {
                        anchors.fill: parent
                        today: root.now
                    }
                }

                // Recursos CPU / RAM / VOL
                C.Card {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.fill: parent
                        spacing: Kirigami.Units.smallSpacing

                        C.VerticalMeter {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            label: "CPU"
                            value: (cpuSensor.value || 0) / 100
                            fillColor: Kirigami.Theme.textColor
                        }
                        C.VerticalMeter {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            label: "RAM"
                            value: (memSensor.value || 0) / 100
                            fillColor: Kirigami.Theme.textColor
                        }
                        C.VerticalMeter {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            label: "VOL"
                            value: root.volume
                            fillColor: Kirigami.Theme.textColor
                        }
                    }
                }
            }
        }

        // ===== Media (columna alta a la derecha) =====
        C.Card {
            id: mediaCard
            Layout.preferredWidth: Kirigami.Units.gridUnit * 8
            Layout.fillHeight: true

            C.MediaCard {
                anchors.fill: parent
                // Redondeo concéntrico con la card (radio_card − padding),
                // con piso en cornerRadius para que nunca quede cuadrado.
                coverRadius: Math.max(Kirigami.Units.cornerRadius,
                                      mediaCard.radius - mediaCard.padding)
            }
        }
    }
}
