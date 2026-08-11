-- ============================================================================
-- Migración 0006: Transformar staging_bd_registros -> registros_transporte
-- ============================================================================
-- Ejecutar DESPUÉS de importar supabase/seed_data/bd_registros.csv dentro de
-- staging_bd_registros (ver README.md, sección "Cargar datos operativos").

-- Nota: los horarios como '00:07:00' y fechas con formato 'YYYY-MM-DD HH24:MI:SS'
-- vienen ya normalizados en el CSV exportado, por lo que el cast directo es seguro.
-- Filas con celdas vacías ('') se convierten a NULL.

insert into registros_transporte (
    item_origen, nave_id, nave_nombre, producto, jornada, turno, ticket_apm, permiso, bl, bodega,
    balanza_ingreso, fecha_ingreso_apm, fecha_inicio_carguio, fecha_termino_carguio,
    duracion_carguio, estadia_muelle_antes_carguio, balanza_salida, guia_remision_agencia,
    placa_camion, transportista_id, num_precinto, peso_bruto_puerto_kg, tara_puerto_kg,
    peso_neto_salida_apm_kg, peso_apm_tn, planta_id, destino_almacen_texto, fecha_salida_apmtc,
    tiempo_termino_carguio_salida, tiempo_llegada_salida_apm, fecha_ingreso_almacen,
    peso_bruto_almacen_kg, tara_almacen_kg, peso_neto_ingreso_almacen_kg, diferencia_pesos_netos_kg,
    fecha_salida_almacen, tiempo_llegada_almacen, permanencia_almacen, duracion_total_traslado,
    observaciones, guia_transporte
)
select
    nullif(s.item,'')::integer,
    n.id,
    s.buque,
    nullif(s.producto,''),
    nullif(s.jornada,''),
    nullif(s.turno,''),
    nullif(s.ticket_apm,''),
    nullif(s.permiso,''),
    nullif(s.bl,''),
    nullif(s.bodega,''),
    nullif(s.balanza_ingreso,''),
    nullif(s.fecha_ingreso_apm,'')::timestamptz,
    nullif(s.fecha_inicio_carguio,'')::timestamptz,
    nullif(s.fecha_termino_carguio,'')::timestamptz,
    nullif(s.duracion_carguio,'')::interval,
    nullif(s.estadia_muelle_antes_carguio,'')::interval,
    nullif(s.balanza_salida,''),
    nullif(s.guia_remision_agencia,''),
    nullif(s.placa_camion,''),
    t.id,
    nullif(s.num_precinto,''),
    nullif(s.peso_bruto_puerto,'')::numeric,
    nullif(s.tara_puerto,'')::numeric,
    nullif(s.peso_neto_salida_apm,'')::numeric,
    nullif(s.peso_apm_tn,'')::numeric,
    p.id,
    nullif(s.destino_almacen,''),
    nullif(s.fecha_salida_apmtc,'')::timestamptz,
    nullif(s.tiempo_termino_carguio_salida,'')::interval,
    nullif(s.tiempo_llegada_salida_apm,'')::interval,
    nullif(s.fecha_ingreso_almacen,'')::timestamptz,
    nullif(s.peso_bruto_almacen,'')::numeric,
    nullif(s.tara_almacen,'')::numeric,
    nullif(s.peso_neto_ingreso_almacen,'')::numeric,
    nullif(s.diferencia_pesos_netos,'')::numeric,
    nullif(s.fecha_salida_almacen,'')::timestamptz,
    nullif(s.tiempo_llegada_almacen_desde_puerto,'')::interval,
    nullif(s.permanencia_almacen,'')::interval,
    nullif(s.duracion_total_traslado,'')::interval,
    nullif(s.observaciones,''),
    nullif(s.guia_transporte,'')
from staging_bd_registros s
left join naves n           on n.nombre = s.buque
left join transportistas t  on t.nombre = s.empresa_transporte
left join plantas p         on s.destino_almacen ilike '%' || p.codigo || '%';

-- Limpieza opcional (descomentar si ya no necesitas la tabla de staging):
-- drop table if exists staging_bd_registros;
