import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.plasma5support as P5Support
import org.kde.taskmanager as TaskManager
import org.kde.kirigami as Kirigami
import "../components" as C

Item {
    id: root

    TaskManager.VirtualDesktopInfo { id: vdInfo }

    // Cambio de escritorio (best-effort vía dbus)
    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (source) => exec.disconnectSource(source)
    }
    function switchTo(n) {
        exec.connectSource("dbus-send --session --dest=org.kde.KWin --type=method_call " +
                           "/KWin org.kde.KWin.setCurrentDesktop int32:" + n);
    }

    GridLayout {
        anchors.fill: parent
        columns: Math.max(1, Math.min(vdInfo.numberOfDesktops,
                          Math.floor(root.width / (Kirigami.Units.gridUnit * 10))))
        rowSpacing: Kirigami.Units.largeSpacing
        columnSpacing: Kirigami.Units.largeSpacing

        Repeater {
            model: vdInfo.numberOfDesktops

            delegate: C.Card {
                id: deskCard
                required property int index
                readonly property var deskId: vdInfo.desktopIds[index]
                readonly property bool current: deskId === vdInfo.currentDesktop

                Layout.fillWidth: true
                Layout.fillHeight: true
                border.width: current ? 2 : 1
                border.color: current ? Kirigami.Theme.highlightColor
                                      : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)

                // Modelo de ventanas de este escritorio
                TaskManager.TasksModel {
                    id: tasks
                    filterByVirtualDesktop: true
                    virtualDesktop: deskCard.deskId
                    groupMode: TaskManager.TasksModel.GroupDisabled
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Kirigami.Units.smallSpacing

                    // Cabecera del escritorio (clic = cambiar)
                    PC3.Label {
                        Layout.fillWidth: true
                        text: (vdInfo.desktopNames[deskCard.index] || i18n("Escritorio %1", deskCard.index + 1))
                        font.bold: true
                        color: deskCard.current ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                        elide: Text.ElideRight

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.switchTo(deskCard.index + 1)
                        }
                    }

                    // Ventanas
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 2
                        model: tasks
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: PC3.ItemDelegate {
                            width: ListView.view.width
                            required property int index
                            required property var model
                            icon.name: model.decoration && typeof model.decoration === "string" ? model.decoration : ""
                            text: model.display || model.AppName || ""
                            onClicked: tasks.requestActivate(tasks.index(index, 0))
                        }
                    }

                    PC3.Label {
                        Layout.fillWidth: true
                        visible: tasks.count === 0
                        text: i18n("Sin ventanas")
                        opacity: 0.5
                        font: Kirigami.Theme.smallFont
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
}
