-- fun

--select * from constructor.type_css_var_check_unieue;
--select * from constructor.type_css_var_insert;
--select * from constructor.type_css_var_get_filter;
--select * from constructor.type_css_var_updated;
--select * from constructor.type_css_var_check_id;

-- Очистка

drop table if exists constructor.type_css_var cascade;
-- alter sequence constructor.type_css_var_id_seq restart with 1;

create table constructor.type_css_var (
    id int4 generated always as identity, -- Первичный ключ
    name varchar not null, -- Имя типа css переменной
    description varchar, -- Описание типа css переменной
    active boolean default true, -- Активность типа css переменной
    const_name varchar not null, -- Программное название типа css переменной
	constraint type_css_var_pk primary key (id)
);

create unique index type_css_var_name_idx on constructor.type_css_var using btree (name);
create unique index type_css_var_const_name_idx on constructor.type_css_var using btree (const_name);

--  comments
comment on table constructor.type_css_var is 'Тип css переменной, нужен для возможности определить тип css переменной отображаемый в таблице params_css_class';

comment on column constructor.type_css_var.id is 'Первичный ключ';
comment on column constructor.type_css_var.name is 'Имя типа css переменной';
comment on column constructor.type_css_var.description is 'Описание типа css переменной';
comment on column constructor.type_css_var.active is 'Активность типа css переменной';
comment on column constructor.type_css_var.const_name is 'Программное название типа css переменной';

-- function

drop function if exists constructor.type_css_var_get_filter;
create or replace function constructor.type_css_var_get_filter(
	_id int4 = null,
	_name varchar = null,
	_active boolean = null,
	_const_name varchar = null,
	_no_id int4 = null,
	_limit int = null,
	_offset int = null
)
	returns SETOF constructor.type_css_var
	language plpgsql
	as $function$
	begin
		return query 
			select * from constructor.type_css_var tcv
			where (tcv.id = _id or _id is null)
			and (tcv.id <> _no_id or _no_id is null)
			and (tcv.name = _name or _name is null)
			and (tcv.active = _active or _active is null)
			and (tcv.const_name = _const_name or _const_name is null)
			limit _limit offset _offset;
	end;
$function$;

drop function if exists constructor.type_css_var_check_unieue;
create or replace function constructor.type_css_var_check_unieue(
	in _id int4 = null,
	in _name varchar = null,
	in _const_name varchar = null,
	out errors_ json
)
	language plpgsql
	as $function$
	declare
		count_name int;
		count_const_name int;
		error_id_name int = 5;
		error_id_const_name int = 6;
		error_array int[];
	begin
		select count(*) into count_name from constructor.type_css_var_get_filter(_name => _name, _no_id => _id);
		select count(*) into count_const_name from constructor.type_css_var_get_filter(_const_name => _const_name, _no_id => _id);

		if count_name <> 0 then
			error_array = array_append(error_array, error_id_name);
		end if;

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

drop function if exists constructor.type_css_var_insert;
create or replace function constructor.type_css_var_insert(
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
		select * into result_ from constructor.type_css_var_check_unieue(_name => _name, _const_name => _const_name);
		if (result_::json->'status_result')::text::int = 200 then
			insert into constructor.type_css_var (name, description, active, const_name)
			values (_name, _description, _active, _const_name)
			returning id into id_;
		end if;
	end;
$function$;

drop function if exists constructor.type_css_var_updated;
create or replace function constructor.type_css_var_updated(
	in _id int4,
	in _name varchar,
	in _description varchar,
	in _active boolean,
	in _const_name varchar,
	out result_ json
)
	language plpgsql
	as $function$
	begin
		select * into result_ from constructor.type_css_var_check_id(_id => _id);
		if (result_::json->'status_result')::text::int = 404 then
			return;
		end if;

		select * into result_ from constructor.type_css_var_check_unieue(_name => _name, _const_name => _const_name, _id => _id);
		if (result_::json->'status_result')::text::int = 200 then
			update constructor.type_css_var
			set name = _name, description = _description, active = _active, const_name = _const_name
			where id = _id;
		end if;
	end;
$function$;

drop function if exists constructor.type_css_var_check_id;
create or replace function constructor.type_css_var_check_id(
	in _id int4,
	out result_ json
)
	language plpgsql
	as $function$
	declare
		check_rows int;
		error_id int = 4;
	begin
		select * into result_ from public.create_error_ids(null, 200);
		select count(*) into check_rows from constructor.type_css_var_get_filter(_id => _id);
		if check_rows = 0 then
			select * into result_ from public.create_error_ids(array[error_id], 404);
		end if;
	end;
$function$;


insert into constructor.type_css_var(id, name, description, active, const_name)
overriding system value values(1, 'Единица измерения', 'Размер ширины, высоты, позиции элементов и др. что вводится значения число и ед. размера(px, %, em,rem и тд) ', true, 'size');

insert into constructor.type_css_var(id, name, description, active, const_name)
overriding system value values(2, 'Граница', 'Граница', true, 'border');

insert into constructor.type_css_var(id, name, description, active, const_name)
overriding system value values(3, 'Цвет', 'Цвет', true, 'color');

insert into constructor.type_css_var(id, name, description, active, const_name)
overriding system value values(4, 'Отступы', 'Отступы', true, 'margin/padding');

insert into constructor.type_css_var(id, name, description, active, const_name)
overriding system value values(5, 'Список значении', 'Свойство с ограниченным списком значения', true, 'select');