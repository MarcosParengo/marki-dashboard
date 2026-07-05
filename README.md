# Dashboard (plasmoide para KDE Plasma 6)

Reloj de panel que, al hacer clic, abre un dashboard con pestañas — inspirado en el
dashboard de [caelestia-shell](https://github.com/caelestia-dots/shell), pero como
plasmoide nativo de Plasma 6 (Qt6 / KF6).

## Pestañas

- **Dashboard** — reloj/fecha, info del sistema (distro, kernel, uptime), calendario
  y barras verticales de CPU / RAM / Volumen.
- **Media** — reproductor MPRIS (carátula, metadatos, controles) vía `playerctl`.
- **Performance** — CPU, RAM, red y disco usando los sensores de `ksysguard`.
- **Workspaces** — escritorios virtuales de KWin y sus ventanas (clic para activar).

## Dependencias

- Plasma 6 / Qt 6 / KF6
- `playerctl` (pestaña Media)
- `wpctl` / PipeWire (barra de volumen)
- `org.kde.ksysguard.sensors`, `org.kde.taskmanager`, `org.kde.plasma.workspace.calendar`

## Instalación

El paquete vive en `~/.local/share/plasma/plasmoids/org.marki.dashboard/`.
Luego, en modo edición del panel: **Agregar widgets → "Dashboard"**.

Si no aparece tras instalarlo:

```sh
kquitapp6 plasmashell && kstart plasmashell
```

## Probar aislado

```sh
plasmawindowed org.marki.dashboard
```

## Licencia

MIT
