-- ============================================================================
-- Migración 0001: Esquema base
-- Sistema de Gestión de Gastos Portuarios (Puerto Chancay / Puerto Callao)
-- ============================================================================
-- Modelo de negocio:
--   Una nave llega a un puerto (Callao o Chancay) con un producto (maíz,
--   torta de soya, etc). La carga se descarga (gasto de descarga) y luego
--   se transporta por vía terrestre (gasto de transporte, por camión) hacia
--   una de las plantas de alimento balanceado (Chancay, GH Chancay, Lurín)
--   usando uno de los transportistas contratados.
-- ============================================================================

create extension if not exists "pgcrypto";

-- ----------------------------------------------------------------------------
-- Tablas de referencia (catálogos)
-- ----------------------------------------------------------------------------

create table if not exists puertos (
    id          smallserial primary key,
    nombre      text not null unique,           -- 'Chancay' | 'Callao'
    created_at  timestamptz not null default now()
);
comment on table puertos is 'Puertos donde se descargan las naves.';

create table if not exists plantas (
    id          smallserial primary key,
    nombre      text not null,                  -- 'Chancay', 'GH Chancay', 'Lurín'
    codigo      text not null unique,            -- '5003', '5029', '5001'
    created_at  timestamptz not null default now()
);
comment on table plantas is 'Plantas de alimento balanceado (centros receptores).';

create table if not exists transportistas (
    id          smallserial primary key,
    nombre      text not null unique,            -- 'TOSA E.I.R.L.', 'TRANSJIBAJA S.A.C.', 'VILMA ROJAS'
    ruc         text,
    created_at  timestamptz not null default now()
);
comment on table transportistas is 'Empresas de transporte terrestre contratadas.';

create table if not exists productos (
    id          smallserial primary key,
    nombre      text not null unique             -- 'Maíz', 'Torta de soya', 'Grano de soya'...
);

-- ----------------------------------------------------------------------------
-- Tarifas
-- ----------------------------------------------------------------------------

-- Tarifa de flete terrestre puerto -> planta (referencial / base APM)
create table if not exists tarifas_puerto_planta (
    id                smallserial primary key,
    puerto_id         smallint references puertos(id),
    planta_id         smallint not null references plantas(id),
    descripcion       text,
    flete_soles_tn    numeric(12,4),
    vigente_desde     date not null default current_date,
    created_at        timestamptz not null default now()
);

-- Tarifa de flete terrestre por planta + transportista (S/ por TN)
create table if not exists tarifas_transporte (
    id                smallserial primary key,
    planta_id         smallint not null references plantas(id),
    transportista_id  smallint not null references transportistas(id),
    tarifa_soles_tn   numeric(12,4) not null,
    vigente_desde     date not null default current_date,
    vigente_hasta     date,
    created_at        timestamptz not null default now(),
    unique (planta_id, transportista_id, vigente_desde)
);
comment on table tarifas_transporte is 'Tarifa S/ por TN, por planta y transportista. Permite versionado histórico.';

-- ----------------------------------------------------------------------------
-- Naves
-- ----------------------------------------------------------------------------

create table if not exists naves (
    id                uuid primary key default gen_random_uuid(),
    nombre            text not null,
    puerto_id         smallint references puertos(id),
    producto_id       smallint references productos(id),
    tonelaje_tn       numeric(14,3),
    fecha_llegada     date,
    anio              smallint,
    notas             text,
    created_at        timestamptz not null default now()
);
create index if not exists idx_naves_nombre on naves (nombre);
create index if not exists idx_naves_puerto on naves (puerto_id);

-- ----------------------------------------------------------------------------
-- Registros de transporte terrestre (detalle operativo por camión)
-- Migrado 1:1 desde la hoja "BD" del Excel original.
-- ----------------------------------------------------------------------------

