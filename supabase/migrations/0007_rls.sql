-- ============================================================================
-- Migración 0007: Row Level Security (RLS)
-- ============================================================================
-- Por defecto se habilita RLS en todas las tablas y se permite LECTURA pública
-- (rol 'anon' y 'authenticated') para que el dashboard funcione de inmediato.
-- La ESCRITURA queda restringida a usuarios autenticados.
--
-- ⚠️ Ajusta estas políticas antes de ir a producción si los datos de gastos
-- son sensibles: por ejemplo, restringe SELECT a 'authenticated' quitando la
-- política "lectura_publica_*" y dejando solo "lectura_autenticados_*".

do $$
declare
    t text;
begin
    for t in
        select unnest(array[
            'puertos','plantas','transportistas','productos',
            'tarifas_puerto_planta','tarifas_transporte',
            'naves','registros_transporte','gastos_descarga_puerto',
            'resumen_puertos','comparativo_presupuesto',
            'gestion_ahorros','gestion_logistica_naves','laytime'
        ])
    loop
        execute format('alter table %I enable row level security;', t);

        execute format(
            'drop policy if exists "lectura_publica_%1$s" on %1$I;
             create policy "lectura_publica_%1$s" on %1$I for select using (true);', t);

        execute format(
            'drop policy if exists "escritura_autenticados_%1$s" on %1$I;
             create policy "escritura_autenticados_%1$s" on %1$I
                for all using (auth.role() = ''authenticated'')
                with check (auth.role() = ''authenticated'');', t);
    end loop;
end $$;
