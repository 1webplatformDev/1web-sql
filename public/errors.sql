-- fun

--select * from public.create_error_json(ARRAY['{ "id": 1, "name": "Указанное const_name имя типа компонента занято"}'::json], 200);
--select * from public.create_error_json(ARRAY['{ "id": 1, "name": "Указанное const_name имя типа компонента занято"}'::json]);

--  select * from public.create_error_ids(ARRAY[1,2]);
--  select * from public.create_error_ids(ARRAY[1,2], 404);

-- Очистка
drop table if exists public.errors cascade;

create table public.errors (
	id int4 not null generated always as identity, -- Первичный ключ
	"name" varchar not null, -- Название ошибки
	description varchar null, -- Описание ошибки
	id_project int4 NULL, -- внешний ключ проекта
	status int4 NULL DEFAULT 400, -- статус ошибки

	constraint error_pk primary key (id),
	CONSTRAINT errors_fk FOREIGN KEY (id_project) REFERENCES public.project(id)
);

--  comments
comment on table public.errors is 'Ошибки';

comment on column public.errors.id is 'Первичный ключ';
comment on column public.errors."name" is 'Название ошибки';
comment on column public.errors.description is 'Описание ошибки';
comment on column public.errors.id_project is 'Внешний ключ проекта';
comment on column public.errors.status is 'Статус ошибки';

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
 

drop function if exists public.create_error_ids;
create or replace function public.create_error_ids(_ids int[], _status int = null)
returns json
	language  plpgsql
	as $function$
	declare	
		errors json[] = (select ARRAY(select row_to_json(res) from (
			select e.id, e.name, e.description from public.errors e where e.id = any(_ids)) as res 
		));
    begin 
    	return (select * from public.create_error_json(errors, _status));
	end;
$function$;

-- dataset
insert into public.errors(id, name, description, id_project, status)
overriding system value values(1, 'Указанное const_name типа компонента уже существует', null, 2, 400);

insert into public.errors(id, name, description, id_project, status)
overriding system value values(2, 'Указанное имя типа компонента уже существует', null, 2, 400);

insert into public.errors(id, name, description, id_project, status)
overriding system value values(3, 'Запись компонента с указаным id не существует', null, 2, 404);

insert into public.errors(id, name, description, id_project, status)
overriding system value values(4, 'Запись типа css с указаным id не существует', null, 2, 404);

insert into public.errors(id, name, description, id_project, status)
overriding system value values(5, 'Указанное имя типа css переменной уже существует', null, 2, 400);

insert into public.errors(id, name, description, id_project, status)
overriding system value values(6, 'Указанное const_name типа css переменной уже существует', null, 2, 400);

insert into public.errors(id, name, description, id_project, status)
overriding system value values(7, 'Запись css class с указаным id не существует', null, 2, 404);

insert into public.errors(id, name, description, id_project, status)
overriding system value values(8, 'Указанное имя css class уже существует', null, 2, 400);

insert into public.errors(id, name, description, id_project, status)
overriding system value values(10, 'css_class_item_params с указаным id не существует', null, 2, 404);

insert into public.errors(id, name, description, id_project, status)
overriding system value values(11, 'Запись params_css_class с указаным id не существует', null, 2, 404);

insert into public.errors(id, name, description, id_project, status)
overriding system value values(12, 'Запись css_class_list_params  с указаным id не существует', null, 2, 404)