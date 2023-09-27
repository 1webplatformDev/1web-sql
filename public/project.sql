-- Очистка

drop table if exists public.project cascade;

create table public.project (
	id int4 not null generated always as identity, -- Первичный ключ
	"name" varchar not null, -- Название проекта
	description varchar null, -- Описание проекта
	active bool not null default true, -- Актуальность проекта
	const_name varchar not null, -- 'Программное название проекта'
	id_type_project int4 NOT NULL, -- Внешний ключ таблицы type_project
	constraint project_pk primary key (id),
	constraint project_fk foreign key (id_type_project) references public.type_project(id)
);

comment on table public.project is 'Тип проекта';

create unique index project_const_name_idx on public.project using btree (const_name);
create unique index project_name_idx on public.project using btree (name);

--  comments
comment on table public.project is 'Проекты';

comment on column public.project.id is 'Первичный ключ';
comment on column public.project."name" is 'Название проека';
comment on column public.project.description is 'Описание проека';
comment on column public.project.active is 'Актуальность проека';
comment on column public.project.const_name is 'Программное название проека';
comment on column public.project.id_type_project is 'Внешний ключ таблицы type_project';

-- dataset
ALTER SEQUENCE public.type_project_id_seq RESTART WITH 1;
insert into public.project ("name", description, active, const_name, id_type_project) VALUES('Основная бд', 'Основная база данных разработки sql на postgresql', true, '1-web-sql', 1);
