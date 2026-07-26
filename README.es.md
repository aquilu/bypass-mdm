# Bypass MDM para macOS 💻

[🇬🇧 English](README.md) | **🇪🇸 Español**

![mdm-screen](https://raw.githubusercontent.com/aquilu/bypass-mdm/main/mdm-screen.png)

Un script para saltar la inscripción de Mobile Device Management (MDM) durante la configuración de macOS.

## 🚨 Actualización: 3 de febrero de 2026

**¡Versión 2 disponible!** Debido a la gran cantidad de solicitudes y a los problemas reportados de forma repetida, publiqué una nueva versión del script con mejoras importantes:

### Novedades en v2:

- **Detección automática de volúmenes** - Ya no requiere nombres específicos como "Macintosh HD"
- **Manejo integral de errores** - Mensajes de error claros y validación en cada paso
- **Validación de entrada** - Valida nombres de usuario y contraseñas para evitar errores comunes
- **Detección de conflictos de UID** - Encuentra automáticamente UIDs disponibles para evitar conflictos
- **Mejor experiencia de usuario** - Salida con colores, indicadores de progreso y mensajes útiles

Las instrucciones de abajo usan **v2 por defecto** (recomendado). Si tienes problemas, puedes usar la versión original reemplazando `bypass-mdm-v2.sh` por `bypass-mdm.sh` en los comandos.

---

## 🚨 Actualización: 26 de julio de 2026

**v2 reforzada para Apple Silicon y macOS moderno (hasta macOS 26 "Tahoe").** Basado en el trabajo comunitario del PR upstream #170, `bypass-mdm-v2.sh` ahora apunta correctamente al **volumen de datos** y sobrevive a las actualizaciones del sistema:

### Novedades

- **Corrección del volumen de sistema sellado (SSV)** — En Apple Silicon el sistema arranca desde una instantánea (snapshot) de solo lectura y sellada. El `/etc/hosts` y `ConfigurationProfiles` reales viven en el **volumen de datos** (vía el firmlink `/private`). Ahora v2 escribe todo ahí, así que el bloqueo sí surte efecto.
- **Compatibilidad con FileVault** — Encuentra el volumen de datos por **rol APFS** (no por nombre) y lo desbloquea con `diskutil apfs unlockVolume`. Corrige el fallo "Could not detect data volume" en Macs con FileVault activado por defecto.
- **Bloqueo duradero del daemon de inscripción** — Escribe un override de launchd en el volumen de datos que deshabilita `com.apple.ManagedClient.enroll` (macOS 26 reemplazó `cloudconfigurationd`). Sobrevive al resellado del volumen de sistema que hace una actualización de macOS, así que el aviso de inscripción no regresa tras actualizar.
- **Bloqueo de dominios más inteligente** — Lee el host MDM propio de la organización desde el registro DEP y también lo bloquea, agrega `acmdm.apple.com` y bloquea IPv6 además de IPv4, dejando a propósito `gdmf.apple.com` y `albert.apple.com` sin bloquear para que Software Update e iMessage/FaceTime sigan funcionando.
- **Nuevo `bypass-mdm-v3.sh`** — Una variante independiente de dos modos (solo suprimir, para un Mac ya configurado, o bypass completo, para un Setup Assistant atascado) con el mismo refuerzo SSV / FileVault / daemon.

> **Nota:** Esto sigue siendo supresión **local**. El número de serie de tu equipo sigue en el inventario de Apple Business/School Manager (DEP) de la organización y puede reaparecer tras un restablecimiento de fábrica o una reactivación mayor. Nunca ejecutes `profiles renew` ni "Borrar todo el contenido y los ajustes".

---

## 🧭 ¿Cuál uso?

Tres scripts, tres situaciones:

| Tu situación | Usa | Qué hace |
| --- | --- | --- |
| Mac **atascado** en la pantalla de inscripción MDM / Administración Remota | **`bypass-mdm-v2.sh`** (recomendado) | Crea un admin temporal, salta el Setup Assistant, bloquea la inscripción y limpia el registro DEP |
| Igual que arriba, pero el Mac tiene **FileVault**, es un Apple Silicon reciente / macOS 26, o quieres un modo solo-supresión | **`bypass-mdm-v3.sh`** (avanzado, pendiente de prueba real) | Todo lo de v2, más detección por rol APFS, desbloqueo de FileVault y dos modos |
| Mac **ya configurado y funcionando**, pero el aviso de inscripción **parpadea un segundo en cada arranque** | **`clear-dep-record-v2.sh`** | Solo elimina el registro DEP residual y coloca los marcadores de bypass — no crea usuarios, no edita `hosts`, no borra nada |
| Mac antiguo donde la autodetección falla y conoces los nombres exactos de los volúmenes | **`bypass-mdm.sh`** (legacy) | Script original con nombres de volumen fijos |

**En una línea cada uno:**

- **v2** — "sácame de la pantalla de inscripción atascada". La opción por defecto.
- **v3** — "lo mismo, pero reforzado" (FileVault, macOS 26, dos modos). Aún sin prueba real.
- **clear** — "solo quita el parpadeo al arrancar" en un Mac que ya funciona. El más suave.

> ⚠️ **Todos son supresión _local_.** El número de serie de tu Mac sigue en el
> inventario de Apple Business/School Manager (DEP) de la organización y puede
> reaparecer tras un restablecimiento de fábrica o una reactivación contra Apple.
> La solución permanente es que la organización dueña libere el serial.

---

## ✨ Características

- **🔍 Detección inteligente de volúmenes** - Detecta automáticamente los volúmenes de sistema y datos sin importar nombres personalizados
- **✅ Validación de entrada** - Valida nombres de usuario y contraseñas para evitar errores comunes
- **🛡️ Manejo integral de errores** - Mensajes de error claros que te guían ante cualquier problema
- **🎯 Resolución de conflictos de UID** - Encuentra automáticamente IDs de usuario disponibles para evitar conflictos
- **📊 Progreso en tiempo real** - Mensajes de estado con colores que muestran exactamente qué está pasando
- **🔄 Prevención de duplicados** - Verifica entradas existentes para evitar duplicados
- **🍎 Consciente de Apple Silicon / SSV** - Escribe en el volumen de datos (vía `/private`) para que los cambios lleguen al SO en Macs con volumen de sistema sellado
- **🔓 Compatibilidad con FileVault** - Localiza el volumen de datos por rol APFS y lo desbloquea con `diskutil apfs unlockVolume`
- **🧱 Bloqueo de inscripción duradero** - Deshabilita el daemon de inscripción vía override de launchd en el volumen de datos, sobreviviendo a actualizaciones de macOS
- **🌐 Bloqueo de dominios más inteligente** - Bloquea el host MDM de la organización + IPv6, dejando `gdmf`/`albert` intactos (mantiene Software Update e iMessage funcionando)

## ⚠️ Requisitos previos

- **Se recomienda encarecidamente borrar el disco duro antes de empezar**
- **Se recomienda reinstalar macOS usando una unidad flash externa**
- **Se recomienda el idioma inglés** (no es obligatorio para v2, pero se recomienda)

## 📋 Instalación y uso

### Instrucciones paso a paso

Sigue estos pasos para saltar la inscripción MDM durante una instalación limpia de macOS:

> **Punto de partida:** Has llegado a la pantalla de inscripción MDM durante la configuración de macOS

**1.** **Apagado forzado** - Mantén presionado el botón de encendido para apagar tu Mac

**2.** **Arranca en modo Recovery:**

- **Mac con Apple Silicon**: Mantén el botón de encendido hasta que aparezca "Cargando opciones de arranque"
- **Mac con Intel**: Mantén <kbd>CMD</kbd> + <kbd>R</kbd> durante el arranque

**3.** **Conéctate al WiFi** para activar tu Mac

**4.** **Abre la Terminal** en modo Recovery:

- Haz clic en **Utilidades** en la barra de menú
- Selecciona **Terminal**

**5.** **Ejecuta el script de bypass** - Copia y pega este comando en la Terminal:

```bash
curl -L https://raw.githubusercontent.com/aquilu/bypass-mdm/main/bypass-mdm-v2.sh -o bypass-mdm.sh && chmod +x ./bypass-mdm.sh && ./bypass-mdm.sh
```

**6.** **Detección de volúmenes** - El script detectará automáticamente tus volúmenes:

- Volumen de sistema (p. ej. "Macintosh HD", "MacOS" o tu nombre personalizado)
- Volumen de datos (p. ej. "Data", "Macintosh HD - Data" o tu nombre personalizado)

**7.** **Selecciona la opción 1** - "Bypass MDM from Recovery"

**8.** **Crea un usuario temporal** - Configura la cuenta de administrador (o presiona Enter para los valores por defecto):

- **Nombre completo**: Apple (por defecto)
- **Usuario**: Apple (por defecto)
- **Contraseña**: 1234 (por defecto)

> 💡 **Consejo:** El script valida tu entrada y te pedirá reintentar si hay problemas

**9.** **Espera a que termine** - Verás mensajes de progreso:

- ✓ Validando rutas del sistema
- ✓ Creando la cuenta de usuario
- ✓ Bloqueando dominios MDM
- ✓ Configurando los ajustes de bypass MDM

**10.** **Reinicia** - Cuando veas "MDM Bypass Completed Successfully", cierra la Terminal y reinicia

---

### 🔄 Pasos posteriores a la instalación

**11.** **Inicia sesión** con la cuenta temporal:

- Usuario: `Apple` (o tu usuario personalizado)
- Contraseña: `1234` (o tu contraseña personalizada)

**12.** **Salta la configuración** - Salta todos los diálogos (Apple ID, Siri, Touch ID, Localización)

**13.** **Crea tu cuenta real:**

- Ve a **Ajustes del Sistema > Usuarios y Grupos**
- Crea tu cuenta de administrador real con las credenciales que prefieras

**14.** **Cambia de cuenta** - Cierra sesión e inicia sesión en tu nueva cuenta

**15.** **Configura correctamente** - Ahora configura Apple ID, Siri, Touch ID, etc.

**16.** **Limpieza** - Elimina el perfil temporal "Apple":

- Ve a **Ajustes del Sistema > Usuarios y Grupos**
- Selecciona el perfil "Apple" y haz clic en el botón menos (−)

**17.** **🎉 ¡Listo!** ¡Estás libre de MDM!

---

## 🔧 Solución de problemas

### Problemas de detección de volúmenes

**Problema:** El script no detecta los volúmenes

**Soluciones:**

- Asegúrate de estar en modo Recovery (no arrancado en macOS normalmente)
- Verifica que macOS esté instalado en tu disco
- Comprueba que tu disco sea visible en Utilidad de Discos
- Prueba la versión original (legacy, nombres de volumen fijos):

```bash
curl -L https://raw.githubusercontent.com/aquilu/bypass-mdm/main/bypass-mdm.sh -o bypass-mdm.sh && chmod +x ./bypass-mdm.sh && ./bypass-mdm.sh
```

### Errores de permisos

**Problema:** Errores de permiso denegado

**Soluciones:**

- Confirma que estás ejecutando desde la Terminal en modo Recovery
- El modo Recovery otorga privilegios elevados automáticamente
- Asegúrate de que el script sea ejecutable: `chmod +x bypass-mdm.sh`

### El script no se ejecuta

**Problema:** El script no corre

**Soluciones:**

```bash
# Asegúrate de que sea ejecutable
chmod +x bypass-mdm.sh

# Ejecútalo de nuevo
./bypass-mdm.sh
```

### Usuario o contraseña inválidos

**Problema:** El script rechaza tu usuario/contraseña

**Reglas de validación:**

- **Usuario:** Solo letras, números, guion bajo y guion; debe empezar con letra o guion bajo
- **Contraseña:** Mínimo 4 caracteres
- Presiona Enter para usar los valores por defecto si no estás seguro

---

## 🩹 Complemento: Limpiar un registro DEP residual (`clear-dep-record-v2.sh`)

**Úsalo cuando:** tu Mac ya terminó el Setup Assistant y funciona con normalidad
(ya tienes una cuenta de administrador local), pero el aviso de Inscripción de
Dispositivos / MDM sigue **parpadeando unos segundos en cada arranque**. Eso
ocurre cuando el equipo aún conserva un registro de activación DEP real en el
volumen de datos (`.cloudConfigHasActivationRecord` / `.cloudConfigRecordFound`).

Este **no** es el caso de "atascado en la pantalla de inscripción" — para eso usa
`bypass-mdm-v2.sh`.

**Qué hace:** trabajando solo en el **volumen de datos**, elimina los registros de
activación residuales, borra el archivo de aviso (nag) de DEP y escribe los
marcadores de bypass (`.cloudConfigProfileInstalled` / `.cloudConfigRecordNotFound`).

**Qué NO hace:** no crea usuarios, no edita `/etc/hosts` y no borra ni reinstala
nada. No hace falta formatear el disco.

### Requisitos

- **Arranca en Recovery** — obligatorio. Con macOS en ejecución, SIP protege
  `/var/db/ConfigurationProfiles` y los cambios fallarán.
- Si **FileVault** está activado, desbloquea/monta primero el volumen de datos
  (`diskutil apfs unlockVolume <disco>`).

### Uso

Desde la Terminal en modo Recovery:

```bash
curl -L https://raw.githubusercontent.com/aquilu/bypass-mdm/main/clear-dep-record-v2.sh -o clear-dep-record.sh && chmod +x ./clear-dep-record.sh && ./clear-dep-record.sh
```

El script autodetecta tus volúmenes, muestra los registros de activación actuales,
pide confirmación, los limpia y escribe los marcadores de bypass. Reinicia cuando
termine.

> **Nota:** esto limpia solo el registro **local**. El dispositivo sigue
> apareciendo en el inventario de Apple Business/School Manager (DEP) de la
> organización. Si el Mac se borra y se reactiva contra Apple, el registro DEP vuelve.

---

## 🚀 Avanzado: `bypass-mdm-v3.sh` (dos modos, reforzado SSV / FileVault / daemon)

> ⚠️ **Estado de prueba en campo:** v3 pasa las verificaciones de sintaxis y la
> revisión de código, pero está **pendiente de verificación en el mundo real** en
> hardware afectado. Prefiere `bypass-mdm-v2.sh` salvo que necesites específicamente
> las funciones de v3 y puedas probarlo en un dispositivo propio.

Una reescritura independiente reforzada para Apple Silicon + Volumen de Sistema
Sellado (macOS 11 Big Sur hasta macOS 26 "Tahoe"). Comparte un mismo núcleo de
supresión de inscripción en **dos modos**:

- **Solo suprimir inscripción** — para un Mac que *ya está configurado* y solo te
  molesta para inscribirte. **No** crea ningún usuario; tus cuentas y datos quedan intactos.
- **Bypass completo** — para un Mac *atascado en la pantalla de Administración Remota /
  Setup Assistant*. Crea un administrador local temporal + `.AppleSetupDone`, y luego suprime.

### Qué añade sobre v2

- Localiza el volumen de datos por **rol APFS** y desbloquea FileVault automáticamente
- Lee el host MDM propio de la organización desde el registro DEP y lo bloquea (más IPv6)
- Deshabilita el daemon de inscripción (`com.apple.ManagedClient.enroll`) vía un override
  de launchd en el volumen de datos — sobrevive a actualizaciones de macOS
- Una opción de menú **"Verify current state"** para inspeccionar marcadores / hosts / override

### Requisitos

- **Arranca en Recovery** (Apple Silicon: mantén Encendido → Opciones → Utilidades → Terminal)
- Si FileVault está activo, el script te pedirá desbloquear el volumen de datos

### Uso

Desde la Terminal en modo Recovery:

```bash
curl -L https://raw.githubusercontent.com/aquilu/bypass-mdm/main/bypass-mdm-v3.sh -o bypass-mdm-v3.sh && chmod +x ./bypass-mdm-v3.sh && ./bypass-mdm-v3.sh
```

> **Nota:** Como todas las versiones, esto es supresión **local** únicamente — el
> dispositivo sigue en el inventario DEP de la organización. Nunca ejecutes
> `profiles renew` ni "Borrar todo el contenido y los ajustes", que rearman DEP.

---

## 📦 Información de versiones

| Versión            | Descripción                                       | Estado             |
| ------------------ | ------------------------------------------------- | ------------------ |
| `bypass-mdm-v2.sh` | Reforzada: consciente de SSV/volumen de datos, desbloqueo de FileVault, bloqueo de daemon duradero, lista de dominios inteligente | ✅ **Recomendada** |
| `bypass-mdm-v3.sh` | Dos modos (solo-supresión / bypass completo), detección por rol APFS, macOS 11–26 | 🧪 Avanzada |
| `bypass-mdm.sh`    | Versión original con nombres de volumen fijos      | ⚠️ Legacy          |
| `clear-dep-record-v2.sh` | Complemento: limpia un registro DEP residual en un Mac ya configurado | 🩹 Caso específico |

### ❤️ Contribuciones opcionales

Mucha gente se ha puesto en contacto preguntando cómo agradecer por salvar su Mac. **¡Esto es completamente opcional y no se espera!** Si quieres contribuir, se agradecen las donaciones en cripto.

Hay quienes han bifurcado (fork) este repositorio y han puesto el script tras un muro de pago. No me molesta en absoluto. De nuevo, las contribuciones en cripto no se esperan, pero siéntete libre si quieres.

**Bitcoin (BTC):**

```
bc1qzguh4908r7wguz20ylzeggya9d38t6hega5ppf
```

**Monero (XMR):**

```
45RnFseY4gNZv58DvShz2KJEbx1EyaTtaMCDnU5th21KbRThWurjjK6iugEdq9wfc4Kbw3a7AAyqo6WnEmL1StAMJur8QJp
```

## ⚖️ Aviso legal

> **Importante:** Aunque es prácticamente imposible detectar que has eliminado el MDM (porque nunca se configuró localmente), ten en cuenta que el número de serie de tu dispositivo seguirá apareciendo en el sistema de inventario de tu organización. Este script evita que el MDM se configure localmente, haciendo que el dispositivo no se pueda gestionar de forma remota.
>
> **Úsalo de forma responsable y bajo tu propio riesgo.** Esta herramienta está pensada para dispositivos personales y no debe usarse para eludir políticas organizacionales legítimas sin la debida autorización.

---

## 📄 Licencia

Este proyecto se ofrece tal cual, con fines educativos. Úsalo a tu discreción.
