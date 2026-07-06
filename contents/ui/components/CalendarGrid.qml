import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components 3.0 as PC3
import org.kde.kirigami as Kirigami

// Calendario mensual compacto (semana Lun–Dom), día actual en círculo.
ColumnLayout {
    id: root

    property date today: new Date()
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()   // 0..11

    readonly property var monthNames: [
        i18n("January"), i18n("February"), i18n("March"), i18n("April"),
        i18n("May"), i18n("June"), i18n("July"), i18n("August"),
        i18n("September"), i18n("October"), i18n("November"), i18n("December")
    ]
    readonly property var dayNames: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    // primer día del mes como offset con Lunes=0
    readonly property int firstOffset: (new Date(viewYear, viewMonth, 1).getDay() + 6) % 7
    readonly property int daysInMonth: new Date(viewYear, viewMonth + 1, 0).getDate()

    function sameDay(y, m, d) {
        return d === today.getDate() && m === today.getMonth() && y === today.getFullYear();
    }
    function goPrev() {
        if (viewMonth === 0) { viewMonth = 11; viewYear--; } else viewMonth--;
    }
    function goNext() {
        if (viewMonth === 11) { viewMonth = 0; viewYear++; } else viewMonth++;
    }
    function goToday() {
        viewYear = today.getFullYear();
        viewMonth = today.getMonth();
    }

    spacing: Kirigami.Units.smallSpacing

    // ---- Header: fecha completa de hoy ----
    PC3.Label {
        Layout.fillWidth: true
        Layout.bottomMargin: Kirigami.Units.smallSpacing
        text: {
            const s = root.today.toLocaleDateString(Qt.locale(), Locale.LongFormat);
            return s.charAt(0).toUpperCase() + s.slice(1);
        }
        font.weight: Font.DemiBold
        font.pixelSize: Kirigami.Units.gridUnit * 0.9
        elide: Text.ElideRight
    }

    // ---- Grilla ----
    GridLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        columns: 7
        rowSpacing: 0
        columnSpacing: 0

        // Encabezados de días
        Repeater {
            model: 7
            delegate: PC3.Label {
                required property int index
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: root.dayNames[index]
                font: Kirigami.Theme.smallFont
                opacity: 0.6
                bottomPadding: Kirigami.Units.smallSpacing
            }
        }

        // 42 celdas (6 semanas). Los días fuera del mes se muestran atenuados
        // para llenar la grilla (sin espacio vacío abajo).
        Repeater {
            model: 42
            delegate: Item {
                id: cell
                required property int index

                readonly property int dayNum: index - root.firstOffset + 1
                readonly property bool inMonth: dayNum >= 1 && dayNum <= root.daysInMonth
                readonly property bool isToday: inMonth && root.sameDay(root.viewYear, root.viewMonth, dayNum)
                readonly property int displayNum: {
                    if (dayNum < 1)
                        return new Date(root.viewYear, root.viewMonth, 0).getDate() + dayNum; // mes anterior
                    if (dayNum > root.daysInMonth)
                        return dayNum - root.daysInMonth; // mes siguiente
                    return dayNum;
                }

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: Kirigami.Units.gridUnit * 1.1

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height)
                    height: width
                    radius: width / 2
                    color: cell.isToday ? Kirigami.Theme.textColor : "transparent"
                }

                PC3.Label {
                    anchors.centerIn: parent
                    text: cell.displayNum
                    horizontalAlignment: Text.AlignHCenter
                    color: cell.isToday ? Kirigami.Theme.backgroundColor : Kirigami.Theme.textColor
                    opacity: cell.isToday ? 1 : (cell.inMonth ? 0.9 : 0.3)
                    font.weight: cell.isToday ? Font.DemiBold : Font.Normal
                }
            }
        }
    }
}
