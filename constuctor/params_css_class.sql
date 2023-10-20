-- fun

--select * from constuctor.params_css_class_check_unieue;
--select * from constuctor.params_css_class_insert;
--select * from constuctor.params_css_class_get_filter;
--select * from constuctor.params_css_class_updated;
--select * from constuctor.params_css_class_check_id;

-- Очистка

drop table if exists constuctor.params_css_class cascade;
-- alter sequence constuctor.params_css_class_id_seq restart with 1;

create table constuctor.params_css_class (
    id int4 generated always as identity, -- Первичный ключ
    id_type_css_var int4 not null REFERENCES constuctor.type_css_var (id), -- Внешний ключ таблицы type_css_var
    id_css_class int4 not null REFERENCES constuctor.css_class (id), -- Внешний ключ таблицы css_class
    name varchar not null, -- Имя параметра css класса
    const_name varchar not null, -- const_name параметра css класса
    description varchar, -- Описание параметра css класса
    active boolean default true, -- Активность параметра css класса
	constraint params_css_class_pk primary key (id)
);
--  comments
comment on table constuctor.params_css_class is 'параметры css классов';

comment on column constuctor.params_css_class.id is 'Первичный ключ';
comment on column constuctor.params_css_class.id_type_css_var is 'Внешний ключ таблицы type_css_var';
comment on column constuctor.params_css_class.id_css_class is 'Внешний ключ таблицы css_class';
comment on column constuctor.params_css_class.name is 'Имя параметра css класса';
comment on column constuctor.params_css_class.const_name is 'const_name параметра css класса';
comment on column constuctor.params_css_class.description is 'Описание параметра css класса';
comment on column constuctor.params_css_class.active is 'Активность параметра css класса';

-- function

drop function if exists constuctor.params_css_class_get_filter;
create or replace function constuctor.params_css_class_get_filter(
	_id int4 = null,
	_id_type_css_var int4 = null,
	_id_css_class int4 = null,
	_name varchar = null,
	_const_name varchar = null,
	_active boolean = null,
	_no_id int4 = null,
	_limit int = null,
	_offset int = null
)
	returns SETOF constuctor.params_css_class
	language plpgsql
	as $function$
	begin
		return query 
			select * from constuctor.params_css_class pcc
			where (pcc.id = _id or _id is null)
			and (pcc.id <> _no_id or _no_id is null)
			and (pcc.id_type_css_var = _id_type_css_var or _id_type_css_var is null)
			and (pcc.id_css_class = _id_css_class or _id_css_class is null)
			and (pcc.name = _name or _name is null)
			and (pcc.const_name = _const_name or _const_name is null)
			and (pcc.active = _active or _active is null)
			limit _limit offset _offset;
	end;
$function$;

drop function if exists constuctor.params_css_class_check_unieue;
create or replace function constuctor.params_css_class_check_unieue(
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

drop function if exists constuctor.params_css_class_insert;
create or replace function constuctor.params_css_class_insert(
	in _id_type_css_var int4,
	in _id_css_class int4,
	in _name varchar,
	in _const_name varchar,
	in _description varchar = null,
	in _active boolean = true,
    out id_ int,
    out result_ json
)
	language plpgsql
	as $function$
	begin
		select * into result_ from constuctor.type_css_var_check_id(_id => _id_type_css_var);
		if (result_::json->'status_result')::text::int = 404 then
			return;
		end if;

		select * into result_ from constuctor.css_class_check_id(_id => _id_css_class);
		if (result_::json->'status_result')::text::int = 404 then
			return;
		end if;

		select * into result_ from constuctor.params_css_class_check_unieue();
		if (result_::json->'status_result')::text::int = 200 then
			insert into constuctor.params_css_class (id_type_css_var, id_css_class, name, const_name, description, active)
			values (_id_type_css_var, _id_css_class, _name, _const_name, _description, _active)
			returning id into id_;
		end if;
	end;
$function$;

drop function if exists constuctor.params_css_class_updated;
create or replace function constuctor.params_css_class_updated(
	in _id int4,
	in _id_type_css_var int4,
	in _id_css_class int4,
	in _name varchar,
	in _const_name varchar,
	in _description varchar,
	in _active boolean,
	out result_ json
)
	language plpgsql
	as $function$
	begin
		select * into result_ from constuctor.params_css_class_check_id(_id => _id);
		if (result_::json->'status_result')::text::int = 404 then
			return;
		end if;

		select * into result_ from constuctor.type_css_var_check_id(_id => _id_type_css_var);
		if (result_::json->'status_result')::text::int = 404 then
			return;
		end if;

		select * into result_ from constuctor.css_class_check_id(_id => _id_css_class);
		if (result_::json->'status_result')::text::int = 404 then
			return;
		end if;

		select * into result_ from constuctor.params_css_class_check_unieue( _id => _id);
		if (result_::json->'status_result')::text::int = 200 then
			update constuctor.params_css_class
			set id_type_css_var = _id_type_css_var, id_css_class = _id_css_class, name = _name, const_name = _const_name, description = _description, active = _active
			where id = _id;
		end if;
	end;
$function$;

drop function if exists constuctor.params_css_class_check_id;
create or replace function constuctor.params_css_class_check_id(
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
		select count(*) into check_rows from constuctor.params_css_class_get_filter(_id => _id);
		if check_rows = 0 then
			select * into result_ from public.create_error_ids(array[error_id], 404);
		end if;
	end;
$function$;

