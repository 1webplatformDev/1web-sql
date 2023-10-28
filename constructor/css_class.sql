-- fun

--select * from constructor.css_class_check_unieue;
--select * from constructor.css_class_insert;
--select * from constructor.css_class_get_filter;
--select * from constructor.css_class_updated;
--select * from constructor.css_class_check_id;
--select * from constructor.css_class_get_tc;

-- Очистка

drop table if exists constructor.css_class cascade;
-- alter sequence constructor.css_class_id_seq restart with 1;

create table constructor.css_class (
    id int4 generated always as identity, -- Первичный ключ
    id_type_component int4 REFERENCES constructor.type_component (id), -- Внешний ключ таблицы type_component
    class_name varchar not null, -- Имя css class
    description varchar, -- Описание css class
    active boolean default true, -- Активность css class
	constraint css_class_pk primary key (id)
);

create unique index css_class_class_name_idx on constructor.css_class using btree (class_name);

--  comments
comment on table constructor.css_class is 'css класс, нужен для возможности задать допустимый класс любому компоненту';

comment on column constructor.css_class.id is 'Первичный ключ';
comment on column constructor.css_class.id_type_component is 'Внешний ключ таблицы type_component';
comment on column constructor.css_class.class_name is 'Имя css class';
comment on column constructor.css_class.description is 'Описание css class';
comment on column constructor.css_class.active is 'Активность css class';

-- function

drop function if exists constructor.css_class_get_filter;
create or replace function constructor.css_class_get_filter(
	_id int4 = null,
	_id_type_component int4 = null,
	_class_name varchar = null,
	_active boolean = null,
	_no_id int4 = null,
	_limit int = null,
	_offset int = null
)
	returns SETOF constructor.css_class
	language plpgsql
	as $function$
	begin
		return query 
			select * from constructor.css_class cc
			where (cc.id = _id or _id is null)
			and (cc.id <> _no_id or _no_id is null)
			and (cc.id_type_component = _id_type_component or _id_type_component is null)
			and (cc.class_name = _class_name or _class_name is null)
			and (cc.active = _active or _active is null)
			limit _limit offset _offset;
	end;
$function$;

drop function if exists constructor.css_class_check_unieue;
create or replace function constructor.css_class_check_unieue(
	in _id int4 = null,
	in _class_name varchar = null,
	out errors_ json
)
	language plpgsql
	as $function$
	declare
		count_class_name int;
		error_id_class_name int = 8;
		error_array int[];
	begin
		select count(*) into count_class_name from constructor.css_class_get_filter(_class_name => _class_name, _no_id => _id);

		if count_class_name <> 0 then
			error_array = array_append(error_array, error_id_class_name);
		end if;

		if array_length(error_array, 1) <> 0 then
			select * into errors_ from public.create_error_ids(error_array, 400);
			return;
		end if;

		select * into errors_ from public.create_error_json(null, 200);
	end;
$function$;

drop function if exists constructor.css_class_insert;
create or replace function constructor.css_class_insert(
	in _id_type_component int4,
	in _class_name varchar,
	in _description varchar = null,
	in _active boolean = true,
    out id_ int,
    out result_ json
)
	language plpgsql
	as $function$
	begin
		select * into result_ from constructor.type_component_check_id(_id => _id_type_component);
		if (result_::json->'status_result')::text::int = 404 then
			return;
		end if;

		select * into result_ from constructor.css_class_check_unieue(_class_name => _class_name);
		if (result_::json->'status_result')::text::int = 200 then
			insert into constructor.css_class (id_type_component, class_name, description, active)
			values (_id_type_component, _class_name, _description, _active)
			returning id into id_;
		end if;
	end;
$function$;

drop function if exists constructor.css_class_updated;
create or replace function constructor.css_class_updated(
	in _id int4,
	in _id_type_component int4,
	in _class_name varchar,
	in _description varchar,
	in _active boolean,
	out result_ json
)
	language plpgsql
	as $function$
	begin
		select * into result_ from constructor.css_class_check_id(_id => _id);
		if (result_::json->'status_result')::text::int = 404 then
			return;
		end if;

		select * into result_ from constructor.type_component_check_id(_id => _id_type_component);
		if (result_::json->'status_result')::text::int = 404 then
			return;
		end if;

		select * into result_ from constructor.css_class_check_unieue(_class_name => _class_name, _id => _id);
		if (result_::json->'status_result')::text::int = 200 then
			update constructor.css_class
			set id_type_component = _id_type_component, class_name = _class_name, description = _description, active = _active
			where id = _id;
		end if;
	end;
$function$;

drop function if exists constructor.css_class_check_id;
create or replace function constructor.css_class_check_id(
	in _id int4,
	out result_ json
)
	language plpgsql
	as $function$
	declare
		check_rows int;
		error_id int = 7;
	begin
		select * into result_ from public.create_error_ids(null, 200);
		select count(*) into check_rows from constructor.css_class_get_filter(_id => _id);
		if check_rows = 0 then
			select * into result_ from public.create_error_ids(array[error_id], 404);
		end if;
	end;
$function$;

drop function if exists constructor.css_class_get_tc;
create or replace function constructor.css_class_get_tc(
	_id_type_component int[] = null,
	_class_name varchar = null,
	_limit int = null,
	_offset int = null
)
	returns table (
		id int, 
		id_type_component int, 
		class_name varchar, 
		description varchar, 
		active boolean, 
		tc_name varchar,
		tc_description varchar,
		tc_active boolean,
		tc_const_name varchar
		)
	language plpgsql
	as $function$
	begin
		return query 
		select cc.*, 
			tc."name" as tc_name, 
			tc.description as tc_description,
			tc.active as tc_active,
			tc.const_name as tc_const_name
		from constructor.css_class cc 
		left join constructor.type_component tc on tc.id = cc.id_type_component
		where 
			((cc.class_name like '%' || _class_name || '%') or _class_name is null)
			and (cc.id_type_component = any(_id_type_component) or _id_type_component is null)
		limit _limit offset _offset;
	end
$function$;

-- dataset

insert into constructor.css_class(id, id_type_component, class_name, description, active)
overriding system value values(1, null, 'component', 'Базовый класс применяемый к любому компоненту', true);

insert into constructor.css_class(id, id_type_component, class_name, description, active)
overriding system value values(2, null, 'flex', 'Базовый класс применяющий к flex элементам', true);