-- Очистка

 drop table if exists constuctor.type_component cascade;
-- ALTER SEQUENCE constuctor.type_component_id_seq RESTART WITH 1;

create table constuctor.type_component (
	id int4 not null generated always as identity, -- Первичный ключ
	"name" varchar not null, -- Название типа компонента
	description varchar null, -- Описание типа компонента
	active bool not null default true, -- Актуальность типа компонента
	const_name varchar not null
);

create unique index type_component_const_name_idx on constuctor.type_component using btree (const_name);
create unique index type_component_name_idx on constuctor.type_component using btree (name);

-- Column comments

comment on column constuctor.type_component.id is 'Первичный ключ';
comment on column constuctor.type_component."name" is 'Название типа компонента';
comment on column constuctor.type_component.description is 'Описание типа компонента';
comment on column constuctor.type_component.active is 'Актуальность типа компонента';

-- type

drop type if exists constuctor.return_type_component cascade;
create type constuctor.return_type_component as (
	id int, 
	name varchar, 
	description varchar, 
	active bool,
	const_name varchar
);

-- function
drop function if exists constuctor.type_component_get();
create or replace function constuctor.type_component_get()
	returns SETOF constuctor.return_type_component
	language  plpgsql
as $function$
    begin 
        return query select tc.id, tc."name", tc.description, tc.active, tc.const_name  from constuctor.type_component tc;
    end;
$function$;
-- select * from constuctor.type_component_get();

drop function if exists constuctor.type_component_get_active();
create or replace function constuctor.type_component_get_active()
	returns SETOF constuctor.return_type_component
	language  plpgsql
as $function$
    begin 
        return query select * from constuctor.type_component_get() where active = true;
    end;
$function$;
-- select * from constuctor.type_component_get_active();

drop function if exists constuctor.type_component_check_unieue;
create or replace function constuctor.type_component_check_unieue(
	in _name varchar,
	in _const_name varchar,
	in _id int = null,
	out errors_ json
)
	language  plpgsql
	as $function$
declare
	count_name int;
	count_const_name int;
	error_text_const_name json = '{ "id": 1, "name": "Указанное const_name имя типа компонента занято"}';
	error_text_name json = '{ "id": 2, "name": "Указанное имя типа компонента занято"}';
	error_array json[];
    begin 
	    select count(*) into count_name from constuctor.type_component tc where tc.name = _name and (id <> _id or _id is null);
	   	select count(*) into count_const_name from constuctor.type_component tc where tc.const_name = _const_name and (id <> _id or _id is null);

	   	if count_name <> 0 then
			error_array = array_append(error_array, error_text_name);
	   	end if;	
	   		
	   	if count_const_name <> 0 then	
			error_array = array_append(error_array, error_text_const_name);
	   	end if;

		if array_length(error_array, 1) <> 0 then
			select * into errors_ from public.create_error_json(error_array);
			return;
		end if;

	   select * into errors_ from public.create_error_json(null, 200);
    end;
$function$;
-- select * from constuctor.type_component_check_unieue('div', 'div');

drop function if exists constuctor.type_component_insert();
create or replace function constuctor.type_component_insert(
	in _name varchar,
	in _const_name varchar,
	in _description varchar,
	out id_ int,
	out result_ json
)
	language  plpgsql
as $function$
    begin 
	   select * into result_ from constuctor.type_component_check_unieue(_name, _const_name);
	   if (result_::json->'status_result')::text::int = 200 then
	   	insert into constuctor.type_component
        (name, const_name, description) values (_name, _const_name, _description)
        returning id into id_;
	   end if;
    end;
$function$;
-- select * from constuctor.type_component_insert('test', 'test', 'test описание');

drop function if exists constuctor.type_component_updated;
create or replace function constuctor.type_component_updated(
	in _id int,
	in _name varchar,
	in _const_name varchar,
	in _description varchar,
	out result_ json
)
	language  plpgsql
as $function$
	declare 
		check_rows int;
		error_text_const_name json = '{ "id": 3, "name": "Запись с указаным id не существует"}';
    begin
		select count(*) into check_rows from constuctor.type_component tc where tc.id = _id;
		if check_rows = 0 then
			select * into result_ from public.create_error_json(array[error_text_const_name]);
			return;
		end if;
	   	select * into result_ from constuctor.type_component_check_unieue(_name, _const_name, _id);
	   	if (result_::json->'status_result')::text::int = 200 then
	   	 	UPDATE constuctor.type_component
			SET name = _name, const_name = _const_name, description = _description
			where id = _id;  
	   	end if;
    end;
$function$;
-- select * from constuctor.type_component_updated('1', 'test', 'test', 'test описание');