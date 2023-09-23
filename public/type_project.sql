-- Очистка

drop table if exists public.type_project cascade;

create table public.type_project (
	id int4 not null generated always as identity, -- Первичный ключ
	"name" varchar not null, -- Название типа проекта
	description varchar null, -- Описание типа проекта
	active bool not null default true, -- Актуальность типа проекта
	const_name varchar not null -- 'Программное название типа проекта'
);

comment on table public.type_project IS 'Тип проекта';

create unique index type_project_const_name_idx on public.type_project using btree (const_name);
create unique index type_project_name_idx on public.type_project using btree (name);
