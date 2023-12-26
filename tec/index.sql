CREATE SCHEMA tec AUTHORIZATION postgres;
COMMENT ON SCHEMA tec IS 'Техническая схема (для разработчиков)';

-- получить входящие параметры функции
drop function if exists tec.get_fun_in_params;
create or replace function tec.get_fun_in_params(
    schema_ varchar[],
    entity_ varchar
)
	returns table (
		fun_name information_schema.sql_identifier, 
		schema_name information_schema.sql_identifier, 
		params jsonb
)
	language plpgsql
	as $function$
	begin
        return query select r.routine_name as fun_name,
        r.routine_schema as schema_name,
            jsonb_agg(
                jsonb_build_object(
                    'name', p.parameter_name,
                    'type', 
                    case when p.udt_name like '\_%' 
                        then ltrim(p.udt_name, '_') || '[]'
                    else p.udt_name end  
                )
            ) as params
        from information_schema.routines r
        left join information_schema.parameters p on (r.specific_name = p.specific_name)
        where r.routine_type = 'FUNCTION'
        and r.routine_schema = any(schema_)
        and p.parameter_mode = 'IN'
        and r.routine_name like(entity_ || '%')
        group by fun_name, schema_name;
	end;
$function$;

-- получить первичный ключ в таблице
CREATE OR REPLACE FUNCTION tec.get_column_FK(table_schema_ character varying, table_name_ character varying)
 RETURNS TABLE(column_name varchar)
 LANGUAGE plpgsql
AS $function$
	begin
        return query select c.column_name::varchar
        from information_schema.columns c
        where table_schema=table_schema_ and table_name = table_name_ and is_identity = 'YES';
	end;
$function$;