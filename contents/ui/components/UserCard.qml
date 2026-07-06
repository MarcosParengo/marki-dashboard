import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import org.kde.plasma.components 3.0 as PC3
import org.kde.kirigami as Kirigami

// Tarjeta de usuario: avatar + distro / WM / uptime.
RowLayout {
    id: root

    property string distro: ""
    property string wm: ""
    property string uptime: ""
    property string facePath: ""   // file:// URL a ~/.face (opcional)
    // Radio de la foto; se ata a la fórmula del thumbnail desde afuera.
    property real imageRadius: Kirigami.Units.cornerRadius

    spacing: Kirigami.Units.largeSpacing

    // Avatar: cuadrado que llena el alto de la card
    Item {
        id: avatar
        Layout.alignment: Qt.AlignVCenter
        Layout.fillHeight: true
        Layout.preferredWidth: height

        // Fondo/fallback cuando no hay foto
        Rectangle {
            anchors.fill: parent
            radius: root.imageRadius
            visible: face.status !== Image.Ready
            color: Qt.rgba(Kirigami.Theme.highlightColor.r,
                           Kirigami.Theme.highlightColor.g,
                           Kirigami.Theme.highlightColor.b, 0.18)
            Kirigami.Icon {
                anchors.centerIn: parent
                source: "user-identity"
                width: parent.width * 0.55
                height: width
                opacity: 0.8
            }
        }

        // Foto recortada con esquinas redondeadas
        Image {
            id: face
            anchors.fill: parent
            source: root.facePath
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
        }
        Rectangle {
            id: mask
            anchors.fill: parent
            radius: root.imageRadius
            visible: false
        }
        OpacityMask {
            anchors.fill: parent
            source: face
            maskSource: mask
            visible: face.status === Image.Ready
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: Kirigami.Units.smallSpacing

        InfoRow { icon: "distributor-logo-archlinux"; fallback: "computer"; label: root.distro }
        InfoRow { icon: "preferences-system-windows"; fallback: "kde"; label: root.wm }
        InfoRow { icon: "chronometer"; fallback: "chronometer"; label: root.uptime }
    }

    component InfoRow: RowLayout {
        id: infoRow
        property string icon: ""
        property string fallback: ""
        property string label: ""
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing
        visible: infoRow.label.length > 0

        Kirigami.Icon {
            source: infoRow.icon
            fallback: infoRow.fallback
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
        }
        PC3.Label {
            text: infoRow.label
            elide: Text.ElideRight
            Layout.fillWidth: true
            font.weight: Font.DemiBold
        }
    }
}
