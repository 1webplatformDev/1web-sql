-- Очистка

drop table if exists public.project cascade;

create table public.project (
	id int4 not null generated always as identity, -- Первичный ключ
	"name" varchar not null, -- Название проекта
	description varchar null, -- Описание проекта
	active bool not null default true, -- Актуальность проекта
	const_name varchar not null -- 'Программное название проекта'
);

comment on table public.project IS 'Тип проекта';

create unique index project_const_name_idx on public.project using btree (const_name);
create unique index project_name_idx on public.project using btree (name);
