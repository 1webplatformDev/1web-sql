CREATE SCHEMA tec AUTHORIZATION postgres;
COMMENT ON SCHEMA tec IS 'Техническая схема (для разработчиков)';

-- получить входящие параметры функции для создания комментариев
drop function if exists tec.get_fun_in_params_comment;
create or replace function tec.get_fun_in_params_comment(
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
drop function if exists tec.get_column_FK;
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

-- получить список схем
drop function if exists tec.get_schema;
CREATE OR REPLACE FUNCTION tec.get_schema(_search varchar = null)
 RETURNS TABLE(name varchar)
 LANGUAGE plpgsql
AS $function$
	begin
        return query select schema_name::varchar as name
        from information_schema.schemata s 
        where s.schema_name not in ('information_schema', 'pg_catalog', 'pg_toast', 'temp') and (s.schema_name like '%' || _search || '%' or _search is null);
	end;
$function$;

-- получить список таблиц по таблице
drop function if exists tec.get_tables;
CREATE OR REPLACE FUNCTION tec.get_tables(_schema varchar, _search varchar = null)
 RETURNS TABLE(id varchar)
 LANGUAGE plpgsql
AS $function$
	begin
        return query select table_name::varchar as id 
        from information_schema.tables t 
        where 
            t.table_schema not in ('information_schema', 'pg_catalog', 'pg_toast', 'temp')
            and t.table_schema = _schema 
            and (t.table_name like '%' || _search || '%' or _search is null); 
	end;
$function$;