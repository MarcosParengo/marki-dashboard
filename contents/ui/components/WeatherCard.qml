import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

// Clima compacto (temperatura + condición) vía wttr.in.
Item {
    id: root

    property string temp: ""
    property string condition: ""

    readonly property string iconName: {
        const c = condition.toLowerCase();
        if (c.indexOf("thunder") !== -1 || c.indexOf("storm") !== -1) return "weather-storm";
        if (c.indexOf("snow") !== -1 || c.indexOf("sleet") !== -1) return "weather-snow";
        if (c.indexOf("rain") !== -1 || c.indexOf("drizzle") !== -1 || c.indexOf("shower") !== -1) return "weather-showers";
        if (c.indexOf("mist") !== -1 || c.indexOf("fog") !== -1 || c.indexOf("haze") !== -1) return "weather-mist";
        if (c.indexOf("overcast") !== -1 || c.indexOf("cloud") !== -1) return "weather-many-clouds";
        if (c.indexOf("clear") !== -1 || c.indexOf("sunny") !== -1) return "weather-clear";
        return "weather-none-available";
    }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            const out = (data["stdout"] || "").trim();
            if (out.length > 0 && out.indexOf("|") !== -1) {
                const p = out.split("|");
                root.temp = (p[0] || "").trim();
                root.condition = (p[1] || "").trim();
            }
            exec.disconnectSource(source);
        }
    }

    function poll() {
        exec.connectSource("curl -s --max-time 8 'wttr.in/?format=%t|%C'");
    }

    Component.onCompleted: poll()
    Timer { interval: 15 * 60 * 1000; running: true; repeat: true; onTriggered: root.poll() }

    RowLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Icon {
            source: root.iconName
            Layout.preferredWidth: Kirigami.Units.iconSizes.large
            Layout.preferredHeight: Kirigami.Units.iconSizes.large
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            PC3.Label {
                text: root.temp.length > 0 ? root.temp.replace("+", "") : "—"
                font.pixelSize: Kirigami.Units.gridUnit * 1.9
                font.weight: Font.DemiBold
            }
            PC3.Label {
                Layout.fillWidth: true
                text: root.condition.length > 0 ? root.condition : i18n("Sin datos")
                opacity: 0.8
                elide: Text.ElideRight
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                font.weight: Font.DemiBold
            }
        }
    }
}
