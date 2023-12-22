drop table if exists constructor.component_event cascade;
create table constructor.component_event (
	id int4 generated always as identity, -- Первичный ключ
	const_name varchar not null, -- const_name события компонента
	ids_type_component int4 [], -- Массив внешних ключей таблицы type_component
	description varchar, -- Описание события компонента
	active boolean default true, -- Активность события компонента
	constraint component_event_pk primary key (id)
);

create unique index component_event_const_name_idx on constructor.component_event  using btree (const_name);

comment on table constructor.component_event is 'События компонента';

comment on column constructor.component_event.id is 'Первичный ключ';
comment on column constructor.component_event.const_name is 'const_name события компонента';
comment on column constructor.component_event.ids_type_component is 'Массив внешних ключей таблицы type_component';
comment on column constructor.component_event.description is 'Описание события компонента';
comment on column constructor.component_event.active is 'Активность события компонента';

drop function if exists constructor.component_event_get_filter;
create or replace function constructor.component_event_get_filter(
	_no_id int4 = null,
	_id int4 = null,
	_const_name varchar = null,
	_active boolean = null,
	_limit int = null,
	_offset int = null
)
	returns setof constructor.component_event
	language plpgsql
	as $function$
	declare 
	begin 
		return query select * from constructor.component_event ce
			where (ce.id <> _no_id or _no_id is null)
				and(ce.id = _id or _id is null)
				and(ce.const_name = _const_name or _const_name is null)
				and(ce.active = _active or _active is null)
			limit _limit offset _offset;
	end;
$function$;

drop function if exists constructor.component_event_check_id;
create or replace function constructor.component_event_check_id(
	in _id int4,
	out result_ json
)
	returns json
	language plpgsql
	as $function$
	declare 
		check_rows int;
		error_id int = 18;
	begin 
		select * into result_ from public.create_error_ids(null, 200);
		select count(*) into check_rows from constructor.component_event_get_filter(_id => _id);
		if check_rows = 0 then
			select * into result_ from public.create_error_ids(array[error_id], 404);
		end if;
	end;
$function$;

drop function if exists constructor.component_event_check_unique;
create or replace function constructor.component_event_check_unique(
	in _const_name varchar,
	in _id int4 = null,
	out errors_ json
)
	returns json
	language plpgsql
	as $function$
	declare 
		count_const_name int;
		error_id_const_name int = 19;
		error_array int[];
	begin 

		select count(*) into count_const_name 
		from constructor.component_event_get_filter(_const_name => _const_name, _no_id => _id);

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

drop function if exists constructor.component_event_insert;
create or replace function constructor.component_event_insert(
	in _const_name varchar,
	in _ids_type_component int4 [] = null,
	in _description varchar = null,
	in _active boolean = true,
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
		select * into result_ from constructor.component_event_check_unique(_const_name => _const_name);
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

		insert into constructor.component_event (const_name, ids_type_component, description, active) 
		values (_const_name, _ids_type_component, _description, _active)
		returning id into id_;
	end;
$function$;

drop function if exists constructor.component_event_updated;
create or replace function constructor.component_event_updated(
	in _id int4,
	in _const_name varchar,
	in _ids_type_component int4 [] = null,
	in _description varchar = null,
	in _active boolean = true,
	out result_ json
)
	returns json
	language plpgsql
	as $function$
	declare 
		errors_text json[];
		error_text json;
	begin 
		select * into result_ from constructor.component_event_check_id(_id => _id);
		if (result_::json->'status_result')::text::int = 404 then
			return;
		end if;

		select * into result_ from constructor.component_event_check_unique(_const_name => _const_name, _id => _id);
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

		update constructor.component_event
		set const_name = _const_name, ids_type_component = _ids_type_component, description = _description, active = _active
		where id = _id;
	end;
$function$;

-- dataset

insert into constructor.component_event(id, const_name, ids_type_component, description, active)
overriding system value values(1, 'click', 5,9,21, 'Событие обработки на клик', true);

insert into constructor.component_event(id, const_name, ids_type_component, description, active)
overriding system value values(2, 'focus', null, 'Событие фокус на компоненте', true);

insert into constructor.component_event(id, const_name, ids_type_component, description, active)
overriding system value values(3, 'blur', null, 'Событие потеря фокуса на компоненте', true);

insert into constructor.component_event(id, const_name, ids_type_component, description, active)
overriding system value values(4, 'keydown', null, 'Событие нажатия на клавишу', true);

insert into constructor.component_event(id, const_name, ids_type_component, description, active)
overriding system value values(5, 'keyup', null, 'Событие отпускание клавиши', true);

insert into constructor.component_event(id, const_name, ids_type_component, description, active)
overriding system value values(6, 'mouseover', null, 'Событие наведение мышкой на компонент', true);

insert into constructor.component_event(id, const_name, ids_type_component, description, active)
overriding system value values(7, 'mouseout', null, 'Событие уходамышки из компонента', true);

insert into constructor.component_event(id, const_name, ids_type_component, description, active)
overriding system value values(8, 'input', 	'{3,4,8,10,12,13,14,15}', 'Событие изменения значения у компонента', true);