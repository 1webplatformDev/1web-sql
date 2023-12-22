drop table if exists constructor.component_method cascade;
create table constructor.component_method (
	id int4 generated always as identity, -- Первичный ключ
	const_name varchar not null, -- const_name метода компонента
	name varchar not null, -- name метода компонента
	ids_type_component int4 [], -- Массив внешних ключей таблицы type_component
	description varchar, -- Описание метода компонента
	active boolean default true, -- Активность метода компонента
	params json[], -- Параметры метода в формате [{name: name, type: type}] - где от type берется const_name из component_params_type
	constraint component_method_pk primary key (id)
);

create unique index component_method_const_name_idx on constructor.component_method  using btree (const_name);
create unique index component_method_name_idx on constructor.component_method  using btree (name);

comment on table constructor.component_method is 'Методы компонента';

comment on column constructor.component_method.id is 'Первичный ключ';
comment on column constructor.component_method.const_name is 'const_name метода компонента';
comment on column constructor.component_method.name is 'name метода компонента';
comment on column constructor.component_method.ids_type_component is 'Массив внешних ключей таблицы type_component';
comment on column constructor.component_method.description is 'Описание метода компонента';
comment on column constructor.component_method.active is 'Активность метода компонента';
comment on column constructor.component_method.params is 'Параметры метода в формате [{name: name, type: type, description: description}] - где от type берется const_name из component_params_type';

drop function if exists constructor.component_method_get_filter;
create or replace function constructor.component_method_get_filter(
	_no_id int4 = null,
	_id int4 = null,
	_const_name varchar = null,
	_name varchar = null,
	_active boolean = null,
	_params json[] = null,
	_limit int = null,
	_offset int = null
)
	returns setof constructor.component_method
	language plpgsql
	as $function$
	declare 
	begin 
		return query select * from constructor.component_method cm
			where (cm.id <> _no_id or _no_id is null)
				and(cm.id = _id or _id is null)
				and(cm.const_name = _const_name or _const_name is null)
				and(cm.name = _name or _name is null)
				and(cm.active = _active or _active is null)
				and(cm.params = _params or _params is null)
			limit _limit offset _offset;
	end;
$function$;

drop function if exists constructor.component_method_check_id;
create or replace function constructor.component_method_check_id(
	in _id int4,
	out result_ json
)
	returns json
	language plpgsql
	as $function$
	declare 
		check_rows int;
		error_id int = 21;
	begin 
		select * into result_ from public.create_error_ids(null, 200);
		select count(*) into check_rows from constructor.component_method_get_filter(_id => _id);
		if check_rows = 0 then
			select * into result_ from public.create_error_ids(array[error_id], 404);
		end if;
	end;
$function$;

drop function if exists constructor.component_method_check_unique;
create or replace function constructor.component_method_check_unique(
	in _const_name varchar,
	in _name varchar,
	in _id int4 = null,
	out errors_ json
)
	returns json
	language plpgsql
	as $function$
	declare 
		count_const_name int;
		count_name int;
		error_id_const_name int = 22;
		error_id_name int = 23;
		error_array int[];
	begin 

		select count(*) into count_const_name 
		from constructor.component_method_get_filter(_const_name => _const_name, _no_id => _id);

		if count_const_name <> 0 then
			error_array = array_append(error_array, error_id_const_name);
		end if;

		select count(*) into count_name 
		from constructor.component_method_get_filter(_name => _name, _no_id => _id);

		if count_name <> 0 then
			error_array = array_append(error_array, error_id_name);
		end if;

		if array_length(error_array, 1) <> 0 then
			select * into errors_ from public.create_error_ids(error_array, 400);
			return;
		end if;

		select * into errors_ from public.create_error_json(null, 200);
	end;
$function$;

drop function if exists constructor.component_method_insert;
create or replace function constructor.component_method_insert(
	in _const_name varchar,
	in _name varchar,
	in _ids_type_component int4 [] = null,
	in _description varchar = null,
	in _active boolean = true,
	in _params json[] = null,
	out id_ int,
	out result_ json
)
	returns record
	language plpgsql
	as $function$
	declare 
		errors_text json[];
		error_text json;
	begin 

		select * into result_ from constructor.component_method_check_unique(_const_name => _const_name, _name => _name);
		if (result_::json->'status_result')::text::int = 400 then
			return;
		end if;

		select _result_ids, _result into _ids_type_component, error_text
		from constructor.type_component_check_array_id(_ids_type_component);
		if error_text is not null then
			errors_text = array_append(errors_text, error_text);
		end if;

		if array_length(errors_text, 1) <> 0 then
			select * into result_ from create_result_json(_warning => errors_text);
		end if;

		insert into constructor.component_method (const_name, name, ids_type_component, description, active, params) 
		values (_const_name, _name, _ids_type_component, _description, _active, _params)
		returning id into id_;
	end;
$function$;

drop function if exists constructor.component_method_updated;
create or replace function constructor.component_method_updated(
	in _id int4,
	in _const_name varchar,
	in _name varchar,
	in _ids_type_component int4 [] = null,
	in _description varchar = null,
	in _active boolean = true,
	in _params json[] = null,
	out result_ json
)
	returns json
	language plpgsql
	as $function$
	declare 
		errors_text json[];
		error_text json;
	begin 
		select * into result_ from constructor.component_method_check_id(_id => _id);
		if (result_::json->'status_result')::text::int = 404 then
			return;
		end if;

		select * into result_ from constructor.component_method_check_unique(_const_name => _const_name, _name => _name, _id => _id);
		if (result_::json->'status_result')::text::int = 400 then
			return;
		end if;

		select _result_ids, _result into _ids_type_component, error_text
		from constructor.type_component_check_array_id(_ids_type_component);
		if error_text is not null then
			errors_text = array_append(errors_text, error_text);
		end if;

		if array_length(errors_text, 1) <> 0 then
			select * into result_ from create_result_json(_warning => errors_text);
		end if;

		update constructor.component_method
		set const_name = _const_name, name = _name, ids_type_component = _ids_type_component, description = _description, active = _active, params = _params
		where id = _id;
	end;
$function$;
 