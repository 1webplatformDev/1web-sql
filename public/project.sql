-- Очистка

drop table if exists public.project cascade;

create table public.project (
	id int4 not null generated always as identity, -- Первичный ключ
	"name" varchar not null, -- Название проекта
	description varchar null, -- Описание проекта
	active bool not null default true, -- Актуальность проекта
	const_name varchar not null, -- 'Программное название проекта'
	CONSTRAINT project_pk PRIMARY KEY (id)
);

comment on table public.project IS 'Тип проекта';

create unique index project_const_name_idx on public.project using btree (const_name);
create unique index project_name_idx on public.project using btree (name);

--  comments
comment on table public.project IS 'Проекты';

comment on column public.project.id is 'Первичный ключ';
comment on column public.project."name" is 'Название проека';
comment on column public.project.description is 'Описание проека';
comment on column public.project.active is 'Актуальность проека';
comment on column public.project.const_name is 'Программное название проека';
