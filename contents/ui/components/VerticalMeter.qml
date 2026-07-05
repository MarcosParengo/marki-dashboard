import QtQuick
import org.kde.kirigami as Kirigami

// Barra vertical de progreso (uso CPU / RAM / volumen).
Item {
    id: root

    property real value: 0            // 0.0 .. 1.0
    property string label: ""
    property color fillColor: Kirigami.Theme.highlightColor

    implicitWidth: Kirigami.Units.gridUnit * 1.4
    implicitHeight: Kirigami.Units.gridUnit * 6

    Column {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        // Riel
        Rectangle {
            id: track
            width: Kirigami.Units.gridUnit * 0.8
            height: parent.height - label.height - parent.spacing
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

        Text {
            id: label
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            color: Kirigami.Theme.textColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            font.capitalization: Font.AllUppercase
        }
    }
}
