import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components 3.0 as PC3
import org.kde.kirigami as Kirigami
import "tabs" as Tabs

Item {
    id: root

    property date now: new Date()

    // Tamaño del popup del dashboard
    Layout.preferredWidth: Kirigami.Units.gridUnit * 38
    Layout.preferredHeight: Kirigami.Units.gridUnit * 20
    Layout.minimumWidth: Kirigami.Units.gridUnit * 32
    Layout.minimumHeight: Kirigami.Units.gridUnit * 17

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.largeSpacing

        // ---- Barra de pestañas ----
        PC3.TabBar {
            id: tabBar
            Layout.fillWidth: true
            currentIndex: swipe.currentIndex
            onCurrentIndexChanged: swipe.currentIndex = currentIndex

            PC3.TabButton {
                icon.name: "view-calendar-day"
                text: i18n("Dashboard")
            }
            PC3.TabButton {
                icon.name: "media-playback-start"
                text: i18n("Media")
            }
            PC3.TabButton {
                icon.name: "speedometer"
                text: i18n("Performance")
            }
            PC3.TabButton {
                icon.name: "virtual-desktops"
                text: i18n("Workspaces")
            }
        }

        // ---- Contenido deslizable ----
        PC3.SwipeView {
            id: swipe
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            currentIndex: tabBar.currentIndex

            Tabs.DashboardTab { now: root.now }
            Tabs.MediaTab {}
            Tabs.PerformanceTab {}
            Tabs.WorkspacesTab {}
        }
    }
}
