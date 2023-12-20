-- fun

--select * from constructor.css_class_item_params_insert;
--select * from constructor.css_class_item_params_get_filter;
--select * from constructor.css_class_item_params_updated;
--select * from constructor.css_class_item_params_check_id;
-- select * from constructor.css_class_item_params_get_json();

-- Очистка

drop table if exists constructor.css_class_item_params cascade;
-- alter sequence constructor.css_class_item_params_id_seq restart with 1;

create table constructor.css_class_item_params (
    id int4 generated always as identity, -- Первичный ключ
    id_css_class_list_params int4 not null REFERENCES constructor.css_class_list_params (id), -- Внешний ключ таблицы css_class_list_params
    name varchar not null, -- Имя элемента списка для параметра css класса
    value varchar not null, -- const_name элемента списка для параметра css класса
    description varchar, -- Описание элемента списка для параметра css класса
    active boolean default true, -- Активность элемента списка для параметра css класса
	constraint css_class_item_params_pk primary key (id)
);
--  comments
comment on table constructor.css_class_item_params is 'Элемент список для css параметров класса, применяется у params_css_class с type_css_var = 5(select) и у которого задан ключ внешний таблицы id_css_class_list_params';

comment on column constructor.css_class_item_params.id is 'Первичный ключ';
comment on column constructor.css_class_item_params.id_css_class_list_params is 'Внешний ключ таблицы css_class_list_params';
comment on column constructor.css_class_item_params.name is 'Имя элемента списка для параметра css класса';
comment on column constructor.css_class_item_params.value is 'const_name элемента списка для параметра css класса';
comment on column constructor.css_class_item_params.description is 'Описание элемента списка для параметра css класса';
comment on column constructor.css_class_item_params.active is 'Активность элемента списка для параметра css класса';

-- function

drop function if exists constructor.css_class_item_params_get_filter;
create or replace function constructor.css_class_item_params_get_filter(
	_id int4 = null,
	_id_css_class_list_params int4 = null,
	_name varchar = null,
	_value varchar = null,
	_active boolean = null,
	_no_id int4 = null,
	_limit int = null,
	_offset int = null
)
	returns SETOF constructor.css_class_item_params
	language plpgsql
	as $function$
	begin
		return query 
			select * from constructor.css_class_item_params ccip
			where (ccip.id = _id or _id is null)
			and (ccip.id <> _no_id or _no_id is null)
			and (ccip.id_css_class_list_params = _id_css_class_list_params or _id_css_class_list_params is null)
			and (ccip.name = _name or _name is null)
			and (ccip.value = _value or _value is null)
			and (ccip.active = _active or _active is null)
			limit _limit offset _offset;
	end;
$function$;

drop function if exists constructor.css_class_item_params_insert;
create or replace function constructor.css_class_item_params_insert(
	in _id_css_class_list_params int4,
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
		select * into result_ from constructor.css_class_list_params_check_id(_id => _id_css_class_list_params);
		if (result_::json->'status_result')::text::int = 404 then
			return;
		end if;

		insert into constructor.css_class_item_params (id_css_class_list_params, name, value, description, active)
		values (_id_css_class_list_params, _name, _value, _description, _active)
		returning id into id_;

	end;
$function$;

drop function if exists constructor.css_class_item_params_updated;
create or replace function constructor.css_class_item_params_updated(
	in _id int4,
	in _id_css_class_list_params int4,
	in _name varchar,
	in _value varchar,
	in _description varchar,
	in _active boolean,
	out result_ json
)
	language plpgsql
	as $function$
	begin
		select * into result_ from constructor.css_class_item_params_check_id(_id => _id);
		if (result_::json->'status_result')::text::int = 404 then
			return;
		end if;

		select * into result_ from constructor.css_class_list_params_check_id(_id => _id_css_class_list_params);
		if (result_::json->'status_result')::text::int = 404 then
			return;
		end if;
		update constructor.css_class_item_params
		set id_css_class_list_params = _id_css_class_list_params, name = _name, value = _value, description = _description, active = _active
		where id = _id;
	end;
$function$;

drop function if exists constructor.css_class_item_params_check_id;
create or replace function constructor.css_class_item_params_check_id(
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
		select count(*) into check_rows from constructor.css_class_item_params_get_filter(_id => _id);
		if check_rows = 0 then
			select * into result_ from public.create_error_ids(array[error_id], 404);
		end if;
	end;
$function$;

drop function if exists constructor.css_class_item_params_get_json;
create or replace function constructor.css_class_item_params_get_json(
	in _id int4
)
	returns table(result_json json)
	language plpgsql
	as $function$
	begin
	return query select 
		json_build_object(
			'id', pcc.id, 'name', pcc."name", 'const_name', pcc.const_name, 'id_type_css_var', pcc.id_type_css_var,
			'css_list', case when cclp.id is not null then json_build_object(
			'id', cclp.id, 'name', cclp."name", 'description', cclp."description", 
			'select',  (select  jsonb_agg( jsonb_build_object(
					'id', ccip.id, 'name', ccip.name, 'value', ccip.value, 'description', ccip.description
				)) 
				from constructor.css_class_item_params ccip 
				where ccip.id_css_class_list_params = cclp.id and ccip.active = true
			)
			) else null end
		) as result_json 
		from  constructor.params_css_class pcc 
		left join constructor.css_class_list_params cclp ON pcc.id_css_class_list_params = cclp.id 
		where pcc.id_css_class = _id and pcc.active = true;
	end;
$function$;

-- dataset 

insert into constructor.css_class_item_params(id, id_css_class_list_params, name, value, description, active)
overriding system value values(1, 1, 'Центр', 'center', 'Выравнивание по центру', true);

insert into constructor.css_class_item_params(id, id_css_class_list_params, name, value, description, active)
overriding system value values(2, 1, 'Справо', 'start', 'Выравнивание справо', true);

insert into constructor.css_class_item_params(id, id_css_class_list_params, name, value, description, active)
overriding system value values(3, 1, 'Слево', 'end', 'Выравнивание слево', true);

insert into constructor.css_class_item_params(id, id_css_class_list_params, name, value, description, active)
overriding system value values(4, 2, 'Центр', 'center', 'Выравнивание по центру', true);

insert into constructor.css_class_item_params(id, id_css_class_list_params, name, value, description, active)
overriding system value values(5, 2, 'Справо', 'start', 'Выравнивание справо', true);

insert into constructor.css_class_item_params(id, id_css_class_list_params, name, value, description, active)
overriding system value values(6, 2, 'Слево', 'end', 'Выравнивание слево', true);

insert into constructor.css_class_item_params(id, id_css_class_list_params, name, value, description, active)
overriding system value values(7, 2, 'Одинаковые отступы', 'space-between', 'Выравнивание каждого элемента с одинаковым отступом между друг другом', true);

insert into constructor.css_class_item_params(id, id_css_class_list_params, name, value, description, active)
overriding system value values(8, 3, 'Не переносить', 'nowrap', 'Не переносить', true);

insert into constructor.css_class_item_params(id, id_css_class_list_params, name, value, description, active)
overriding system value values(9, 3, 'Переносить', 'wrap', 'Переносить', true);

insert into constructor.css_class_item_params(id, id_css_class_list_params, name, value, description, active)
overriding system value values(10, 4, 'В строку', 'row', 'Положение flex компонентов потомков в строчку', true);

insert into constructor.css_class_item_params(id, id_css_class_list_params, name, value, description, active)
overriding system value values(11, 4, 'В колонку', 'column', 'Положение flex компонентов потомков в колонку', true);