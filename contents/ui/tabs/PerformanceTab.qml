import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components 3.0 as PC3
import org.kde.ksysguard.sensors as Sensors
import org.kde.kirigami as Kirigami
import "../components" as C

Item {
    id: root

    Sensors.Sensor { id: cpu;   sensorId: "cpu/all/usage" }
    Sensors.Sensor { id: mem;   sensorId: "memory/physical/usedPercent" }
    Sensors.Sensor { id: down;  sensorId: "network/all/download" }
    Sensors.Sensor { id: up;    sensorId: "network/all/upload" }
    Sensors.Sensor { id: dread; sensorId: "disk/all/read" }
    Sensors.Sensor { id: dwrite;sensorId: "disk/all/write" }

    GridLayout {
        anchors.fill: parent
        columns: 2
        rowSpacing: Kirigami.Units.largeSpacing
        columnSpacing: Kirigami.Units.largeSpacing

        // CPU
        C.Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            GaugeContent {
                icon: "cpu"
                title: "CPU"
                percent: (cpu.value || 0) / 100
                caption: Math.round(cpu.value || 0) + " %"
                accent: Kirigami.Theme.highlightColor
            }
        }

        // RAM
        C.Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            GaugeContent {
                icon: "media-flash-memory-stick"
                title: "Memoria"
                percent: (mem.value || 0) / 100
                caption: Math.round(mem.value || 0) + " %"
                accent: Kirigami.Theme.positiveTextColor
            }
        }

        // Red
        C.Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            StatContent {
                icon: "network-wired"
                title: "Red"
                line1: "↓ " + (down.formattedValue || "0 B/s")
                line2: "↑ " + (up.formattedValue || "0 B/s")
            }
        }

        // Disco
        C.Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            StatContent {
                icon: "drive-harddisk"
                title: "Disco"
                line1: "R " + (dread.formattedValue || "0 B/s")
                line2: "W " + (dwrite.formattedValue || "0 B/s")
            }
        }
    }

    // --- Tarjeta con barra de porcentaje ---
    component GaugeContent: ColumnLayout {
        id: gauge
        property string icon: ""
        property string title: ""
        property real percent: 0
        property string caption: ""
        property color accent: Kirigami.Theme.highlightColor
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Kirigami.Icon { source: gauge.icon; Layout.preferredWidth: Kirigami.Units.iconSizes.small; Layout.preferredHeight: Kirigami.Units.iconSizes.small }
            PC3.Label { text: gauge.title; font.bold: true }
            Item { Layout.fillWidth: true }
            PC3.Label { text: gauge.caption; opacity: 0.8 }
        }
        Item { Layout.fillHeight: true }
        PC3.ProgressBar {
            Layout.fillWidth: true
            from: 0; to: 1
            value: gauge.percent
        }
    }

    // --- Tarjeta con dos líneas de texto (red/disco) ---
    component StatContent: ColumnLayout {
        id: stat
        property string icon: ""
        property string title: ""
        property string line1: ""
        property string line2: ""
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Kirigami.Icon { source: stat.icon; Layout.preferredWidth: Kirigami.Units.iconSizes.small; Layout.preferredHeight: Kirigami.Units.iconSizes.small }
            PC3.Label { text: stat.title; font.bold: true }
        }
        Item { Layout.fillHeight: true }
        PC3.Label { text: stat.line1; font.family: "monospace" }
        PC3.Label { text: stat.line2; font.family: "monospace" }
    }
}
