# Acceso móvil y revisión grabada en Windows + WSL

Cada PC ejecuta su propio OpenCode en WSL. El teléfono retoma las sesiones de
ese PC: no se comparten repositorios, sesiones, credenciales ni evidencias
entre equipos. Tailscale va en **Windows y Android**; OpenCode, Chromium y las
herramientas de captura van en **WSL**.

Usa OpenCode Web para el chat y **Firefox para Android** para abrir noVNC.
noVNC controla el Chromium de WSL que `agent-browser` graba. No hace falta
instalar OpenCode en el teléfono.

## 0. Preparar Windows + WSL

Si el PC aún no tiene una distro, abre PowerShell como administrador y
[instala WSL](https://learn.microsoft.com/en-us/windows/wsl/install). Esta
guía usa Ubuntu 24.04 en WSL 2:

```powershell
wsl --install -d Ubuntu-24.04
```

Reinicia si Windows lo solicita, abre Ubuntu y crea tu usuario de Linux.
Con `wsl -l -v` en PowerShell, comprueba que la distro indica `VERSION 2`.
Si ya tienes Ubuntu 24.04 en WSL 2, no hace falta reinstalarla.

## 1. Entrar a OpenCode Web

1. En WSL, [instala OpenCode V2, tu configuración y las skills](../README.md#configurar-opencode).
   Abre OpenCode normalmente en tu repo, **sin `--standalone`**. Ejecuta
   `opencode service status` en WSL y anota el puerto del servicio compartido;
   no asumas que será el mismo en otra instalación.
2. Instala [Tailscale en Windows](https://tailscale.com/download/windows) y en
   [Android](https://play.google.com/store/apps/details?id=com.tailscale.ipn).
   Conecta ambos a la misma red. En PowerShell define `$puertoOpenCode` con el
   puerto que anotaste. Verifica que Windows llegue por loopback y que el
   puerto HTTPS 443 de Serve no esté ocupado por otro servicio:

   ```powershell
   $puertoOpenCode = [int](Read-Host 'Puerto de opencode service status')
   curl.exe --max-time 5 -I "http://127.0.0.1:$puertoOpenCode/"
   tailscale serve status
   ```

   Si `localhost` no responde, revisa primero el
   [reenvío de WSL](https://learn.microsoft.com/en-us/windows/wsl/networking).
   No cambies OpenCode a `0.0.0.0` para resolverlo.
3. Revisa qué dispositivos pueden llegar al TCP 443 de este PC en la política
   de Tailscale y limita el acceso a los que realmente usarán OpenCode. Desde
   esa misma ventana de PowerShell, publica **solo dentro de Tailscale**:

   ```powershell
   tailscale serve --bg --https=443 "http://127.0.0.1:$puertoOpenCode"
   tailscale serve status
   ```

   Si pide habilitar HTTPS, sigue el aviso de Tailscale. Confirma que la ruta
   recién creada dice `tailnet only` y apunta al puerto local de OpenCode. Si
   no puedes confirmarlo, ejecuta `tailscale serve --https=443 off` y no sigas
   con el emparejamiento. No uses Funnel, OpenTunnel ni un reenvío en el router.
4. Usa la URL HTTPS que imprimió Serve. En WSL genera el emparejamiento:

   ```bash
   read -r -p 'URL HTTPS de OpenCode (sin barra final): ' url_opencode
   opencode pair --url "$url_opencode"
   ```

   Abre la URL base en el teléfono y usa **Escanee el código QR** dentro de
   OpenCode; el lector normal de Android puede mostrar JSON. Otra opción es
   pegar el enlace completo `/auth/connect/...` que imprime la terminal
   directamente en la barra del navegador. Es de un solo uso y caduca en cinco
   minutos. No compartas el enlace ni el QR. No hay que instalar OpenCode Web.

Comprueba desde el teléfono con Wi-Fi apagado que puedes abrir la misma sesión
de la terminal. Abre también la URL en una ventana privada **sin emparejarla**:
debe pedir autenticación y no mostrar ni permitir controlar sesiones. Si
permite ver o controlar sesiones, desactiva de inmediato el acceso remoto con
`tailscale serve --https=443 off` y corrige la autenticación antes de reabrirlo.
El PC debe seguir encendido, despierto y conectado. Antes de depender del
acceso durante una ausencia, prueba cerrar la terminal y bloquear Windows sin
suspenderlo: [systemd por sí solo no mantiene vivo WSL](https://learn.microsoft.com/en-us/windows/wsl/systemd).

## 2. Preparar la app y su navegador de revisión

Levanta la app en el equipo elegido. `agent-browser` necesita poder abrirla
desde WSL; el teléfono **no** necesita acceso directo a la app para esta
revisión. Con Docker Compose, consulta `docker compose ps` y, si hace falta
publicar el puerto al host, prefiere loopback. Por ejemplo, en un servicio web
que escucha en el puerto 3000 dentro del contenedor:

```yaml
ports:
  - "127.0.0.1:3000:3000"
```

El servidor del contenedor debe escuchar en una interfaz alcanzable dentro de
él (normalmente `0.0.0.0`). Verifica desde WSL la URL publicada, tanto si usas
Docker Desktop con integración WSL como si usas Docker Engine en la distro.
No publiques la app, la base de datos ni el socket de Docker en Tailscale para
la revisión grabada.

En WSL, instala [`agent-browser`](https://agent-browser.dev/installation).
Descarga su Chromium e instala las dependencias de Linux; después comprueba
el navegador y la grabación:

```bash
sudo apt update
sudo apt install ffmpeg tigervnc-standalone-server openbox websockify
agent-browser install --with-deps
agent-browser doctor
```

Descarga el archivo **Source code** de [noVNC 1.7.0](https://github.com/novnc/noVNC/releases/tag/v1.7.0)
y descomprímelo en WSL, fuera del repo. Usa la ruta absoluta del directorio
que contiene `vnc.html`.

### Abrir un escritorio dedicado

En WSL, elige un display libre (el ejemplo usa `:77`). No compartas el
escritorio normal de Windows o WSLg. En una terminal, crea un directorio
privado y una credencial X11 local. Copia la ruta que imprime `mktemp` para las
otras terminales. No hay contraseña VNC: el acceso remoto depende de la
política por dispositivo de Tailscale. El socket VNC no escucha por TCP.

```bash
umask 077
revision=$(mktemp -d "$HOME/.opencode-review.XXXXXXXX")
printf 'Directorio de revisión: %s\n' "$revision"
touch "$revision/Xauthority"
xauth -f "$revision/Xauthority" add :77 MIT-MAGIC-COOKIE-1 "$(openssl rand -hex 16)"
Xtigervnc :77 -geometry 540x960 -depth 24 -nolisten tcp \
  -auth "$revision/Xauthority" -rfbport -1 \
  -rfbunixpath "$revision/rfb.sock" -rfbunixmode 0600 \
  -SecurityTypes None \
  -AcceptCutText=0 -SendCutText=0
```

En una segunda terminal, define `revision` con esa misma ruta. Arranca
Openbox sin atajos de teclado ni menú de escritorio, en el display dedicado:

```bash
read -r -p 'Directorio de revisión: ' revision
cat > "$revision/openbox.xml" <<'XML'
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <desktops><number>1</number></desktops>
  <keyboard/>
  <mouse/>
  <applications>
    <application class="*"><fullscreen>yes</fullscreen><decor>no</decor></application>
  </applications>
</openbox_config>
XML
DISPLAY=:77 XAUTHORITY="$revision/Xauthority" openbox --config-file "$revision/openbox.xml"
```

En una tercera terminal, sirve solo los archivos de noVNC en loopback. No
sirvas el directorio privado que contiene `Xauthority` y el socket. Usa el
mismo nombre HTTPS de OpenCode, con el puerto `8443` y sin barra final, para
rechazar conexiones WebSocket iniciadas desde otros sitios. El origen no
autentica al teléfono: eso lo hace la política de Tailscale.

```bash
read -r -p 'Directorio de revisión: ' revision
read -r -p 'Directorio de noVNC (contiene vnc.html): ' novnc_web
read -r -p 'Origen HTTPS de noVNC (incluye :8443, sin barra final): ' origen_novnc
websockify --web="$novnc_web" --auth-plugin ExpectOrigin --auth-source "$origen_novnc" \
  --unix-target="$revision/rfb.sock" 127.0.0.1:6081
```

### Iniciar la captura y compartir el acceso temporal

En el OpenCode del proyecto, pide una
[revisión narrada](../skills/narrated-browser-review/SKILL.md) desde el móvil.
Al iniciar el escritorio dedicado, indica una vez en esa conversación la URL
local de la app y cómo encontrar ese escritorio. Por ejemplo: «Inicia una
revisión narrada desde el móvil de `<URL local>`. El display de noVNC es `:77`,
su directorio de revisión es `<ruta absoluta>` y su origen es `<URL HTTPS
con :8443>`». Comparte rutas, no el contenido de `Xauthority`.

El agente arranca **una sesión nueva y nombrada** en ese display, sin iniciar
el dashboard. Ejemplo (`revision` es el directorio anterior, `timeline` la
ruta al script de la skill y `review_session` un nombre nuevo):

```bash
env -u WAYLAND_DISPLAY DISPLAY=:77 XAUTHORITY="$revision/Xauthority" \
  agent-browser --session "$review_session" --headed \
  --args '--ozone-platform=x11,--kiosk,--no-first-run' \
  open --init-script "$timeline" about:blank
```

La skill abre la app en esa sesión y guarda video, interacciones y diagnósticos
localmente. Comprueba el desplazamiento en el video o la traza: el script base
del registro no guarda eventos de scroll por separado. Usa datos ficticios:
el video y el registro pueden incluir texto introducido, incluso si no se
envía al servidor. No reutilices un perfil
personal; un escritorio dedicado no es una barrera de seguridad del sistema.

**Antes de publicar el puerto de revisión**, limita TCP 8443 de este PC a la
IP de Tailscale del teléfono, no a su cuenta (que puede tener otros equipos).
En [Access controls](https://console.tailscale.com/admin/acls), integra este
ejemplo con tu política, **sin reemplazarla**. Cambia las IP de ejemplo por
las de los equipos; para `otro-cliente-prueba` usa otra IP distinta a la del
teléfono. Si usas IPv6, agrega alias y pruebas equivalentes para esa familia.

```json
{
  "hosts": {
    "telefono-revision": "100.64.0.10",
    "pc-revision": "100.64.0.20",
    "otro-cliente-prueba": "100.64.0.30"
  },
  "grants": [
    { "src": ["telefono-revision"], "dst": ["pc-revision"], "ip": ["tcp:8443"] }
  ],
  "tests": [
    { "src": "telefono-revision", "proto": "tcp", "accept": ["pc-revision:8443"] },
    { "src": "otro-cliente-prueba", "proto": "tcp", "deny": ["pc-revision:8443"] }
  ]
}
```

Tailscale ejecuta estas [pruebas de política](https://tailscale.com/docs/reference/syntax/policy-file#tests)
al guardar, aunque no tengas otro cliente conectado. Verifica ambas familias
de direcciones si el equipo tiene IPv4 e IPv6 en Tailscale. Las reglas son aditivas:
revisa también que no exista una regla amplia que abra ese puerto a otros
dispositivos. Si no puedes verificar el acceso exclusivo del teléfono, no
publiques 8443. La política de Tailscale es el control de acceso remoto, no
una contraseña VNC. Comparte la sesión solo con un operador de confianza y
úsala en un PC de confianza: los procesos locales que alcancen el proxy
quedan fuera de esa protección de red.

Si el puerto 8443 está libre, las pruebas de política pasan y el proxy exige
el origen HTTPS exacto, el agente habilita Serve desde Windows (por ejemplo,
mediante la interoperabilidad de WSL). Si no puede ejecutar comandos en
Windows, el operador los ejecuta en PowerShell y confirma el resultado al
agente. Solo publica si está claro quién lo abrirá y lo cerrará:

```powershell
curl.exe --max-time 5 -I http://127.0.0.1:6081/vnc.html
tailscale serve --bg --https=8443 http://127.0.0.1:6081
tailscale serve status
```

Con la grabación lista, el agente verifica (o recibe confirmación de) que
`serve status` muestra `tailnet only` y el proxy correcto en 8443. Verifica
también desde otro dispositivo si está disponible: debe quedar bloqueado.
Si el estado no es el esperado o falla una restricción, cierra 8443 y no
entregues el enlace. Si pasa, el agente envía en el mismo chat la URL de Serve
con `/vnc.html?autoconnect=1&resize=scale` al final. Ábrela en **Firefox para
Android** con Tailscale conectado: no pide contraseña VNC ni requiere un QR.
Usa un toque para seleccionar, dos dedos para desplazar y el icono de teclado
de noVNC para escribir. Para probar el motor nativo del teléfono, abre la app
directamente cuando esté accesible; esa interacción no queda en la captura
de Chromium en WSL.

## 3. Verificar y cerrar

1. Desde Android, abre la conversación de OpenCode y la sesión de noVNC. Toca,
   desplaza, escribe y envía un formulario con datos ficticios. Vuelve al chat y
   escribe **«terminé»**. El agente comprueba el video y el registro sin que
   tengas que reconstruir lo que hiciste. Terminar la prueba no equivale a
   aprobar el incremento.
2. Cuando acaba el control manual, también si se cancela o falla la captura,
   detén el `websockify` de la revisión con `Ctrl+C` en su terminal y comprueba
   que ya no escucha en `127.0.0.1:6081`. Así se corta el control ya conectado
   sin cerrar Chromium. El agente retira la ruta de Serve desde Windows; si
   no puede, el operador designado ejecuta los comandos en PowerShell y
   confirma que 8443 ya no aparece. Haz ambas cosas antes de diagnosticar o
   repetir acciones. Conserva las evidencias y comprueba que OpenCode sigue
   disponible:

   ```powershell
   tailscale serve --https=8443 off
   tailscale serve status
   ```

3. Cierra la sesión nombrada de Chromium y detén Openbox y TigerVNC con
   `Ctrl+C` en sus terminales. Retira las credenciales temporales
   una vez cerrada la sesión; no borres el directorio de evidencias.

El TCP 443 queda activo para el chat. Si ya no necesitas acceso remoto a
OpenCode, ejecuta `tailscale serve --https=443 off` en PowerShell (si ese
puerto se dedicó a OpenCode). Esto no detiene el servicio local de WSL.

Para verificar la instalación, elige cualquier app local adecuada y usa datos
ficticios. Comprueba que puedes retomar la conversación, que solo el teléfono
autorizado puede controlar la revisión, que toque, scroll y escritura quedan
registrados, y que el puerto 8443 se cierra al terminar. Los avisos push quedan
fuera de esta guía.
