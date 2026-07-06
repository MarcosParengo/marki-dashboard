import QtQuick
import org.kde.kirigami as Kirigami

// Tarjeta con esquinas muy redondeadas, plana y sin borde, al estilo del
// dashboard de caelestia (superficie sólida "surfaceContainer").
Rectangle {
    default property alias content: inner.data
    property real padding: Kirigami.Units.largeSpacing

    // Fondo gris translúcido (deja pasar el blur del popup), como la
    // pestaña seleccionada del tema de Plasma.
    radius: Kirigami.Units.cornerRadius * 1.6
    color: Qt.rgba(Kirigami.Theme.textColor.r,
                   Kirigami.Theme.textColor.g,
                   Kirigami.Theme.textColor.b, 0.1)
    border.width: 0

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: parent.padding
    }
}
