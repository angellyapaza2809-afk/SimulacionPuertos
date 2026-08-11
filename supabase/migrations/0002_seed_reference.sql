-- ============================================================================
-- Migración 0002: Datos semilla (catálogos y tarifas)
-- Extraídos de Resumen_de_gastos_Puerto_Chancay.xlsx
-- ============================================================================

insert into puertos (nombre) values ('Chancay'), ('Callao')
on conflict (nombre) do nothing;

insert into plantas (nombre, codigo) values
    ('Chancay', '5003'),
    ('GH Chancay', '5029'),
    ('Lurín', '5001')
on conflict (codigo) do nothing;

insert into transportistas (nombre) values
    ('TOSA E.I.R.L.'),
    ('TRANSJIBAJA S.A.C.'),
    ('VILMA ROJAS')
on conflict (nombre) do nothing;

insert into productos (nombre) values
    ('Maíz amarillo argentino'),
    ('Torta de soya'),
    ('Grano de soya')
on conflict (nombre) do nothing;

-- Tarifas de flete terrestre por planta y transportista (hoja "Gastos de Transporte")
insert into tarifas_transporte (planta_id, transportista_id, tarifa_soles_tn, vigente_desde)
select p.id, t.id, v.tarifa, current_date
from (values
    ('5003', 'TOSA E.I.R.L.', 9.5),
    ('5003', 'TRANSJIBAJA S.A.C.', 8.0),
    ('5003', 'VILMA ROJAS', 7.9),
    ('5029', 'TOSA E.I.R.L.', 9.5),
    ('5029', 'TRANSJIBAJA S.A.C.', 9.5),
    ('5029', 'VILMA ROJAS', 8.9),
    ('5001', 'TOSA E.I.R.L.', 50.0),
    ('5001', 'TRANSJIBAJA S.A.C.', 45.0),
    ('5001', 'VILMA ROJAS', 45.0)
) as v(codigo_planta, nombre_transportista, tarifa)
join plantas p on p.codigo = v.codigo_planta
join transportistas t on t.nombre = v.nombre_transportista
on conflict (planta_id, transportista_id, vigente_desde) do nothing;

-- Tarifa base puerto -> planta (hoja "tarifas"). Nota: el valor de PAB CHANCAY (5003)
-- venía corrupto en el archivo original (celda con formato de fecha en vez de número),
-- se deja NULL a la espera de confirmación del dato real por el usuario.
insert into tarifas_puerto_planta (puerto_id, planta_id, descripcion, flete_soles_tn)
select (select id from puertos where nombre = 'Chancay'), p.id, v.descripcion, v.flete
from (values
    ('5003', 'TPC / PAB CHANCAY', null),
    ('5029', 'TPC / PAB GH CHANCAY', 31.51),
    ('5001', 'TPC / PAB LURIN', 23.96)
) as v(codigo_planta, descripcion, flete)
join plantas p on p.codigo = v.codigo_planta;
