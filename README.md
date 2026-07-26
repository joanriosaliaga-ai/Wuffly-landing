# Wuffly — Landing de lista de espera

Página única (`index.html`), sin build ni dependencias. Se sube directa a GitHub y funciona.

## 1. Subir a GitHub Pages (5 minutos)

1. Crea un repositorio nuevo en GitHub (público), por ejemplo `wuffly-landing`.
2. Sube `index.html` **y la carpeta `assets/`** (con el logo) a la raíz del repositorio, manteniendo esa misma estructura de carpetas — arrastrar y soltar ambos en la web de GitHub funciona, GitHub respeta las subcarpetas. (`supabase-setup.sql` no hace falta subirlo al hosting — es solo para pegarlo una vez en el editor SQL de Supabase, ver punto 2.)
3. Ve a **Settings → Pages**.
4. En "Source" elige la rama `main` y la carpeta `/ (root)`. Guarda.
5. En 1-2 minutos tu landing estará en `https://tu-usuario.github.io/wuffly-landing/`.

**Alternativa (recomendada si luego quieres dominio propio):** conecta el repo a **Vercel** (gratis) — deploy automático en cada commit y es más fácil añadir `wuffly.club` cuando lo compres.

## 2. Activar la lista real: posición en cola + referidos (Supabase, gratis)

Esta versión ya no usa Formspree — ahora tenéis un sistema propio, gratis para siempre en el volumen que vais a manejar, con lo que pedía la mecánica tipo Robinhood: cada persona ve su puesto en la cola y puede subir posiciones invitando amigos con su link único.

**Paso 1 — Crear el proyecto (2 min)**
1. Ve a [supabase.com](https://supabase.com) y crea una cuenta gratuita.
2. Crea un proyecto nuevo (elige región de Europa para latencia y RGPD).
3. Ve a **Project Settings → API**. Copia dos valores: la **Project URL** y la **anon public key**.

**Paso 2 — Crear la base de datos (1 min)**
1. Ve a **SQL Editor** en el panel de Supabase.
2. Abre el archivo `supabase-setup.sql` (incluido junto a este README), copia todo su contenido y pégalo en el editor.
3. Dale a **Run**. Esto crea la tabla y toda la lógica de posición/referidos de golpe.

**Paso 3 — Conectar la web (1 min)**
1. Abre `index.html`, busca estas dos líneas cerca del final del archivo:
   ```js
   const SUPABASE_URL = "https://YOUR-PROJECT.supabase.co";
   const SUPABASE_ANON_KEY = "YOUR_PUBLIC_ANON_KEY";
   ```
2. Sustituye ambas por los valores que copiaste en el Paso 1.
3. Guarda, haz commit y sube el cambio.

**¿Es seguro exponer la "anon key" en el código público?** Sí — está pensada para eso, es la clave "pública" de Supabase, no un secreto. La seguridad de verdad la da el `supabase-setup.sql`: bloquea el acceso directo a la tabla (nadie puede leer la lista de emails de otra gente) y solo permite entrar a través de dos funciones controladas que devuelven exclusivamente tu propia posición, nunca la lista completa.

**Cómo funciona la mecánica de posición:**
- Cada persona que se apunta entra en la cola por orden de llegada.
- Cada referido confirmado (alguien que se apunta usando su link) le sube 3 puestos.
- Al enviar el formulario, la persona ve al momento su puesto y su link único para compartir — ese link lleva `?ref=SUCODIGO`, así que si alguien entra a la web con ese parámetro, el sistema sabe a quién atribuir el referido.
- Si vuelve a visitar la web más tarde, el sitio recuerda su email (vía `localStorage` del navegador) y le muestra su posición actualizada, sin tener que apuntarse dos veces.

**Para ver tus datos:** entra en Supabase → **Table Editor** → tabla `waitlist`, o usa las consultas SQL de ejemplo que están al final de `supabase-setup.sql`. Ahí verás emails, de qué interés vienen (general / Wuffly Nations) y quién ha traído a quién.

## 3. Qué personalizar antes de compartir el link

- **Instagram real**: busca `instagram.com/wuffly.club` en el HTML y cámbialo por tu cuenta real (ahora mismo es un placeholder).
- **Email de contacto**: busca `hola@wuffly.club` y cámbialo si usas otro.
- **Copy de "Impacto"**: en cuanto cierres la entidad benéfica con la que colaboráis, actualiza ese bloque — está escrito a propósito sin cifras inventadas.
- **Precio en el FAQ**: cuando tengas el pricing cerrado, puedes decidir si lo enseñas ya o lo dejas como "condiciones especiales para fundadores".

## 4. Qué ha cambiado en esta versión

- **Sistema de posición + referidos (Supabase)**, sustituyendo Formspree: cada persona ve su puesto en la cola y un link único para invitar amigos y subir posiciones — la mecánica que hizo crecer a Robinhood antes de su lanzamiento. Gratis en el volumen que vais a manejar (Supabase free tier: 500MB de base de datos, más que suficiente para millones de filas de una lista de espera).
  **Aviso importante:** el plan gratuito de Supabase pausa el proyecto automáticamente si pasa **una semana sin ninguna visita/uso**. Si eso pasa, los formularios dejan de funcionar hasta que entres al panel de Supabase y le des a "reanudar" (tarda menos de un minuto). Mientras la landing reciba alguna visita a la semana durante la fase de validación, no debería pasaros — pero si vais a estar varios días sin promocionarla, revisadlo antes de mandar una campaña.
- **Paleta real de marca**: petróleo (#17393f), mostaza (#fdd05c), terracota (#d27c61), camel y crema.
- **Logo real**: 3 versiones del icono (petróleo, crema, terracota) con fondo transparente, en `assets/`.
- **Mensaje corregido**: una única suscripción con tema rotativo mensual (Adventure/Spa/Games), no tres cajas a elegir. Wuffly Nations queda como la única edición "Próximamente".

## 5. Qué NO lleva esta versión (a propósito)

- El contador de posición **es real**, no inventado — se calcula en directo contra la base de datos, así que si hoy solo hay 2 personas apuntadas, la primera verá "puesto #1" y no un número inflado artificialmente. Es importante no simular actividad falsa para dar sensación de más tracción de la que hay.
- Sin checkout ni tienda — esto es solo captación de lista de espera, tal como acordamos como primer paso.
- Sin analítica — si quieres medir visitas, lo más simple y respetuoso con privacidad es añadir [Plausible](https://plausible.io) o [Vercel Analytics](https://vercel.com/analytics) más adelante.

## 6. Siguiente paso sugerido

Una vez la landing esté recibiendo registros reales durante unas semanas, los siguientes bloques del plan son:
1. Documento de pricing y modelo de negocio
2. Los 3 primeros conceptos de "caja del mes"
3. Web completa con tienda (cuando cierres proveedores y precio)