create table if not exists registros_transporte (
    id                              uuid primary key default gen_random_uuid(),
    item_origen                     integer,                 -- ITEM original del Excel (trazabilidad)
    nave_id                         uuid references naves(id) on delete set null,
    nave_nombre                     text not null,            -- respaldo textual si no hay match de nave
    producto                        text,
    jornada                         text,
    turno                           text,
    ticket_apm                      text,
    permiso                         text,
    bl                              text,
    bodega                          text,
    balanza_ingreso                 text,
    fecha_ingreso_apm               timestamptz,
    fecha_inicio_carguio            timestamptz,
    fecha_termino_carguio           timestamptz,
    duracion_carguio                interval,
    estadia_muelle_antes_carguio    interval,
    balanza_salida                  text,
    guia_remision_agencia           text,
    placa_camion                    text,
    transportista_id                smallint references transportistas(id),
    num_precinto                    text,
    peso_bruto_puerto_kg            numeric(12,2),
    tara_puerto_kg                  numeric(12,2),
    peso_neto_salida_apm_kg         numeric(12,2),
    peso_apm_tn                     numeric(12,3),
    planta_id                       smallint references plantas(id),
    destino_almacen_texto           text,                     -- respaldo textual del destino original
    fecha_salida_apmtc              timestamptz,
    tiempo_termino_carguio_salida   interval,
    tiempo_llegada_salida_apm       interval,
    fecha_ingreso_almacen           timestamptz,
    peso_bruto_almacen_kg           numeric(12,2),
    tara_almacen_kg                 numeric(12,2),
    peso_neto_ingreso_almacen_kg    numeric(12,2),
    diferencia_pesos_netos_kg       numeric(12,2),
    fecha_salida_almacen            timestamptz,
    tiempo_llegada_almacen          interval,
    permanencia_almacen             interval,
    duracion_total_traslado         interval,
    observaciones                   text,
    guia_transporte                 text,
    created_at                      timestamptz not null default now()
);
create index if not exists idx_registros_transportista on registros_transporte (transportista_id);
create index if not exists idx_registros_planta on registros_transporte (planta_id);
create index if not exists idx_registros_nave on registros_transporte (nave_id);
create index if not exists idx_registros_fecha_ingreso on registros_transporte (fecha_ingreso_apm);

-- ----------------------------------------------------------------------------
-- Gastos de descarga (por puerto, conceptos operativos)
-- ----------------------------------------------------------------------------

create table if not exists gastos_descarga_puerto (
    id                    serial primary key,
    puerto_id             smallint not null references puertos(id),
    nave_id               uuid references naves(id) on delete cascade,
    concepto              text not null,           -- CONTROL DE BALANZA, COMISION DE AGENTE, GASTOS DE AREA OPERATIVA, GASTOS DE A&G
    tarifa_dolares_tn     numeric(12,4),
    tarifa_soles_tn       numeric(12,4),
    distribucion_soles    numeric(14,2),
    periodo               date,
    created_at            timestamptz not null default now()
);
create index if not exists idx_gdp_puerto on gastos_descarga_puerto (puerto_id);
create index if not exists idx_gdp_nave on gastos_descarga_puerto (nave_id);

-- ----------------------------------------------------------------------------
-- Resumen comparativo por nave: Chancay vs Callao
-- (migrado desde la hoja "Resumen Puertos")
-- ----------------------------------------------------------------------------

create table if not exists resumen_puertos (
    id                       serial primary key,
    nave_id                  uuid references naves(id) on delete cascade,
    nave_nombre              text not null,
    puerto_id                smallint not null references puertos(id),
    tn                       numeric(14,3),
    costo_descarga_soles     numeric(14,2),
    costo_transporte_soles   numeric(14,2),
    costo_almacenamiento     numeric(14,2),
    costo_total_soles        numeric(14,2),
    cu_descarga              numeric(12,4),
    cu_transporte            numeric(12,4),
    cu_almacenamiento        numeric(12,4),
    cu_total                 numeric(12,4),
    demurrage_dispatch_usd   numeric(14,2),
    created_at               timestamptz not null default now()
);
create index if not exists idx_resumen_puertos_nave on resumen_puertos (nave_nombre);

-- ----------------------------------------------------------------------------
-- Comparativo presupuestal (puerto elegido vs presupuesto)
-- ----------------------------------------------------------------------------

