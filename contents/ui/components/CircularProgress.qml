import QtQuick
import org.kde.kirigami as Kirigami

// Anillo de progreso configurable (ángulo de inicio y barrido).
Item {
    id: root

    property real value: 0                 // 0..1
    property real startAngle: -90           // grados
    property real sweepAngle: 360           // grados
    property color fgColor: Kirigami.Theme.textColor
    property color bgColor: Qt.rgba(Kirigami.Theme.textColor.r,
                                    Kirigami.Theme.textColor.g,
                                    Kirigami.Theme.textColor.b, 0.15)
    property real thickness: Kirigami.Units.gridUnit * 0.35

    default property alias content: inner.data

    Behavior on value { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
    onValueChanged: canvas.requestPaint()
    onFgColorChanged: canvas.requestPaint()
    onBgColorChanged: canvas.requestPaint()
    onStartAngleChanged: canvas.requestPaint()
    onSweepAngleChanged: canvas.requestPaint()
    onThicknessChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const cx = width / 2, cy = height / 2;
            const r = Math.min(width, height) / 2 - root.thickness / 2;
            if (r <= 0) return;
            const s = root.startAngle * Math.PI / 180;
            const sweep = root.sweepAngle * Math.PI / 180;
            const v = Math.max(0, Math.min(1, root.value || 0));

            ctx.lineWidth = root.thickness;
            ctx.lineCap = "round";

            ctx.beginPath();
            ctx.strokeStyle = root.bgColor;
            ctx.arc(cx, cy, r, s, s + sweep);
            ctx.stroke();

            if (v > 0) {
                ctx.beginPath();
                ctx.strokeStyle = root.fgColor;
                ctx.arc(cx, cy, r, s, s + sweep * v);
                ctx.stroke();
            }
        }
    }

    Item {
        id: inner
        anchors.fill: parent
    }
}
