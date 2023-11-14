drop table if exists constructor.component_params_type cascade;
create table constructor.component_params_type (
	id int4 generated always as identity, -- Первичный ключ
	name varchar not null, -- name типа параметра компонента
	const_name varchar not null, -- const_name типа параметра компонента
	description varchar, -- Описание типа параметра компонента
	active boolean default true, -- Активность типа параметра компонента
	constraint component_params_type_pk primary key (id)
);

create unique index component_params_type_name_idx on constructor.component_params_type  using btree (name);    
create unique index component_params_type_const_name_idx on constructor.component_params_type  using btree (const_name);

comment on table constructor.component_params_type is 'Тип параметра компонента';

comment on column constructor.component_params_type.id is 'Первичный ключ';
comment on column constructor.component_params_type.name is 'name типа параметра компонента';
comment on column constructor.component_params_type.const_name is 'const_name типа параметра компонента';
comment on column constructor.component_params_type.description is 'Описание типа параметра компонента';
comment on column constructor.component_params_type.active is 'Активность типа параметра компонента';

drop function if exists constructor.component_params_type_get_filter;
create or replace function constructor.component_params_type_get_filter(
	_no_id int4 = null,
	_id int4 = null,
	_name varchar = null,
	_const_name varchar = null,
	_description varchar = null,
	_active boolean = null,
	_limit int = null,
	_offset int = null
)
	returns setof constructor.component_params_type
	language plpgsql
	as $function$
	declare 
	begin 
		return query select * from constructor.component_params_type pt
			where (pt.id <> _no_id or _no_id is null)
				and(pt.id = _id or _id is null)
				and(pt.name = _name or _name is null)
				and(pt.const_name = _const_name or _const_name is null)
				and(pt.description = _description or _description is null)
				and(pt.active = _active or _active is null)
			limit _limit offset _offset;
	end;
$function$;

drop function if exists constructor.component_params_type_check_id;
create or replace function constructor.component_params_type_check_id(
	in _id int4,
	out result_ json
)
	returns json
	language plpgsql
	as $function$
	declare 
		check_rows int;
		error_id int = 13;
	begin 
		select * into result_ from public.create_error_ids(null, 200);
		select count(*) into check_rows from constructor.component_params_type_get_filter(_id => _id);
		if check_rows = 0 then
			select * into result_ from public.create_error_ids(array[error_id], 404);
		end if;
	end;
$function$;

drop function if exists constructor.component_params_type_check_unique;
create or replace function constructor.component_params_type_check_unique(
	in _name varchar,
	in _const_name varchar,
	in _id int4 = null,
	out errors_ json
)
	returns json
	language plpgsql
	as $function$
	declare 
		count_name int;
		count_const_name int;
		error_id_name int = 14;
		error_id_const_name int = 15;
		error_array int[];
	begin 

		select count(*) into count_name 
		from constructor.component_params_type_get_filter(_name => _name, _no_id => _id);

		if count_name <> 0 then
			error_array = array_append(error_array, error_id_name);
		end if;

		select count(*) into count_const_name 
		from constructor.component_params_type_get_filter(_const_name => _const_name, _no_id => _id);

		if count_const_name <> 0 then
			error_array = array_append(error_array, error_id_const_name);
		end if;

		if array_length(error_array, 1) <> 0 then
			select * into errors_ from public.create_error_ids(error_array, 400);
			return;
		end if;

		select * into errors_ from public.create_error_json(null, 200);
	end;
$function$;

drop function if exists constructor.component_params_type_insert;
create or replace function constructor.component_params_type_insert(
	in _name varchar,
	in _const_name varchar,
	in _description varchar = null,
	in _active boolean = true,
	out id_ int,
	out result_ json
)
	returns record
	language plpgsql
	as $function$
	declare 
	begin 		

		select * into result_ from constructor.component_params_type_check_unique(_name => _name, _const_name => _const_name);
		if (result_::json->'status_result')::text::int = 400 then
			return;
		end if;

		insert into constructor.component_params_type (name, const_name, description, active) 
		values (_name, _const_name, _description, _active)
		returning id into id_;
	end;
$function$;

drop function if exists constructor.component_params_type_updated;
create or replace function constructor.component_params_type_updated(
	in _id int4,
	in _name varchar,
	in _const_name varchar,
	in _description varchar = null,
	in _active boolean = true,
	out result_ json
)
	returns json
	language plpgsql
	as $function$
	declare 
	begin 
		select * into result_ from constructor.component_params_type_check_id(_id => _id);
		if (result_::json->'status_result')::text::int = 404 then
			return;
		end if;

		select * into result_ from constructor.component_params_type_check_unique(_name => _name, _const_name => _const_name, _id => _id);
		if (result_::json->'status_result')::text::int = 400 then
			return;
		end if;

		update constructor.component_params_type
		set name = _name, const_name = _const_name, description = _description, active = _active
		where id = _id;
	end;
$function$;