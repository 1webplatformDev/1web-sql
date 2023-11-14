create schema public authorization postgres;

drop function public.intersectAndExcept;
-- Функция принимает 2 массива что передал пользователь и что вернула функция
-- в element_intersect хранятся валидные переданные пользователем значения
-- в element_except хранятся значения которых нет в базе данных и они считаются не валидными
create or replace function public.intersectAndExcept(array_ int4[], array_ids int4[])
	returns table (element_intersect int4[], element_except int4[])
	LANGUAGE plpgsql
AS $function$
	begin
		return query 
		select 
			array(select unnest(array_) intersect select unnest(array_ids)) as id_save, 
			array(select unnest(array_) except select unnest(array_ids)) as id_error;
	end;
$function$;
