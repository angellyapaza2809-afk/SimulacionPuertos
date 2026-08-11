-- ============================================================================
-- Migración 0003: Gastos de descarga por puerto (hoja "Gastos de Descarga")
-- ============================================================================

insert into gastos_descarga_puerto (puerto_id, concepto, tarifa_dolares_tn, tarifa_soles_tn, distribucion_soles)
select (select id from puertos where nombre = v.puerto), v.concepto, v.usd_tn, v.soles_tn, v.distribucion
from (values
    ('Chancay', 'CONTROL DE BALANZA',        0.0588235294, 0.20,  4618.998),
    ('Callao',  'CONTROL DE BALANZA',        0.0588235294, 0.20,  4618.998),
    ('Chancay', 'COMISION DE AGENTE',        0.34,         1.156, 26697.808440),
    ('Callao',  'COMISION DE AGENTE',        0.34,         1.156, 26697.808440),
    ('Chancay', 'GASTOS DE AREA OPERATIVA',  10.00,        34.00, 785229.66),
    ('Callao',  'GASTOS DE AREA OPERATIVA',  12.22,        41.548, 959550.64452),
    ('Chancay', 'GASTOS DE A&G',             null,         0.82,  18937.8918),
    ('Callao',  'GASTOS DE A&G',             null,         0.82,  18937.8918)
) as v(puerto, concepto, usd_tn, soles_tn, distribucion);
