import QtQuick
import org.kde.kirigami as Kirigami

// Barra vertical de progreso tipo píldora (uso CPU / RAM / volumen).
Item {
    id: root

    property real value: 0            // 0.0 .. 1.0
    property string label: ""
    property string icon: ""          // glifo opcional bajo la barra
    property color fillColor: Kirigami.Theme.highlightColor

    implicitWidth: Kirigami.Units.gridUnit * 1.4
    implicitHeight: Kirigami.Units.gridUnit * 6

    Column {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        // Riel (píldora)
        Rectangle {
            id: track
            width: Kirigami.Units.gridUnit * 0.65
            height: parent.height - footer.height - parent.spacing
            anchors.horizontalCenter: parent.horizontalCenter
            radius: width / 2
            color: Qt.rgba(Kirigami.Theme.textColor.r,
                           Kirigami.Theme.textColor.g,
                           Kirigami.Theme.textColor.b, 0.12)

            // Relleno
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                radius: parent.radius
                height: Math.max(width, parent.height * Math.max(0, Math.min(1, root.value)))
                color: root.fillColor
                Behavior on height {
                    NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
                }
            }
        }

        // Pie: icono si se define, si no la etiqueta de texto
        Item {
            id: footer
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.max(iconItem.width, textLabel.implicitWidth)
            height: root.icon.length > 0 ? iconItem.height : textLabel.implicitHeight

            Kirigami.Icon {
                id: iconItem
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.icon.length > 0
                source: root.icon
                width: Kirigami.Units.iconSizes.small
                height: width
                color: root.fillColor
                isMask: true
            }

            Text {
                id: textLabel
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.icon.length === 0
                text: root.label
                color: Kirigami.Theme.textColor
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                font.weight: Font.DemiBold
                font.capitalization: Font.AllUppercase
            }
        }
    }
}
