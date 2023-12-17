drop table if exists constructor.component_params cascade;
create table constructor.component_params (
	id int4 generated always as identity, -- Первичный ключ
	const_name varchar not null, -- const_name параметра компонента
	id_component_params_type int4 REFERENCES constructor.component_params_type (id), -- Внешний ключ таблицы component_params_type
	select_list json, -- Список значений параметра компонента в виде {id: name}
	description varchar, -- Описание параметра компонента
	active boolean default true, -- Активность параметра компонента
	ids_type_component int4 [], -- Массив внешних ключей таблицы type_component
	constraint component_params_pk primary key (id)
);

create unique index component_params_const_name_idx on constructor.component_params  using btree (const_name);

comment on table constructor.component_params is 'Параметры компонента';

comment on column constructor.component_params.id is 'Первичный ключ';
comment on column constructor.component_params.const_name is 'const_name параметра компонента';
comment on column constructor.component_params.id_component_params_type is 'Внешний ключ таблицы component_params_type';
comment on column constructor.component_params.select_list is 'Список значений параметра компонента в виде {id: name}';
comment on column constructor.component_params.description is 'Описание параметра компонента';
comment on column constructor.component_params.active is 'Активность параметра компонента';
comment on column constructor.component_params.ids_type_component is 'Массив внешних ключей таблицы type_component';

drop function if exists constructor.component_params_get_filter;
create or replace function constructor.component_params_get_filter(
	_no_id int4 = null,
	_id int4 = null,
	_const_name varchar = null,
	_id_component_params_type int4 = null,
	_select_list json = null,
	_description varchar = null,
	_active boolean = null,
	_limit int = null,
	_offset int = null
)
	returns setof constructor.component_params
	language plpgsql
	as $function$
	declare 
	begin 
		return query select * from constructor.component_params p
			where (p.id <> _no_id or _no_id is null)
				and(p.id = _id or _id is null)
				and(p.const_name = _const_name or _const_name is null)
				and(p.id_component_params_type = _id_component_params_type or _id_component_params_type is null)
				and(p.select_list = _select_list or _select_list is null)
				and(p.description = _description or _description is null)
				and(p.active = _active or _active is null)
			limit _limit offset _offset;
	end;
$function$;

drop function if exists constructor.component_params_check_id;
create or replace function constructor.component_params_check_id(
	in _id int4,
	out result_ json
)
	returns json
	language plpgsql
	as $function$
	declare 
		check_rows int;
		error_id int = 16;
	begin 
		select * into result_ from public.create_error_ids(null, 200);
		select count(*) into check_rows from constructor.component_params_get_filter(_id => _id);
		if check_rows = 0 then
			select * into result_ from public.create_error_ids(array[error_id], 404);
		end if;
	end;
$function$;

drop function if exists constructor.component_params_check_unique;
create or replace function constructor.component_params_check_unique(
	in _const_name varchar,
	in _id int4 = null,
	out errors_ json
)
	returns json
	language plpgsql
	as $function$
	declare 
		count_const_name int;
		error_id_const_name int = 17;
		error_array int[];
	begin 

		select count(*) into count_const_name 
		from constructor.component_params_get_filter(_const_name => _const_name, _no_id => _id);

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

drop function if exists constructor.component_params_insert;
create or replace function constructor.component_params_insert(
	in _const_name varchar,
	in _id_component_params_type int4 = null,
	in _ids_type_component int4[] = null,
	in _select_list json = null,
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
		select * into result_ from constructor.component_params_type_check_id(_id => _id_component_params_type);
		if (result_::json->'status_result')::text::int = 404 then
			return;
		end if;

		select * into result_ from constructor.component_params_check_unique(_const_name => _const_name);
		if (result_::json->'status_result')::text::int = 400 then
			return;
		end if;

		select _result_ids, _result into _ids_type_component, result_
		from constructor.type_component_check_array_id(_ids_type_component);
		
		insert into constructor.component_params (const_name, id_component_params_type, select_list, description, active) 
		values (_const_name, _id_component_params_type, _select_list, _description, _active)
		returning id into id_;
	end;
$function$;

drop function if exists constructor.component_params_updated;
create or replace function constructor.component_params_updated(
	in _id int4,
	in _const_name varchar,
	in _id_component_params_type int4 = null,
	in _ids_type_component int4[] = null,
	in _select_list json = null,
	in _description varchar = null,
	in _active boolean = true,
	out result_ json
)
	returns json
	language plpgsql
	as $function$
	declare 
	begin 
		select * into result_ from constructor.component_params_type_check_id(_id => _id_component_params_type);
		if (result_::json->'status_result')::text::int = 404 then
			return;
		end if;

		select * into result_ from constructor.component_params_check_id(_id => _id);
		if (result_::json->'status_result')::text::int = 404 then
			return;
		end if;

		select * into result_ from constructor.component_params_check_unique(_const_name => _const_name, _id => _id);
		if (result_::json->'status_result')::text::int = 400 then
			return;
		end if;

		select _result_ids, _result into _ids_type_component, result_
		from constructor.type_component_check_array_id(_ids_type_component);

		update constructor.component_params
		set const_name = _const_name, id_component_params_type = _id_component_params_type, select_list = _select_list, description = _description, active = _active
		where id = _id;
	end;
$function$;