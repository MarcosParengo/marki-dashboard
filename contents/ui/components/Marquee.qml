import QtQuick
import org.kde.plasma.components 3.0 as PC3
import org.kde.kirigami as Kirigami

// Texto con ticker infinito a velocidad constante cuando no entra en el ancho.
Item {
    id: root

    property string text: ""
    property int pixelSize: Kirigami.Theme.defaultFont.pixelSize
    property int weight: Font.DemiBold
    property real speed: 34            // ms por pixel (más alto = más lento)

    readonly property real gap: Kirigami.Units.gridUnit * 2
    readonly property bool overflow: metrics.width > width

    implicitHeight: metrics.height
    clip: true

    TextMetrics {
        id: metrics
        font.pixelSize: root.pixelSize
        font.weight: root.weight
        text: root.text
    }

    // Entra completo: texto fijo y centrado
    PC3.Label {
        visible: !root.overflow
        anchors.centerIn: parent
        text: root.text
        font.pixelSize: root.pixelSize
        font.weight: root.weight
        wrapMode: Text.NoWrap
    }

    // No entra: dos copias en loop continuo
    Row {
        visible: root.overflow
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.gap

        Repeater {
            model: 2
            delegate: PC3.Label {
                text: root.text
                font.pixelSize: root.pixelSize
                font.weight: root.weight
                wrapMode: Text.NoWrap
            }
        }

        NumberAnimation on x {
            running: root.overflow
            loops: Animation.Infinite
            from: 0
            to: -(metrics.width + root.gap)
            duration: Math.max(1, metrics.width + root.gap) * root.speed
            // easing lineal por defecto -> velocidad constante
        }
    }
}
