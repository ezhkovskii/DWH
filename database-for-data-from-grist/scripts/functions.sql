
-- Функции
drop function if exists start_dags(text,
text,
text[]) ;

CREATE OR REPLACE FUNCTION start_dags(dags text[])
  RETURNS boolean
  LANGUAGE plpgsql
AS $$
DECLARE
  current_dag text;
  login text := 'login';
   pass text := 'password';
 result http_response array;
BEGIN
  FOREACH current_dag IN ARRAY dags LOOP
    result := array_append(result, start_dag_run(login, pass, current_dag));
  END LOOP;
return true;
END;
$$;

drop function if exists start_dag_run(text,
text,
text);

create or replace
function start_dag_run(login text,
pass text,
dag_id text)
returns http_response  
language plpgsql as 
$$ declare   
result http_response;
url text;
headers http_header array;
logpass text;
begin  
url := concat('http://airflow-airflow-webserver-1:8080/api/v1/dags/', dag_id, '/dagRuns');
logpass := concat(login, ':', pass);
headers := array[http_header('Authorization', concat('Basic ', encode(logpass::bytea, 'base64')))];
select
	*
	into result
from
	http(('POST',
	url,
	headers,
	'application/json',
	'{}')::http_request);
return result;
end;
$$;


-- Пример вызова кода сверху. Код ниже нужно вставить в Custom Action в metabase.
-- т.к. action в metabase принимают только update, delete и insert был написан костыль ниже, который вызывает апи
-- airflow.
--
-- with cte as (
-- 	select
-- 	start_dags('логин',
-- 	'пароль',
-- 	array['DAG1', 'DAG2'])
-- )
-- UPDATE test
-- SET "Name" = 'Test'
-- WHERE false = (select true from cte);


-- Функции вывода информации о дагах


drop function if exists get_info_dags(text,
text,
text);

create or replace
function get_info_dags(login text,
pass text,
dags text[])
returns setof RECORD
language plpgsql as
$$ declare
url text;

headers http_header array;

logpass text;

info_dag text;

result record;

current_dag text;

begin

logpass := concat(login, ':', pass);

headers := array[http_header('Authorization',
concat('Basic ', encode(logpass::bytea, 'base64')))];

foreach current_dag in array dags loop
    url := concat('http://airflow-airflow-webserver-1:8080/api/v1/dags/', current_dag, '/dagRuns?limit=1&order_by=-execution_date');

select
		current_dag,
	(((content::json ->> 'dag_runs')::json ->> 0)::json ->> 'end_date')::timestamp at time zone 'utc' at time zone 'europe/moscow'
		into
	result
from
		http(('GET',
		url,
		headers,
		null,
		null)::http_request);

return next result;
end loop;
end;

$$;

-- Пример вызова функции get_info_dags
--
-- select * from get_info_dags('login',
--  	'password',
--  	array['DAG1', 'DAG2'])  as (DAG_ID text, Time timestamp)