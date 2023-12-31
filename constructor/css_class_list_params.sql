-- fun

--select * from constructor.css_class_list_params_insert;
--select * from constructor.css_class_list_params_get_filter;
--select * from constructor.css_class_list_params_updated;
--select * from constructor.css_class_list_params_check_id;

-- Очистка

drop table if exists constructor.css_class_list_params cascade;
-- alter sequence constructor.css_class_list_params_id_seq restart with 1;

create table constructor.css_class_list_params (
    id int4 generated always as identity, -- Первичный ключ
    name varchar not null, -- Имя списка для параметра css класса
    description varchar, -- Описание списка для параметра css класса
    active boolean default true, -- Активность списка для параметра css класса
	constraint css_class_list_params_pk primary key (id)
);
--  comments
comment on table constructor.css_class_list_params is 'Список для css params, применяется у params_css_class с type_css_var = 5(select)';

comment on column constructor.css_class_list_params.id is 'Первичный ключ';
comment on column constructor.css_class_list_params.name is 'Имя списка для параметра css класса';
comment on column constructor.css_class_list_params.description is 'Описание списка для параметра css класса';
comment on column constructor.css_class_list_params.active is 'Активность списка для параметра css класса';

-- function

drop function if exists constructor.css_class_list_params_get_filter;
create or replace function constructor.css_class_list_params_get_filter(
	_id int4 = null,
	_name varchar = null,
	_active boolean = null,
	_no_id int4 = null,
	_limit int = null,
	_offset int = null
)
	returns SETOF constructor.css_class_list_params
	language plpgsql
	as $function$
	begin
		return query 
			select * from constructor.css_class_list_params cclp
			where (cclp.id = _id or _id is null)
			and (cclp.id <> _no_id or _no_id is null)
			and (cclp.name = _name or _name is null)
			and (cclp.active = _active or _active is null)
			limit _limit offset _offset;
	end;
$function$;

drop function if exists constructor.css_class_list_params_insert;
create or replace function constructor.css_class_list_params_insert(
	in _name varchar,
	in _description varchar = null,
	in _active boolean = true,
    out id_ int,
    out result_ json
)
	language plpgsql
	as $function$
	begin
		insert into constructor.css_class_list_params (name, description, active)
		values (_name, _description, _active)
		returning id into id_;
	end;
$function$;

drop function if exists constructor.css_class_list_params_updated;
create or replace function constructor.css_class_list_params_updated(
	in _id int4,
	in _name varchar,
	in _description varchar,
	in _active boolean,
	out result_ json
)
	language plpgsql
	as $function$
	begin
		select * into result_ from constructor.css_class_list_params_check_id(_id => _id);
		if (result_::json->'status_result')::text::int = 404 then
			return;
		end if;
		
		update constructor.css_class_list_params
		set name = _name, description = _description, active = _active
		where id = _id;
	end;
$function$;

drop function if exists constructor.css_class_list_params_check_id;
create or replace function constructor.css_class_list_params_check_id(
	in _id int4,
	out result_ json
)
	language plpgsql
	as $function$
	declare
		check_rows int;
		error_id int = 12;
	begin
		select * into result_ from public.create_error_ids(null, 200);
		select count(*) into check_rows from constructor.css_class_list_params_get_filter(_id => _id);
		if check_rows = 0 then
			select * into result_ from public.create_error_ids(array[error_id], 404);
		end if;
	end;
$function$;

-- dataset 

insert into constructor.css_class_list_params(id, name, description, active)
overriding system value values(1, 'align_item', 'Список допустимых значении для выравнивание flex компонентов потомков по поперечной оси', true);

insert into constructor.css_class_list_params(id, name, description, active)
overriding system value values(2, 'justify-content', 'Список допустимых значении для выравнивание flex компонентов потомков по главной оси', true);

insert into constructor.css_class_list_params(id, name, description, active)
overriding system value values(4, 'flex-direction', 'Список допустимых значении для  изменения положения flex потомков компонентов', true);

insert into constructor.css_class_list_params(id, name, description, active)
overriding system value values(3, 'flex-wrap', 'Список допустимых значении для переноса flex компонентов потомков на новую строчку', true);