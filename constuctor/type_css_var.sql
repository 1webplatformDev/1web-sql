-- Очистка

drop table if exists constuctor.type_css_var cascade;
 -- ALTER SEQUENCE constuctor.type_css_var_id_seq RESTART WITH 1;

create table constuctor.type_css_var (
	id int4 not null generated always as identity, -- Первичный ключ
	"name" varchar not null, -- Название типа css переменной
	description varchar null, -- Описание типа css переменной
	active bool not null default true, -- Актуальность типа css переменной
	const_name varchar not null -- 'Программное название типа css переменной'
);
comment on table constuctor.type_css_var is 'Тип css переменой';

create unique index type_css_var_idx on constuctor.type_css_var using btree (const_name);
create unique index type_css_var_name_idx on constuctor.type_css_var using btree (name);

-- Column comments

comment on column constuctor.type_component.id is 'Первичный ключ';
comment on column constuctor.type_component."name" is 'Название типа css переменной';
comment on column constuctor.type_component.description is 'Описание типа css переменной';
comment on column constuctor.type_component.active is 'Актуальность типа css переменной';
comment on column constuctor.type_component.active is 'Программное название типа css переменной';

-- type
drop type if exists constuctor.return_type_css_var cascade;
create type constuctor.return_type_css_var as (
	id int, 
	name varchar, 
	description varchar, 
	active bool,
	const_name varchar
);