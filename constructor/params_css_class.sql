-- fun

--select * from constructor.params_css_class_insert;
--select * from constructor.params_css_class_get_filter;
--select * from constructor.params_css_class_updated;
--select * from constructor.params_css_class_check_id;

-- Очистка

drop table if exists constructor.params_css_class cascade;
-- alter sequence constructor.params_css_class_id_seq restart with 1;

create table constructor.params_css_class (
    id int4 generated always as identity, -- Первичный ключ
    id_type_css_var int4 not null REFERENCES constructor.type_css_var (id), -- Внешний ключ таблицы type_css_var
    id_css_class int4 not null REFERENCES constructor.css_class (id), -- Внешний ключ таблицы css_class
	id_css_class_list_params int4 REFERENCES constructor.css_class_list_params (id), -- Внешний ключ таблицы css_class_list_params
    name varchar not null, -- Имя параметра css класса
    const_name varchar not null, -- const_name параметра css класса
    description varchar, -- Описание параметра css класса
    active boolean default true, -- Активность параметра css класса
	constraint params_css_class_pk primary key (id)
);
--  comments
comment on table constructor.params_css_class is 'параметры css классов, нужен для возможности задать css переменные, дает возможность из 1 класса получаться разные результаты стилей';

comment on column constructor.params_css_class.id is 'Первичный ключ';
comment on column constructor.params_css_class.id_type_css_var is 'Внешний ключ таблицы type_css_var';
comment on column constructor.params_css_class.id_css_class is 'Внешний ключ таблицы css_class';
comment on column constructor.params_css_class.name is 'Имя параметра css класса';
comment on column constructor.params_css_class.const_name is 'const_name параметра css класса';
comment on column constructor.params_css_class.description is 'Описание параметра css класса';
comment on column constructor.params_css_class.active is 'Активность параметра css класса';

-- function

