-- Очистка
drop table if exists public.errors cascade;

create table public.errors (
	id int4 not null generated always as identity, -- Первичный ключ
	"name" varchar not null, -- Название ошибки
	description varchar null -- Описание ошибки
);

comment on table constuctor.type_component IS 'Ошибки';

-- function
drop function if exists public.create_error_json;
create or replace function public.create_error_json(
	_error json[], 
	_status int = 400
)
	returns json
	language  plpgsql
as $function$
    begin 
    	return json_build_object('errors', _error, 'status_result', _status); 
	end;
$function$;
--select * from public.create_error_json(ARRAY['{ "id": 1, "name": "Указанное const_name имя типа компонента занято"}'::json], 200);
--select * from public.create_error_json(ARRAY['{ "id": 1, "name": "Указанное const_name имя типа компонента занято"}'::json]);