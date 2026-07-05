import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PC3
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // Reloj vive en el panel; el dashboard se abre al hacer clic.
    preferredRepresentation: compactRepresentation

    property date now: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    // ---- Representación compacta: la hora en el panel ----
    compactRepresentation: MouseArea {
        id: compact

        readonly property bool horizontal: Plasmoid.formFactor === PlasmaCore.Types.Horizontal

        Layout.minimumWidth: horizontal ? timeLabel.implicitWidth + Kirigami.Units.largeSpacing : 0
        Layout.minimumHeight: horizontal ? 0 : timeLabel.implicitHeight + Kirigami.Units.largeSpacing

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.expanded = !root.expanded

        PC3.Label {
            id: timeLabel
            anchors.centerIn: parent
            text: Qt.formatDateTime(root.now, "hh:mm:ss")
            font.pixelSize: Math.max(Kirigami.Theme.defaultFont.pixelSize,
                                     Math.round(compact.height * 0.42))
            font.features: { "tnum": 1 } // números tabulares: no "salta" el ancho
        }
    }

    // ---- Representación completa: el dashboard con pestañas ----
    fullRepresentation: Dashboard {
        now: root.now
    }
}
