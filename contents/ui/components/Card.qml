import QtQuick
import org.kde.kirigami as Kirigami

// Tarjeta con esquinas redondeadas al estilo del dashboard de caelestia.
Rectangle {
    default property alias content: inner.data
    property real padding: Kirigami.Units.largeSpacing

    radius: Kirigami.Units.cornerRadius * 2
    color: Qt.rgba(Kirigami.Theme.backgroundColor.r,
                   Kirigami.Theme.backgroundColor.g,
                   Kirigami.Theme.backgroundColor.b, 0.55)
    border.width: 1
    border.color: Qt.rgba(Kirigami.Theme.textColor.r,
                          Kirigami.Theme.textColor.g,
                          Kirigami.Theme.textColor.b, 0.08)

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: parent.padding
    }
}
