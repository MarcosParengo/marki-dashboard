import QtQuick
import org.kde.kirigami as Kirigami

// Visualizador de barras decorativo (no reactivo al audio, estilo glava/cava).
Item {
    id: root

    property int bars: 48
    property color barColor: Qt.rgba(Kirigami.Theme.textColor.r,
                                     Kirigami.Theme.textColor.g,
                                     Kirigami.Theme.textColor.b, 0.16)
    property bool active: true
    property var levels: []

    Component.onCompleted: {
        const a = [];
        for (let i = 0; i < bars; i++) a.push(0.06);
        levels = a;
    }

    Timer {
        interval: 110
        running: root.visible
        repeat: true
        onTriggered: {
            const a = root.levels.slice();
            for (let i = 0; i < a.length; i++) {
                const target = root.active ? (0.06 + Math.random() * Math.random() * 0.94) : 0.04;
                a[i] = a[i] * 0.55 + target * 0.45; // suavizado
            }
            root.levels = a;
            canvas.requestPaint();
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const n = root.levels.length;
            if (!n || width <= 0) return;
            const slot = width / n;
            const bw = slot * 0.55;
            ctx.fillStyle = root.barColor;
            for (let i = 0; i < n; i++) {
                const h = Math.max(bw, height * root.levels[i]);
                const x = i * slot + (slot - bw) / 2;
                const y = height - h;
                const r = bw / 2;
                // barra con puntas redondeadas
                ctx.beginPath();
                ctx.moveTo(x, y + r);
                ctx.arcTo(x, y, x + r, y, r);
                ctx.arcTo(x + bw, y, x + bw, y + r, r);
                ctx.lineTo(x + bw, height);
                ctx.lineTo(x, height);
                ctx.closePath();
                ctx.fill();
            }
        }
    }
}
