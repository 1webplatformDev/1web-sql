-- fun

-- select * from constructor.type_component_check_unique;
-- select * from constructor.type_component_insert;
-- select * from constructor.type_component_get_unique;
-- select * from constructor.type_component_updated;
-- select * from constructor.type_component_get_filter;
-- select * from constructor.type_component_check_id
-- select * from constructor.type_component_check_array_id

-- Очистка
drop table if exists constructor.type_component cascade;
-- ALTER SEQUENCE constructor.type_component_id_seq RESTART WITH 1;

create table constructor.type_component (
	id int4 not null generated always as identity, -- Первичный ключ
	"name" varchar not null, -- Название типа компонента
	description varchar null, -- Описание типа компонента
	active bool not null default true, -- Актуальность типа компонента
	const_name varchar not null, -- 'Программное название типа компонента'

	constraint type_component_pk primary key (id)
);

create unique index type_component_const_name_idx on constructor.type_component using btree (const_name);
create unique index type_component_name_idx on constructor.type_component using btree (name);

--  comments
comment on table constructor.type_component is 'Тип компонента';

comment on column constructor.type_component.id is 'Первичный ключ';
comment on column constructor.type_component."name" is 'Название типа компонента';
comment on column constructor.type_component.description is 'Описание типа компонента';
comment on column constructor.type_component.active is 'Актуальность типа компонента';
comment on column constructor.type_component.const_name is 'Программное название типа компонента';

-- type

drop type if exists constructor.return_type_component cascade;
create type constructor.return_type_component as (
	id int, 
	name varchar, 
	description varchar, 
	active bool,
	const_name varchar
);

-- function

drop function if exists constructor.type_component_check_unique;
create or replace function constructor.type_component_check_unique(
	in _name varchar,
	in _const_name varchar,
	in _id int = null,
	out errors_ json
)
	language  plpgsql
	as $function$
	declare
		count_name int;
		count_const_name int;
		error_id_const_name int = 1;
		error_id_name int = 2;
		error_array int[];
    begin 
	    select count(*) into count_name from constructor.type_component_get_filter(null, null, _name, null, _id);
	   	select count(*) into count_const_name from constructor.type_component_get_filter(null, null, null, _const_name, _id);

	   	if count_name <> 0 then
			error_array = array_append(error_array, error_id_const_name);
	   	end if;	
	   		
	   	if count_const_name <> 0 then	
			error_array = array_append(error_array, error_id_name);
	   	end if;

		if array_length(error_array, 1) <> 0 then
			select * into errors_ from public.create_error_ids(error_array, 400);
			return;
		end if;

	   select * into errors_ from public.create_error_json(null, 200);
    end;
$function$;

drop function if exists constructor.type_component_insert();
create or replace function constructor.type_component_insert(
	in _name varchar,
	in _const_name varchar,
	in _description varchar,
	out id_ int,
	out result_ json
)
	language  plpgsql
	as $function$
    begin 
		select * into result_ from constructor.type_component_check_unique(_name, _const_name);
		if (result_::json->'status_result')::text::int = 200 then
			insert into constructor.type_component
        	(name, const_name, description) values (_name, _const_name, _description)
        	returning id into id_;
	   end if;
    end;
$function$;

drop function if exists constructor.type_component_updated;
create or replace function constructor.type_component_updated(
	in _id int,
	in _name varchar,
	in _const_name varchar,
	in _description varchar,
	out result_ json
)
	language  plpgsql
	as $function$
	declare 
		check_rows int;
		error_id int = 3;
    begin
		select count(*) into check_rows from constructor.type_component_get_filter(_id);
		if check_rows = 0 then
			select * into result_ from public.create_error_ids(array[error_id], 404);
			return;
		end if;
	   	select * into result_ from constructor.type_component_check_unique(_name, _const_name, _id);
	   	if (result_::json->'status_result')::text::int = 200 then
	   	 	UPDATE constructor.type_component
			SET name = _name, const_name = _const_name, description = _description
			where id = _id;
	   	end if;
    end;
$function$;

drop function if exists constructor.type_component_get_filter;
create or replace function constructor.type_component_get_filter(
	_id int = null,
	_active bool = null,
	_name varchar = null,
	_const_name varchar = null,
	_no_id int = null
)
	returns SETOF constructor.return_type_component
	language  plpgsql
	as $function$
    begin 
        return query 
        	select tc.id, tc."name", tc.description, tc.active, tc.const_name  
       		from constructor.type_component tc 
       		where (tc.id = _id or _id is null) 
			and (tc.id <> _no_id or _no_id is null) 
       		and (tc.const_name = _const_name or _const_name is null)
       		and (tc.name = _name or _name is null)
       		and (tc.active  = _active or _active is null);
    end;
$function$;

drop function if exists constructor.type_component_get_unique;
create or replace function constructor.type_component_get_unique(
	_column_name varchar,
	_id int = null,
	_active bool = null,
	_name varchar = null,
	_const_name varchar = null
)
	returns table(id int, name varchar) 
	language  plpgsql
	as $function$
    begin 
	    if _column_name in ('name', 'const_name') then
	    	return query EXECUTE 
	    		format(
	    			'select id, %s from (select * from constructor.type_component_get_filter(%2$L, %3$L, %4$L, %5$L)) as tc', 
					_column_name, _id, _active, _name, _const_name
				);
	    end if;
    end;
$function$;

