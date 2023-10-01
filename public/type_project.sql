-- Очистка

drop table if exists public.type_project cascade;

create table public.type_project (
	id int4 not null generated always as identity, -- Первичный ключ
	"name" varchar not null, -- Название типа проекта
	description varchar null, -- Описание типа проекта
	active bool not null default true, -- Актуальность типа проекта
	const_name varchar not null, -- 'Программное название типа проекта'
	constraint type_project_pk primary key (id)
);

comment on table public.type_project is 'Тип проекта';

create unique index type_project_const_name_idx on public.type_project using btree (const_name);
create unique index type_project_name_idx on public.type_project using btree (name);

--  comments
comment on table public.type_project is 'Тип проектов';

comment on column public.type_project.id is 'Первичный ключ';
comment on column public.type_project."name" is 'Название типа проектов';
comment on column public.type_project.description is 'Описание типа проектов';
comment on column public.type_project.active is 'Актуальность типа проектов';
comment on column public.type_project.const_name is 'Программное название типа проектов';


-- dataset
ALTER SEQUENCE public.type_project_id_seq RESTART WITH 1;

insert into public.type_project (id, "name", description, active, const_name)
overriding system value values(1, 'БД', 'База данных разработки', true, 'database');

insert into public.type_project (id, "name", description, active, const_name) 
overriding system value values(2, 'Графический интерфейс пользователя', 'Графический интерфейс пользователя', true, 'gui');

insert into public.type_project (id, "name", description, active, const_name) 
overriding system value values(3, 'REST API', 'Сервис для обмена данных по HTTP запросам', true, 'restApi');

insert into public.type_project (id, "name", description, active, const_name) 
overriding system value values(4, 'Система', 'Наименование системы хранящей в базе', true, 'system');
