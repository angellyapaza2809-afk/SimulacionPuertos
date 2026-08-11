-- ============================================================================
-- Migración 0005: Tabla de staging para carga masiva de "registros_transporte"
-- ============================================================================
-- Esta tabla espeja 1:1 las columnas del CSV supabase/seed_data/bd_registros.csv
-- (todo como texto) para poder importarlo con \copy o desde el Table Editor
-- de Supabase, y luego transformarlo con la migración 0006.

create table if not exists staging_bd_registros (
    item                                    text,
    buque                                   text,
    producto                                text,
    jornada                                 text,
    turno                                   text,
    ticket_apm                              text,
    permiso                                 text,
    bl                                      text,
    bodega                                  text,
    balanza_ingreso                         text,
    fecha_ingreso_apm                       text,
    fecha_inicio_carguio                    text,
    fecha_termino_carguio                   text,
    duracion_carguio                        text,
    estadia_muelle_antes_carguio            text,
    balanza_salida                          text,
    guia_remision_agencia                   text,
    placa_camion                            text,
    empresa_transporte                      text,
    num_precinto                            text,
    peso_bruto_puerto                       text,
    tara_puerto                             text,
    peso_neto_salida_apm                    text,
    peso_apm_tn                             text,
    destino_almacen                         text,
    fecha_salida_apmtc                      text,
    tiempo_termino_carguio_salida           text,
    tiempo_llegada_salida_apm               text,
    fecha_ingreso_almacen                   text,
    peso_bruto_almacen                      text,
    tara_almacen                            text,
    peso_neto_ingreso_almacen               text,
    diferencia_pesos_netos                  text,
    fecha_salida_almacen                    text,
    tiempo_llegada_almacen_desde_puerto     text,
    permanencia_almacen                     text,
    duracion_total_traslado                 text,
    observaciones                           text,
    guia_transporte                         text
);

comment on table staging_bd_registros is
    'Tabla temporal de carga. Importar bd_registros.csv aquí y luego ejecutar 0006_transform_staging_registros.sql. Puede truncarse/eliminarse después.';
