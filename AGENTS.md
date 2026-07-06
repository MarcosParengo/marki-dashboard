# AGENTS.md — org.marki.dashboard

Contexto para agentes (Claude) que trabajen en este proyecto.

## Qué es

Plasmoid (widget) de **KDE Plasma 6** en **QML**. Es un **reloj de panel** que, al
hacer clic, abre un **dashboard por pestañas**. Recrea el look & feel del dashboard
de **caelestia-shell** (proyecto Quickshell/Hyprland) adaptado a Plasma.

- **Ubicación (esto es lo que se edita):** `~/.local/share/plasma/plasmoids/org.marki.dashboard/`
- **Repo GitHub:** https://github.com/MarcosParengo/marki-dashboard (remoto `origin`, branch `main`, push por SSH como `MarcosParengo`).
- **Referencia de diseño:** un clon de caelestia-shell está en `/mnt/temp2/otro/shell` (solo lectura, para mirar cómo resuelven las cosas: `modules/dashboard/`).

## Estructura

```
contents/ui/
  main.qml            # PlasmoidItem: compactRepresentation (reloj hh:mm:ss) + fullRepresentation (Dashboard)
  Dashboard.qml       # TabBar + SwipeView con las 4 tabs; define tamaño del popup
  tabs/
    DashboardTab.qml    # Weather + User(avatar) / Reloj + Calendario + Recursos / Media (grilla)
    MediaTab.qml        # Reproductor grande (ver abajo)
    PerformanceTab.qml  # CPU/GPU hero + Memoria/Disco/Red/Batería
    WorkspacesTab.qml   # Escritorios virtuales + ventanas
  components/
    Card.qml            # Tarjeta base: fondo gris translúcido, sin borde, radius configurable
    CircularProgress.qml# Anillo (Canvas) con startAngle/sweepAngle/value
    VerticalMeter.qml   # Barra vertical tipo píldora (CPU/RAM/VOL)
    CalendarGrid.qml    # Calendario propio (grilla Lun–Dom, hoy en círculo, header con fecha)
    WeatherCard.qml     # Clima vía wttr.in
    UserCard.qml        # Avatar (OpacityMask) + distro/WM/uptime
    MediaCard.qml       # Reproductor compacto (usado en DashboardTab)
    Marquee.qml         # Texto con ticker infinito si no entra (velocidad constante)
    SeekBar.qml         # Barra negra arrastrable 0..1, señal seek(frac); Behavior fluido
    Lyrics.qml          # Letras sincronizadas (lrclib.net) + fallback a plana
    DancingCats.qml     # Gatos bailando random de assets/cats (modos: big/party/none)
    Visualizer.qml      # Barras decorativas (actualmente sin uso)
  assets/
    avatar.png          # foto de perfil del usuario
    bongocat.gif, blackcat.gif
    cats/cat1..cat32.gif# gifs de gatos bailando (DancingCats los lista con FolderListModel)
```

## Convenciones de estilo (IMPORTANTE, mantener consistencia)

- **Acento = negro:** todo lo "activo/relleno" usa `Kirigami.Theme.textColor` (no el
  highlight/teal del tema). Barras CPU/RAM/VOL, reloj, anillos, progreso, día actual,
  workspace activo, etc.
- **Cards:** usar el componente `Card` (fondo `textColor` a 0.1 alpha, sin borde).
  Radius de cards ≈ `Kirigami.Units.cornerRadius * 1.6`.
- **Radios concéntricos:** para elementos anidados usar `radio_exterior = radio_interior + padding`
  (equivalente: `radio_interior = radio_card − padding`, con piso en `cornerRadius`).
  Ya aplicado a: thumbnail del media, foto de usuario, barra de controles del media.
- **Pesos de fuente:** énfasis = `Font.DemiBold`; texto secundario = `Font.Medium`; cuerpo = Normal.
- **Números que cambian seguido** (timeline): `font.features: { "tnum": 1 }` (tabulares).
- **Popup:** tamaño en `Dashboard.qml` = `38 × 20` gridUnits (pantalla del usuario:
  1366×768, escala 1, `gridUnit ≈ 18px`).

## Cómo previsualizar y aplicar

- **Aplicar al panel (recargar el widget):** hay que **matar y relanzar plasmashell**
  (no basta re-agregar el widget; Plasma cachea el QML por sesión). `systemctl --user
  restart plasma-plasmashell` NO funciona en esta máquina (plasmashell no lo maneja el unit).
  Usar:
  ```
  kquitapp6 plasmashell; sleep 1.5; cd /home/marki; setsid plasmashell >/dev/null 2>&1 < /dev/null & disown
  ```
- **Preview aislado sin tocar el panel:** `plasmawindowed org.marki.dashboard`.
  - Muestra la representación **compacta** (reloj). Para ver una tab: forzar
    `preferredRepresentation: fullRepresentation` en `main.qml` (revertir después) y,
    para abrir una tab específica, insertar temporalmente
    `Component.onCompleted: currentIndex = N` en el `SwipeView` de `Dashboard.qml`
    (0=Dashboard,1=Media,2=Performance,3=Workspaces). **Revertir con `sed`, NO con `cp`**
    (el `cp` es interactivo/alias y cuelga el comando).
  - Capturar: `spectacle -b -n -f -o <archivo>.png`. Ojo: a veces captura el terminal si
    el popup queda atrás; `plasmawindowed` fija el tamaño al abrir (no sirve para probar
    resize dinámico del popup).