create table if not exists comparativo_presupuesto (
    id                     serial primary key,
    puerto_elegido_id      smallint references puertos(id),
    nave_nombre            text not null,
    tonelaje_tn            numeric(14,3),
    producto               text,
    gasto_presupuestado    numeric(14,2),
    gasto_por_tn           numeric(12,4),
    gasto_por_nave         numeric(14,2),
    presupuesto_menos_real numeric(14,2),
    anio                   smallint,
    created_at             timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- Gestión de ahorros (flete terrestre / demurrage) por nave
-- ----------------------------------------------------------------------------

create table if not exists gestion_ahorros (
    id                              serial primary key,
    nave_nombre                     text not null,
    sobrecosto_flete_lurin          numeric(14,2),
    ahorro_flete_pab_chancay        numeric(14,2),
    ahorro_demurrage                numeric(14,2),
    resultado_neto                  numeric(14,2),
    created_at                      timestamptz not null default now()
);

create table if not exists gestion_logistica_naves (
    id                                  serial primary key,
    nave_nombre                         text not null,
    puerto_descargado_id                smallint references puertos(id),
    gasto_transporte_callao_soles       numeric(14,2),
    gasto_transporte_chancay_soles      numeric(14,2),
    ahorro_logistico_soles              numeric(14,2),
    gasto_descarga_callao_soles         numeric(14,2),
    gasto_descarga_chancay_soles        numeric(14,2),
    diferencia_gasto_descarga_soles     numeric(14,2),
    created_at                          timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- Laytime (tiempo de estadía de naves en puerto)
-- ----------------------------------------------------------------------------

create table if not exists laytime (
    id            serial primary key,
    nave_nombre   text not null,
    anio          smallint not null,
    mes           text,
    producto      text,
    tn            numeric(14,3),
    laytime_dias  numeric(10,3),
    cargo_usd     numeric(14,2),
    created_at    timestamptz not null default now()
);
create index if not exists idx_laytime_anio on laytime (anio);

-- ----------------------------------------------------------------------------
-- Vistas de apoyo para el dashboard
-- ----------------------------------------------------------------------------

create or replace view vw_gastos_transporte_por_planta as
select
    p.nombre as planta,
    t.nombre as transportista,
    r.planta_id,
    r.transportista_id,
    sum(r.peso_apm_tn) as tn_transportadas,
    count(*) as num_viajes
from registros_transporte r
join plantas p on p.id = r.planta_id
join transportistas t on t.id = r.transportista_id
group by p.nombre, t.nombre, r.planta_id, r.transportista_id;

create or replace view vw_gastos_transporte_calculado as
select
    v.planta,
    v.transportista,
    v.tn_transportadas,
    v.num_viajes,
    tt.tarifa_soles_tn,
    round(v.tn_transportadas * tt.tarifa_soles_tn, 2) as gasto_soles
from vw_gastos_transporte_por_planta v
left join tarifas_transporte tt
    on tt.planta_id = v.planta_id and tt.transportista_id = v.transportista_id;

create or replace view vw_comparativo_puertos as
select
    nave_nombre,
    max(case when p.nombre = 'Chancay' then costo_total_soles end) as costo_total_chancay,
    max(case when p.nombre = 'Callao'  then costo_total_soles end) as costo_total_callao,
    max(case when p.nombre = 'Chancay' then cu_total end) as cu_total_chancay,
    max(case when p.nombre = 'Callao'  then cu_total end) as cu_total_callao
from resumen_puertos rp
join puertos p on p.id = rp.puerto_id
group by nave_nombre;

create or replace view vw_dashboard_kpis as
select
    (select coalesce(sum(peso_apm_tn),0) from registros_transporte) as tn_total_transportadas,
    (select count(*) from registros_transporte) as total_viajes,
    (select count(distinct nave_nombre) from naves) as total_naves,
    (select coalesce(sum(distribucion_soles),0) from gastos_descarga_puerto) as gasto_descarga_total_soles;
