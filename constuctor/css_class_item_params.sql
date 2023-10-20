-- fun

--select * from constuctor.css_class_item_params_check_unieue;
--select * from constuctor.css_class_item_params_insert;
--select * from constuctor.css_class_item_params_get_filter;
--select * from constuctor.css_class_item_params_updated;
--select * from constuctor.css_class_item_params_check_id;

-- Очистка

drop table if exists constuctor.css_class_item_params cascade;
-- alter sequence constuctor.css_class_item_params_id_seq restart with 1;

create table constuctor.css_class_item_params (
    id int4 generated always as identity, -- Первичный ключ
    id_params_css_class int4 not null REFERENCES constuctor.params_css_class (id), -- Внешний ключ таблицы params_css_class
    name varchar not null, -- Имя элемента списка для параметра css класса
    value varchar not null, -- const_name элемента списка для параметра css класса
    description varchar, -- Описание элемента списка для параметра css класса
    active boolean default true, -- Активность элемента списка для параметра css класса
	constraint css_class_item_params_pk primary key (id)
);
--  comments
comment on table constuctor.css_class_item_params is 'Элемент список для css параметров класса';

comment on column constuctor.css_class_item_params.id is 'Первичный ключ';
comment on column constuctor.css_class_item_params.id_params_css_class is 'Внешний ключ таблицы params_css_class';
comment on column constuctor.css_class_item_params.name is 'Имя элемента списка для параметра css класса';
comment on column constuctor.css_class_item_params.value is 'const_name элемента списка для параметра css класса';
comment on column constuctor.css_class_item_params.description is 'Описание элемента списка для параметра css класса';
comment on column constuctor.css_class_item_params.active is 'Активность элемента списка для параметра css класса';

-- function

drop function if exists constuctor.css_class_item_params_get_filter;
create or replace function constuctor.css_class_item_params_get_filter(
	_id int4 = null,
	_id_params_css_class int4 = null,
	_name varchar = null,
	_value varchar = null,
	_active boolean = null,
	_no_id int4 = null,
	_limit int = null,
	_offset int = null
)
	returns SETOF constuctor.css_class_item_params
	language plpgsql
	as $function$
	begin
		return query 
			select * from constuctor.css_class_item_params ccip
			where (ccip.id = _id or _id is null)
			and (ccip.id <> _no_id or _no_id is null)
			and (ccip.id_params_css_class = _id_params_css_class or _id_params_css_class is null)
			and (ccip.name = _name or _name is null)
			and (ccip.value = _value or _value is null)
			and (ccip.active = _active or _active is null)
			limit _limit offset _offset;
	end;
$function$;

drop function if exists constuctor.css_class_item_params_check_unieue;
create or replace function constuctor.css_class_item_params_check_unieue(
	in _id int4 = null,
	out errors_ json
)
	language plpgsql
	as $function$
	declare
		error_array int[];
	begin

		if array_length(error_array, 1) <> 0 then
			select * into errors_ from public.create_error_ids(error_array, 400);
			return;
		end if;

		select * into errors_ from public.create_error_json(null, 200);
	end;
$function$;

drop function if exists constuctor.css_class_item_params_insert;
create or replace function constuctor.css_class_item_params_insert(
	in _id_params_css_class int4,
	in _name varchar,
	in _value varchar,
	in _description varchar = null,
	in _active boolean = true,
    out id_ int,
    out result_ json
)
	language plpgsql
	as $function$
	begin
		select * into result_ from constuctor.params_css_class_check_id(_id => _id_params_css_class);
		if (result_::json->'status_result')::text::int = 404 then
			return;
		end if;

		select * into result_ from constuctor.css_class_item_params_check_unieue();
		if (result_::json->'status_result')::text::int = 200 then
			insert into constuctor.css_class_item_params (id_params_css_class, name, value, description, active)
			values (_id_params_css_class, _name, _value, _description, _active)
			returning id into id_;
		end if;
	end;
$function$;

drop function if exists constuctor.css_class_item_params_updated;
create or replace function constuctor.css_class_item_params_updated(
	in _id int4,
	in _id_params_css_class int4,
	in _name varchar,
	in _value varchar,
	in _description varchar,
	in _active boolean,
	out result_ json
)
	language plpgsql
	as $function$
	begin
		select * into result_ from constuctor.css_class_item_params_check_id(_id => _id);
		if (result_::json->'status_result')::text::int = 404 then
			return;
		end if;

		select * into result_ from constuctor.params_css_class_check_id(_id => _id_params_css_class);
		if (result_::json->'status_result')::text::int = 404 then
			return;
		end if;

		select * into result_ from constuctor.css_class_item_params_check_unieue( _id => _id);
		if (result_::json->'status_result')::text::int = 200 then
			update constuctor.css_class_item_params
			set id_params_css_class = _id_params_css_class, name = _name, value = _value, description = _description, active = _active
			where id = _id;
		end if;
	end;
$function$;

drop function if exists constuctor.css_class_item_params_check_id;
create or replace function constuctor.css_class_item_params_check_id(
	in _id int4,
	out result_ json
)
	language plpgsql
	as $function$
	declare
		check_rows int;
		error_id int = 10;
	begin
		select * into result_ from public.create_error_ids(null, 200);
		select count(*) into check_rows from constuctor.css_class_item_params_get_filter(_id => _id);
		if check_rows = 0 then
			select * into result_ from public.create_error_ids(array[error_id], 404);
		end if;
	end;
$function$;