# Bitácora Portuaria — Gastos Puerto Chancay / Callao

Migración del Excel `Resumen_de_gastos_Puerto_Chancay.xlsx` a una aplicación web
con **Supabase** (Postgres) como base de datos y un frontend en **React + Vite**.

Modela el flujo real del negocio: una nave llega a un puerto (Chancay o
Callao), se descarga (gasto de descarga), y la carga se transporta por
tierra —con uno de 3 transportistas— hacia una de las 3 plantas de alimento
balanceado (Chancay, GH Chancay, Lurín). El sistema permite comparar el
costo de haber usado cada puerto por nave.

---

## 1. Qué incluye este repositorio

```
├── src/                         # App web (React + Vite + Tailwind + Supabase JS)
│   ├── pages/                   # Panel general, Registros, Tarifas, Gastos, Comparativo
│   ├── components/
│   └── lib/
├── supabase/
│   ├── migrations/               # SQL versionado (correr en orden 0001 → 0007)
│   └── seed_data/                # CSVs exportados del Excel original
├── scripts/
│   └── import_bd_registros.mjs   # Importación masiva de los 992 registros de camiones
├── .env.example
└── package.json
```

## 2. Requisitos

- Node.js 18+
- Una cuenta gratuita en [supabase.com](https://supabase.com)
- Una cuenta en [GitHub](https://github.com)
- (Opcional pero recomendado) [Supabase CLI](https://supabase.com/docs/guides/cli) o acceso a `psql`

---

## 3. Crear el proyecto en Supabase

1. Entra a [supabase.com/dashboard](https://supabase.com/dashboard) → **New project**.
2. Elige nombre, contraseña de base de datos y región (p. ej. `South America`).
3. Cuando el proyecto esté listo, ve a **Project Settings → API** y copia:
   - `Project URL` → lo usarás como `VITE_SUPABASE_URL`
   - `anon public` key → `VITE_SUPABASE_ANON_KEY`
   - `service_role` key → `SUPABASE_SERVICE_ROLE_KEY` (solo para importar datos, nunca al frontend)

## 4. Aplicar el esquema de base de datos

### Opción A — Con Supabase CLI (recomendado)

```bash
npm install -g supabase
supabase login
supabase link --project-ref TU_PROJECT_REF   # está en la URL del dashboard
supabase db push                             # aplica todas las migrations en supabase/migrations
```

### Opción B — Manual desde el SQL Editor del dashboard

Abre **SQL Editor** en el dashboard de Supabase y ejecuta, **en este orden**,
el contenido de cada archivo de `supabase/migrations/`:

1. `0001_schema.sql` — tablas, índices, vistas
2. `0002_seed_reference.sql` — puertos, plantas, transportistas, tarifas
3. `0003_seed_gastos_descarga.sql` — gastos de descarga por puerto
4. `0004_seed_naves_resumen_puertos.sql` — naves + comparativo Chancay/Callao (38 registros)
5. `0005_staging_registros_transporte.sql` — tabla temporal para cargar el detalle de camiones
6. `0006_transform_staging_registros.sql` — **ejecutar solo después del paso 5 en la sección siguiente**
7. `0007_rls.sql` — seguridad a nivel de fila (RLS)

## 5. Cargar los 992 registros de camiones (hoja "BD" del Excel)

Este es el detalle operativo más grande del archivo original. Dos formas de cargarlo:

### Opción A — Import CSV vía Table Editor (más simple, sin consola)

1. En el dashboard, abre **Table Editor → `staging_bd_registros`** (creada por 0005).
2. Botón **Insert → Import data from CSV** → sube `supabase/seed_data/bd_registros.csv`.
3. Vuelve al **SQL Editor** y corre `0006_transform_staging_registros.sql`.
4. (Opcional) Vacía el staging: `truncate table staging_bd_registros;`

### Opción B — Script Node (API, requiere `service_role` key)

```bash
cp .env.example .env
# completa VITE_SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY en .env
npm install
npm run import:registros
```

Este script resuelve automáticamente los `transportista_id` / `planta_id` /
`nave_id` y crea la nave `AFRICAN ROADRUNNER` (la única presente en el
detalle) si no existe aún.

> ⚠️ Dato de calidad detectado en el archivo original: en la hoja `tarifas`,
> la tarifa de flete de `TPC / PAB CHANCAY (5003)` estaba corrupta (celda
> con formato de fecha en vez de número). Quedó en `NULL` en
> `tarifas_puerto_planta` — revísala y complétala manualmente cuando tengas
> el valor correcto.

---

## 6. Ejecutar la app localmente

```bash
cp .env.example .env      # si no lo hiciste ya
# completa VITE_SUPABASE_URL y VITE_SUPABASE_ANON_KEY
npm install
npm run dev
```

Abre `http://localhost:5173`. Deberías ver el panel general con KPIs, el
detalle de registros de transporte (paginado y filtrable), tarifas editables,
gastos de descarga por puerto y el comparativo Chancay vs Callao.

---

## 7. Subir el proyecto a GitHub

```bash
cd puerto-chancay-gastos       # esta carpeta (ya viene con git init hecho)
git remote add origin https://github.com/TU_USUARIO/TU_REPO.git
git branch -M main
git push -u origin main
```

`.env` está en `.gitignore` — nunca se sube. Si despliegas en Vercel/Netlify,
configura `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY` como variables de
entorno del proyecto (no la `service_role`).

## 8. Desplegar (opcional)

Cualquier hosting de estáticos sirve (Vercel, Netlify, Cloudflare Pages):

```bash
npm run build      # genera dist/
```

En Vercel: *Import Project* desde GitHub → Framework preset **Vite** →
agrega las dos variables de entorno `VITE_SUPABASE_*` → Deploy.

---

## 9. Seguridad (RLS)

Por defecto, la migración `0007_rls.sql` deja **lectura pública** (para que
el dashboard funcione sin login) y **escritura solo para usuarios
autenticados** de Supabase. Si los montos de gastos son sensibles y no deben
verse sin iniciar sesión, edita esa migración antes de aplicarla en
producción: quita la política `lectura_publica_*` y agrega autenticación
(Supabase Auth) al frontend.

## 10. Modelo de datos (resumen)

| Tabla                        | Contenido                                                          |
|-------------------------------|---------------------------------------------------------------------|
| `puertos`                    | Chancay, Callao                                                     |
| `plantas`                    | Chancay (5003), GH Chancay (5029), Lurín (5001)                     |
| `transportistas`              | TOSA E.I.R.L., TRANSJIBAJA S.A.C., VILMA ROJAS                      |
| `tarifas_transporte`          | S/ por TN, por planta y transportista (editable desde la app)       |
| `tarifas_puerto_planta`       | Tarifa base de flete APM → planta                                   |
| `naves`                       | Buques registrados                                                  |
| `registros_transporte`        | Detalle por camión (992 filas migradas de la hoja "BD")             |
| `gastos_descarga_puerto`      | Conceptos operativos de descarga, por puerto                        |
| `resumen_puertos`             | Costo total y CU por nave, Chancay vs Callao (38 filas)              |
| `comparativo_presupuesto`     | Presupuesto vs real por nave                                        |
| `gestion_ahorros` / `gestion_logistica_naves` | Ahorros de flete/demurrage por nave                 |
| `laytime`                     | Días de estadía de naves en puerto, por año                         |

Vistas (`vw_*`) precalculan KPIs y agregados usados por el dashboard —
revísalas en `supabase/migrations/0001_schema.sql`.

## 11. Qué falta / próximos pasos sugeridos

Este proyecto migra fielmente las hojas mejor estructuradas del Excel
(BD, tarifas, gastos de transporte y descarga, resumen de puertos). Las
hojas `Gestión CA`, `Laytime2024/2025` y los gráficos (`grafico`,
`grafico 2026`) tienen tablas modeladas en el esquema
(`gestion_ahorros`, `laytime`, etc.) pero **sin datos semilla** todavía —
sus layouts en el Excel combinan varias tablas por hoja y conviene que
confirmes contigo la interpretación correcta antes de cargarlas. Puedo
continuar con eso si me indicas cuál priorizar.