- **Lint de sintaxis:** `qmllint <archivo>.qml 2>&1 | grep -iE "error|:[0-9]+:[0-9]+" | grep -viE "module|import|not found|Failed"` (los warnings de imports de Plasma son falsos positivos).

## Fuentes de datos

- **Sensores:** `org.kde.ksysguard.sensors` (cpu/all/usage, cpu/all/averageTemperature,
  memory/physical/usedPercent|used|total, network/all/download|upload).
- **GPU (AMD Renoir):** `/sys/class/drm/card*/device/gpu_busy_percent` y hwmon `amdgpu` temp1_input.
- **Disco:** `df -B1 --output=used,size,pcent / | tail -1` (el `--output` imprime header → usar `tail -1`).
- **Batería:** `/sys/class/power_supply/BAT0/{capacity,status}` (es laptop).
- **Media (MPRIS):** `playerctl -p playerctld ...` para seguir siempre el **player activo**.
  Metadata en un solo call con separador `␄` (status/title/artist/album/artUrl/length/playerName).
  Volumen/shuffle/loop son subcomandos aparte; posición con `position`.
- **Letras:** `lrclib.net` — `GET /api/get` (por duración exacta) con fallback a
  `GET /api/search`; usa `syncedLyrics` o `plainLyrics`.
- **Clima:** `curl 'wttr.in/?format=%t|%C'`.
- **Exec:** todo lo de shell va por `P5Support.DataSource { engine: "executable" }`;
  distinguir la respuesta por substring/endsWith del `source`.

## Gotchas aprendidos (no repetir errores)

- **`clip: true` NO recorta al radius**, solo al rectángulo. Para imágenes redondeadas
  usar `OpacityMask` (`Qt5Compat.GraphicalEffects`) con una máscara Rectangle+radius.
  Ver `UserCard.qml`, `MediaCard.qml`, `MediaTab.qml`.
- **`Kirigami.Avatar` NO existe** en este Kirigami. Usar OpacityMask.
- **Alto del popup por tab NO se puede** de forma confiable: el popup se dimensiona a la
  tab **más alta** (el `SwipeView` mantiene todas cargadas) y Plasma no redimensiona el
  applet en vivo. Se dejó alto fijo (20u). `Behavior on Layout.preferredHeight` (attached)
  tampoco anima; usar propiedad normal + bind.
- **`playerctl -p playerctld ... {{playerName}}` devuelve "playerctld"** (el proxy), no la
  app real. Para el nombre de app derivar de la lista `playerctl -l` (id → "chromium", etc.).
- **QQC2.Menu con estilo Plasma no renderiza bien el texto** de items dinámicos → se hizo un
  **dropdown propio** (Rectangle + ColumnLayout + Repeater) en `MediaTab.qml`.
  Además `root.appName(modelData)` en el binding del delegate no resolvía; se computa **inline**.
- **En delegates de Repeater sobre array JS**, preferir `required property int index` +
  `root.array[index]` (más confiable que `modelData` con componentes custom).
- **`echo` para separar líneas en bundles de exec** mete líneas vacías y desalinea el parseo
  (rompió temp de GPU / estado de batería). Encadenar `cat a; cat b` sin `echo`.
- **`Fila superior "se come" el alto`** en ColumnLayouts: si una fila tiene `preferredHeight`
  y otra `fillHeight`, a veces la de arriba crece igual → fijar `Layout.maximumHeight`
  en la de arriba (ver DashboardTab hero row, PerformanceTab).
- **Math.random() SÍ funciona** en QML del plasmoid (solo está bloqueado en scripts de workflow).

## Estado por tab

- **Dashboard:** grilla estilo caelestia (Weather, User+avatar, Reloj vertical `hh ••• mm`,
  CalendarGrid con fecha completa + hoy en círculo negro, Recursos, MediaCard).
- **Media:** gatos de fondo (default **1 big catto**), thumbnail cuadrado (izq) con controles
  overlay + timeline + volumen; título/artista·álbum + **letra sincronizada** (der); menú ☰
  arriba-derecha con selector de player + modos de gato.
- **Performance:** CPU y GPU hero (uso + temp), Memoria/Disco (anillos 270°), Red (sparkline),
  Batería (anillo). Todo con acento negro.
- **Workspaces:** un Card por escritorio virtual (borde negro = activo) con lista de ventanas.

## Flujo de trabajo típico

1. Editar QML en `~/.local/share/plasma/plasmoids/org.marki.dashboard/contents/ui/`.
2. `qmllint` para chequear sintaxis.
3. (Opcional) preview con `plasmawindowed` forzando full rep + tab (revertir con `sed`).
4. Aplicar con `kquitapp6 plasmashell` + relanzar.
5. Commit + push (`git add -A && git commit && git push`). Firmar co-autoría de Claude.