drop function if exists constructor.params_css_class_get_filter;
create or replace function constructor.params_css_class_get_filter(
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
	returns SETOF constructor.params_css_class
	language plpgsql
	as $function$
	begin
		return query 
			select * from constructor.params_css_class pcc
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

drop function if exists constructor.params_css_class_insert;
create or replace function constructor.params_css_class_insert(
	in _id_type_css_var int4,
	in _id_css_class int4,
	in id_css_class_list_params int4,
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
		select * into result_ from constructor.type_css_var_check_id(_id => _id_type_css_var);

		if _id_type_css_var <> 5 then -- очистка справочника ибо только у type_css_var = 5 (select) может существовать список допустимых значении
			id_css_class_list_params = null;
		end if;

		if (result_::json->'status_result')::text::int = 404 then
			return;
		end if;

		select * into result_ from constructor.css_class_check_id(_id => _id_css_class);
		if (result_::json->'status_result')::text::int = 404 then
			return;
		end if;

		select * into result_ from constructor.css_class_list_params_check_id(_id => id_css_class_list_params);
		if (result_::json->'status_result')::text::int = 404 then
			return;
		end if;

		insert into constructor.params_css_class (id_type_css_var, id_css_class, name, const_name, description, active)
		values (_id_type_css_var, _id_css_class, _name, _const_name, _description, _active)
		returning id into id_;
	end;
$function$;

drop function if exists constructor.params_css_class_updated;
create or replace function constructor.params_css_class_updated(
	in _id int4,
	in _id_type_css_var int4,
	in _id_css_class int4,
	in id_css_class_list_params int4,
	in _name varchar,
	in _const_name varchar,
	in _description varchar,
	in _active boolean,
	out result_ json
)
	language plpgsql
	as $function$
	begin
		select * into result_ from constructor.params_css_class_check_id(_id => _id);
		if (result_::json->'status_result')::text::int = 404 then
			return;
		end if;

		if _id_type_css_var <> 5 then -- очистка справочника ибо только у type_css_var = 5 (select) может существовать список допустимых значении
			id_css_class_list_params = null;
		end if;

		select * into result_ from constructor.type_css_var_check_id(_id => _id_type_css_var);
		if (result_::json->'status_result')::text::int = 404 then
			return;
		end if;

		select * into result_ from constructor.css_class_check_id(_id => _id_css_class);
		if (result_::json->'status_result')::text::int = 404 then
			return;
		end if;

		select * into result_ from constructor.css_class_list_params_check_id(_id => id_css_class_list_params);
		if (result_::json->'status_result')::text::int = 404 then
			return;
		end if;

		update constructor.params_css_class
		set id_type_css_var = _id_type_css_var, id_css_class = _id_css_class, name = _name, const_name = _const_name, description = _description, active = _active
		where id = _id;
	end;
$function$;

drop function if exists constructor.params_css_class_check_id;
create or replace function constructor.params_css_class_check_id(
	in _id int4,
	out result_ json
)
	language plpgsql
	as $function$
	declare
		check_rows int;
		error_id int = 11;
	begin
		select * into result_ from public.create_error_ids(null, 200);
		select count(*) into check_rows from constructor.params_css_class_get_filter(_id => _id);
		if check_rows = 0 then
			select * into result_ from public.create_error_ids(array[error_id], 404);
		end if;
	end;
$function$;

-- dataset 

insert into constructor.params_css_class(id, id_type_css_var, id_css_class, id_css_class_list_params, name, const_name, description, active)
overriding system value values(1, 3, 1, null, 'Цвет шрифта', '--component-color', 'Параметр определяющий цвет шрифта у компонента', true);

insert into constructor.params_css_class(id, id_type_css_var, id_css_class, id_css_class_list_params, name, const_name, description, active)
overriding system value values(2, 3, 1, null, 'Фон компонента', '--component-bg', 'Параметр определяющий цвет фона у компонента', true);

insert into constructor.params_css_class(id, id_type_css_var, id_css_class, id_css_class_list_params, name, const_name, description, active)
overriding system value values(3, 1, 1, null, 'Размер шрифта', '--component-fz', 'Параметр определяющий размер шрифта у компонента', true);

insert into constructor.params_css_class(id, id_type_css_var, id_css_class, id_css_class_list_params, name, const_name, description, active)
overriding system value values(4, 4, 1, null, 'Внутренние отступы', '--component-padding', 'Параметр определяющий размер внутриних отступов у компонента', true);

insert into constructor.params_css_class(id, id_type_css_var, id_css_class, id_css_class_list_params, name, const_name, description, active)
overriding system value values(5, 4, 1, null, 'Внутрение отступы', '--component-margin', 'Параметр определяющий размер внутрение отступов у компонента', true);

insert into constructor.params_css_class(id, id_type_css_var, id_css_class, id_css_class_list_params, name, const_name, description, active)
overriding system value values(6, 2, 1, null, 'Границы', '--component-border', 'Параметр определяющий границе у компонента', true);

insert into constructor.params_css_class(id, id_type_css_var, id_css_class, id_css_class_list_params, name, const_name, description, active)
overriding system value values(7, 1, 1, null, 'Ширина', '--component-width', 'Параметр определяющий ширина у компонента', true);

insert into constructor.params_css_class(id, id_type_css_var, id_css_class, id_css_class_list_params, name, const_name, description, active)
overriding system value values(8, 1, 1, null, 'Высота', '--component-height', 'Параметр определяющий высота у компонента', true);

insert into constructor.params_css_class(id, id_type_css_var, id_css_class, id_css_class_list_params, name, const_name, description, active)
overriding system value values(9, 5, 2, 1, 'align-item', '--flex-ai', 'Выравнивание дочерних элементов по поперечной оси', true);

insert into constructor.params_css_class(id, id_type_css_var, id_css_class, id_css_class_list_params, name, const_name, description, active)
overriding system value values(10, 5, 2, 2, 'justify-content', '--flex-jc', 'Выравнивание дочерних элементов по главной оси', true);

insert into constructor.params_css_class(id, id_type_css_var, id_css_class, id_css_class_list_params, name, const_name, description, active)
overriding system value values(11, 5, 2, 4, 'flex-direction', '--flex-jc', 'Определяется главная ось', true);

insert into constructor.params_css_class(id, id_type_css_var, id_css_class, id_css_class_list_params, name, const_name, description, active)
overriding system value values(12, 5, 2, 3, 'Перенос компонентов', '--flex-w', 'Перенос компонентов', true);

insert into constructor.params_css_class(id, id_type_css_var, id_css_class, id_css_class_list_params, name, const_name, description, active)
overriding system value values(13, 1, 2, null, 'Оступы колонки', '--flex-col-g', 'Расстояние между компонентами потомками колонки', true);

insert into constructor.params_css_class(id, id_type_css_var, id_css_class, id_css_class_list_params, name, const_name, description, active)
overriding system value values(14, 1, 2, null, 'Оступы строки', '--flex-row-g', 'Расстояние между компонентами потомками строки', true);