drop function if exists constructor.type_component_check_id;
create or replace function constructor.type_component_check_id(
	in _id int4,
	out result_ json
)
	language plpgsql
	as $function$
	declare
		check_rows int;
		error_id int = 3;
	begin
		select * into result_ from public.create_error_ids(null, 200);
		select count(*) into check_rows from constructor.type_component_get_filter(_id => _id);
		if check_rows = 0 then
			select * into result_ from public.create_error_ids(array[error_id], 404);
		end if;
	end;
$function$;


drop function if exists constructor.type_component_check_array_id;
create or replace function constructor.type_component_check_array_id(
	ids_ integer[],
	out _result_ids integer[],
	out _result json
)
	returns record
	language plpgsql
	as $function$
	declare 
		error_text varchar = 'id не будут сохранены они не существуют: {1}';
		error_ids int[];
		warning_json json[];
	begin 
		select array_agg(tc.id) into _result_ids from constructor.type_component tc where tc.id = any(ids_);
		select array(select unnest(ids_) except select unnest(_result_ids)) into error_ids;
		if array_length(error_ids, 1) <> 0 then
			select array(select json_build_object('name', replace(error_text, '{1}', array_to_string(error_ids, ',')))) into warning_json;
			select * into _result from public.create_result_json(_warning => warning_json);
			return;
		end if;
		select * into _result from public.create_result_json();
	end;
$function$;

-- dataset 
insert into constructor.type_component(id, name, description, active, const_name)
overriding system value values(1, 'Блочный элемент', 'Блочный элемент', true, 'div');

insert into constructor.type_component(id, name, description, active, const_name)
overriding system value values(2, 'Текстовый элемент', 'Текстовый элемент', true, 'span');

insert into constructor.type_component(id, name, description, active, const_name)
overriding system value values(3, 'Поле ввода', 'Поле ввода', true, 'input');

insert into constructor.type_component(id, name, description, active, const_name)
overriding system value values(4, 'Выпадающий список', 'Выпадающий список', true, 'select');

insert into constructor.type_component(id, name, description, active, const_name)
overriding system value values(5, 'Пункты списка', 'Пункты списка', true, 'option');

insert into constructor.type_component(id, name, description, active, const_name)
overriding system value values(6, 'Таблица', 'Таблица', true, 'table');

insert into constructor.type_component(id, name, description, active, const_name)
overriding system value values(7, 'Изображение', 'Изображение', true, 'img');

insert into constructor.type_component(id, name, description, active, const_name)
overriding system value values(8, 'Чекбокс ', 'Флажок, флаговая кнопка, чекбокс', true, 'checkbox');

insert into constructor.type_component(id, name, description, active, const_name)
overriding system value values(9, 'Кнопка', 'Кнопка', true, 'button');

insert into constructor.type_component(id, name, description, active, const_name)
overriding system value values(10, 'Многострочное поле ввода', 'Многострочное поле ввода', true, 'textarea');

insert into constructor.type_component(id, name, description, active, const_name)
overriding system value values(11, 'Метка', 'Подпись к элементу пользовательского интерфейса', true, 'label');

insert into constructor.type_component(id, name, description, active, const_name)
overriding system value values(12, 'Поле ввода файла', 'Поле ввода файла', true, 'file');

insert into constructor.type_component(id, name, description, active, const_name)
overriding system value values(13, 'Поле ввода цвета', 'Поле ввода цвета', true, 'color');

insert into constructor.type_component(id, name, description, active, const_name)
overriding system value values(14, 'Группа радиокнопок', 'Группа радиокнопок', true, 'radio');

insert into constructor.type_component(id, name, description, active, const_name)
overriding system value values(15, 'Переключатель', 'Переключатель', true, 'toggle');

insert into constructor.type_component(id, name, description, active, const_name)
overriding system value values(16, 'Форма', 'Форма ', true, 'form');

insert into constructor.type_component(id, name, description, active, const_name)
overriding system value values(17, 'Аккордеон', 'Контейнер со сворачиваемыми вкладками', true, 'accordion');

insert into constructor.type_component(id, name, description, active, const_name)
overriding system value values(18, 'Сообщение', 'Сообщение', true, 'alert');

insert into constructor.type_component(id, name, description, active, const_name)
overriding system value values(19, 'Всплывающиее окно', 'Всплывающиее окно', true, 'popover');

insert into constructor.type_component(id, name, description, active, const_name)
overriding system value values(20, 'Модальная форма', 'Модальная форма', true, 'modal');

insert into constructor.type_component(id, name, description, active, const_name)
overriding system value values(21, 'Ссылка', 'Ссылка на другую страницу', true, 'link');

insert into constructor.type_component(id, name, description, active, const_name)
overriding system value values(22, 'Заголовки', 'Заголовки', true, 'h');

insert into constructor.type_component(id, name, description, active, const_name)
overriding system value values(23, 'Вопрос', 'Окно задающий вопрос пользователю', true, 'message');

insert into constructor.type_component(id, name, description, active, const_name)
overriding system value values(24, 'Прелоадер', 'Элемент показывающий загрузку происходящего', true, 'preloader');

insert into constructor.type_component(id, name, description, active, const_name)
overriding system value values(25, 'Вкладки', 'Вкладки, показывают контент закрепленный за ними', true, 'tab');

insert into constructor.type_component(id, name, description, active, const_name)
overriding system value values(26, 'График', 'График', true, 'chart');

insert into constructor.type_component(id, name, description, active, const_name)
overriding system value values(27, 'Перенос', 'Перенос строки', true, 'br');