-- fun

-- select * from constuctor.type_component_check_unieue;
-- select * from constuctor.type_component_insert;
-- select * from constuctor.type_component_get_unique;
-- select * from constuctor.type_component_updated;
-- select * from constuctor.type_component_get_filter;

-- Очистка
drop table if exists constuctor.type_component cascade;
-- ALTER SEQUENCE constuctor.type_component_id_seq RESTART WITH 1;

create table constuctor.type_component (
	id int4 not null generated always as identity, -- Первичный ключ
	"name" varchar not null, -- Название типа компонента
	description varchar null, -- Описание типа компонента
	active bool not null default true, -- Актуальность типа компонента
	const_name varchar not null, -- 'Программное название типа компонента'

	constraint type_component_pk primary key (id)
);

create unique index type_component_const_name_idx on constuctor.type_component using btree (const_name);
create unique index type_component_name_idx on constuctor.type_component using btree (name);

--  comments
comment on table constuctor.type_component is 'Тип компонента';

comment on column constuctor.type_component.id is 'Первичный ключ';
comment on column constuctor.type_component."name" is 'Название типа компонента';
comment on column constuctor.type_component.description is 'Описание типа компонента';
comment on column constuctor.type_component.active is 'Актуальность типа компонента';
comment on column constuctor.type_component.const_name is 'Программное название типа компонента';

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
		error_id_const_name int = 1;
		error_id_name int = 2;
		error_array int[];
    begin 
	    select count(*) into count_name from constuctor.type_component_get_filter(null, null, _name, null, _id);
	   	select count(*) into count_const_name from constuctor.type_component_get_filter(null, null, null, _const_name, _id);

	   	if count_name <> 0 then
			error_array = array_append(error_array, error_id_const_name);
	   	end if;	
	   		
	   	if count_const_name <> 0 then	
			error_array = array_append(error_array, error_id_name);
	   	end if;

		if array_length(error_array, 1) <> 0 then
			select * into errors_ from public.create_error_ids(error_array, 400);
			return;
		end if;

	   select * into errors_ from public.create_error_json(null, 200);
    end;
$function$;

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
		error_id int = 3;
    begin
		select count(*) into check_rows from constuctor.type_component_get_filter(_id);
		if check_rows = 0 then
			select * into result_ from public.create_error_ids(array[error_id], 404);
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

drop function if exists constuctor.type_component_get_filter;
create or replace function constuctor.type_component_get_filter(
	_id int = null,
	_active bool = null,
	_name varchar = null,
	_const_name varchar = null,
	_no_id int = null
)
	returns SETOF constuctor.return_type_component
	language  plpgsql
	as $function$
    begin 
        return query 
        	select tc.id, tc."name", tc.description, tc.active, tc.const_name  
       		from constuctor.type_component tc 
       		where (tc.id = _id or _id is null) 
			and (tc.id <> _no_id or _no_id is null) 
       		and (tc.const_name = _const_name or _const_name is null)
       		and (tc.name = _name or _name is null)
       		and (tc.active  = _active or _active is null);
    end;
$function$;

drop function if exists constuctor.type_component_get_unique;
create or replace function constuctor.type_component_get_unique(
	_column_name varchar,
	_id int = null,
	_active bool = null,
	_name varchar = null,
	_const_name varchar = null
)
	returns table(id int, name varchar) 
	language  plpgsql
	as $function$
    begin 
	    if _column_name in ('name', 'const_name') then
	    	return query EXECUTE 
	    		format(
	    			'select id, %s from (select * from constuctor.type_component_get_filter(%2$L, %3$L, %4$L, %5$L)) as tc', 
					_column_name, _id, _active, _name, _const_name
				);
	    end if;
    end;
$function$;
