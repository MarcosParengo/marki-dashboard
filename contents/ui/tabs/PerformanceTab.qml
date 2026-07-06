import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.plasma5support as P5Support
import org.kde.ksysguard.sensors as Sensors
import org.kde.kirigami as Kirigami
import "../components" as C

Item {
    id: root

    readonly property color accent: Kirigami.Theme.textColor

    // ---------- Sensores ----------
    Sensors.Sensor { id: cpu;     sensorId: "cpu/all/usage" }
    Sensors.Sensor { id: cpuTemp; sensorId: "cpu/all/averageTemperature" }
    Sensors.Sensor { id: memPct;  sensorId: "memory/physical/usedPercent" }
    Sensors.Sensor { id: memUsed; sensorId: "memory/physical/used" }
    Sensors.Sensor { id: memTot;  sensorId: "memory/physical/total" }
    Sensors.Sensor { id: netDown; sensorId: "network/all/download" }
    Sensors.Sensor { id: netUp;   sensorId: "network/all/upload" }

    // ---------- Datos por exec ----------
    property string cpuName: ""
    property real gpuUsage: 0
    property real gpuTemp: 0
    property real diskPct: 0
    property string diskUsed: ""
    property string diskTotal: ""
    property real batPct: 0
    property string batStatus: ""

    function fmtGiB(bytes) { return (bytes / 1073741824).toFixed(1); }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            const out = (data["stdout"] || "").trim();
            if (source.indexOf("model name") !== -1) {
                root.cpuName = out.replace(/\(R\)|\(TM\)/g, "").trim();
            } else if (source.indexOf("gpu_busy_percent") !== -1) {
                const l = out.split("\n");
                root.gpuUsage = (parseFloat(l[0]) || 0) / 100;
                root.gpuTemp = (parseFloat(l[1]) || 0) / 1000;
            } else if (source.indexOf("df") !== -1) {
                const p = out.split(/\s+/);
                if (p.length >= 3) {
                    root.diskUsed = fmtGiB(parseFloat(p[0]));
                    root.diskTotal = fmtGiB(parseFloat(p[1]));
                    root.diskPct = parseFloat(p[2]) / 100;
                }
            } else if (source.indexOf("power_supply") !== -1) {
                const lines = out.split("\n");
                root.batPct = (parseFloat(lines[0]) || 0) / 100;
                root.batStatus = (lines[1] || "").trim();
            }
            exec.disconnectSource(source);
        }
    }

    function poll() {
        exec.connectSource("sh -c 'df -B1 --output=used,size,pcent / | tail -1'");
        exec.connectSource("sh -c 'cat /sys/class/power_supply/BAT0/capacity; cat /sys/class/power_supply/BAT0/status'");
        exec.connectSource("sh -c 'cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -1; for h in /sys/class/hwmon/hwmon*; do [ \"$(cat $h/name 2>/dev/null)\" = amdgpu ] && cat $h/temp1_input; done'");
    }
    Component.onCompleted: {
        exec.connectSource("sh -c \"grep -m1 'model name' /proc/cpuinfo | cut -d: -f2\"");
        poll();
    }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: root.poll() }

    // ---------- Layout ----------
    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        // ===== Fila 0: CPU | GPU =====
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.preferredHeight: Kirigami.Units.gridUnit * 7
            Layout.maximumHeight: Kirigami.Units.gridUnit * 7
            spacing: Kirigami.Units.largeSpacing

            C.Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                HeroCard {
                    icon: "cpu"
                    label: "CPU"
                    subLabel: root.cpuName
                    usage: (cpu.value || 0) / 100
                    temp: cpuTemp.value || 0
                }
            }
            C.Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                HeroCard {
                    icon: "video-display"
                    label: "GPU"
                    subLabel: "Radeon Graphics"
                    usage: root.gpuUsage
                    temp: root.gpuTemp
                }
            }
        }

        // ===== Fila 1: Memoria | Disco | Red | Batería =====
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.largeSpacing

            C.Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                RingCard {
                    icon: "media-flash-memory-stick"
                    title: "Memoria"
                    value: (memPct.value || 0) / 100
                    detail: (memUsed.formattedValue || "0") + " / " + (memTot.formattedValue || "0")
                }
            }
            C.Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                RingCard {
                    icon: "drive-harddisk"
                    title: "Disco"
                    value: root.diskPct
                    detail: root.diskUsed + " / " + root.diskTotal + " GiB"
                }
            }
            C.Card {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Kirigami.Units.smallSpacing

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Kirigami.Units.smallSpacing
                        Kirigami.Icon {
                            source: "network-wired"
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        }
                        PC3.Label { text: "Red"; font.weight: Font.DemiBold }
                    }

                    Canvas {
                        id: spark
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        property var hist: []
                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();
                            const n = hist.length;
                            if (n < 2) return;
                            let mx = 1;
                            for (let i = 0; i < n; i++) mx = Math.max(mx, hist[i]);
                            const dx = width / (n - 1);
                            ctx.beginPath();
                            for (let i = 0; i < n; i++) {
                                const x = i * dx;
                                const y = height - (hist[i] / mx) * height;
                                if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
                            }
                            ctx.lineWidth = 2;
                            ctx.lineCap = "round";
                            ctx.lineJoin = "round";
                            ctx.strokeStyle = root.accent;
                            ctx.stroke();
                            ctx.lineTo(width, height);
                            ctx.lineTo(0, height);
                            ctx.closePath();
                            ctx.fillStyle = Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.12);
                            ctx.fill();
                        }
                    }

                    NetRow { label: "↓"; value: netDown.formattedValue || "0 B/s" }
                    NetRow { label: "↑"; value: netUp.formattedValue || "0 B/s" }
                }
            }
            C.Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                RingCard {
                    icon: root.batStatus === "Charging" ? "battery-full-charging" : "battery-full"
                    title: "Batería"
                    value: root.batPct
                    detail: root.batStatus === "Charging" ? "Cargando"
                        : (root.batStatus === "Full" ? "Full" : "Descargando")
                }
            }
        }
    }

    // Actualizar sparkline con la descarga
    Connections {
        target: netDown
        function onValueChanged() {
            const h = spark.hist.slice();
            h.push(netDown.value || 0);
            if (h.length > 40) h.shift();
            spark.hist = h;
            spark.requestPaint();
        }
    }

    // ---------- HeroCard (CPU/GPU) ----------
    component HeroCard: RowLayout {
        id: hero
        property string icon: ""
        property string label: ""
        property string subLabel: ""
        property real usage: 0
        property real temp: 0
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        C.CircularProgress {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: Kirigami.Units.gridUnit * 3
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3
            value: hero.usage
            fgColor: root.accent

            Kirigami.Icon {
                anchors.centerIn: parent
                source: hero.icon
                width: Kirigami.Units.iconSizes.medium
                height: width
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                PC3.Label {
                    text: hero.label
                    font.pixelSize: Kirigami.Units.gridUnit
                    font.weight: Font.DemiBold
                }
                Item { Layout.fillWidth: true }
                PC3.Label {
                    text: Math.round(hero.usage * 100) + "%"
                    font.pixelSize: Kirigami.Units.gridUnit * 1.4
                    font.weight: Font.DemiBold
                }
            }
            PC3.Label {
                Layout.fillWidth: true
                text: hero.subLabel
                opacity: 0.7
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                font.weight: Font.Medium
                elide: Text.ElideRight
                wrapMode: Text.WordWrap
                maximumLineCount: 2
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                spacing: Kirigami.Units.smallSpacing
                Kirigami.Icon {
                    source: "temperature-normal"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                }
                PC3.Label {
                    text: Math.round(hero.temp) + "°C"
                    font.weight: Font.DemiBold
                }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                height: Kirigami.Units.smallSpacing
                radius: height / 2
                color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.2)
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * Math.max(0, Math.min(1, hero.temp / 100))
                    radius: parent.radius
                    color: root.accent
                }
            }
        }
    }

    // ---------- RingCard (memoria/disco/batería) ----------
    component RingCard: ColumnLayout {
        id: rc
        property string icon: ""
        property string title: ""
        property real value: 0
        property string detail: ""
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Kirigami.Units.smallSpacing
            Kirigami.Icon {
                source: rc.icon
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }
            PC3.Label { text: rc.title; font.weight: Font.DemiBold }
        }

        C.CircularProgress {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
            Layout.preferredWidth: height
            startAngle: -225
            sweepAngle: 270
            value: rc.value
            fgColor: root.accent

            PC3.Label {
                anchors.centerIn: parent
                text: Math.round(rc.value * 100) + "%"
                font.pixelSize: Kirigami.Units.gridUnit * 1.1
                font.weight: Font.DemiBold
            }
        }

        PC3.Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: rc.detail
            opacity: 0.8
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            font.weight: Font.Medium
            elide: Text.ElideRight
        }
    }

    // ---------- Fila de red ----------
    component NetRow: RowLayout {
        id: nr
        property string label: ""
        property string value: ""
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        PC3.Label { text: nr.label; font.weight: Font.DemiBold; opacity: 0.8 }
        Item { Layout.fillWidth: true }
        PC3.Label {
            text: nr.value
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            font.weight: Font.Medium
        }
    }
}
