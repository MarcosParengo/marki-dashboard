import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Barra negra arrastrable (0..1). Emite seek(frac) al soltar.
Item {
    id: root

    property real value: 0        // 0..1 (externo)
    property bool dragging: false
    property real frac: 0         // valor mostrado
    signal seek(real frac)

    implicitHeight: Kirigami.Units.gridUnit
    Layout.alignment: Qt.AlignVCenter

    onValueChanged: if (!dragging) frac = Math.max(0, Math.min(1, value))
    Component.onCompleted: frac = Math.max(0, Math.min(1, value))

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: Kirigami.Units.smallSpacing + 2
        radius: height / 2
        color: Qt.rgba(Kirigami.Theme.textColor.r,
                       Kirigami.Theme.textColor.g,
                       Kirigami.Theme.textColor.b, 0.2)

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * Math.max(0, Math.min(1, root.frac))
            radius: parent.radius
            color: Kirigami.Theme.textColor
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function apply(mx) { root.frac = Math.max(0, Math.min(1, mx / width)); }
        onPressed: (m) => { root.dragging = true; apply(m.x); }
        onPositionChanged: (m) => { if (pressed) apply(m.x); }
        onReleased: { root.dragging = false; root.seek(root.frac); }
    }
}
