CREATE TABLE bookings.results (
	id int NULL,
	response text NULL
);

--1.      Вывести максимальное количество человек в одном бронировании

INSERT INTO bookings.results 
select 1, max (c_pass) from (select count(passenger_id) as c_pass
from tickets
group by book_ref) as t1;

--2.      Вывести количество бронирований с количеством людей больше 
--среднего значения людей на одно бронирование

with c_pas as (select t.book_ref br, count(t.passenger_id) pas from tickets t
	group by t.book_ref)
INSERT INTO bookings.results 
select 2, count(br) from c_pas
		where c_pas.pas > (select avg(c_pas.pas) from c_pas);

--3.      Вывести количество бронирований, у которых состав пассажиров повторялся
-- два и более раза, среди бронирований с максимальным количеством людей (п.1)?
	
with table1 as (select book_ref, count(*) c
    from tickets
    group by book_ref),
     table2 as (select book_ref, passenger_id from tickets
         where book_ref in (select book_ref from table1
                            where c = (select max(c) from table1)))
INSERT INTO bookings.results 
select 3, count(distinct book_ref)
from (select t1.book_ref,
             row_number() over(partition by t1.book_ref, t2.book_ref
                 order by t1.book_ref, t2.book_ref) pass_num
      from table2 t1
               join table2 t2 on t1.passenger_id = t2.passenger_id and t1.book_ref <> t2.book_ref) t
where t.pass_num = (select max(c) from table1);

--4.      Вывести номера брони и контактную информацию по пассажирам в брони 
--(passenger_id, passenger_name, contact_data) с количеством людей в брони = 3

INSERT INTO bookings.results 
select 4, t4_1.book_ref|| '|' ||t4_1.passenger_id|| '|' ||t4_1.passenger_name|| '|' ||t4_1.contact_data 
	from tickets t4_1 join (
		select count(pas4.passenger_id), pas4.book_ref from tickets pas4
			group by  pas4.book_ref
			having count(pas4.passenger_id) = 3) t4_2 on t4_1.book_ref = t4_2.book_ref
			order by t4_1.book_ref, t4_1.passenger_id, t4_1.passenger_name, t4_1.contact_data;

--5.      Вывести максимальное количество перелётов на бронь

INSERT INTO bookings.results 
select 5, max(cf) from (
	select count(tf.flight_id) cf, b.book_ref 
		from ticket_flights tf 
		left join tickets t on t.ticket_no = tf.ticket_no
		left join bookings b on t.book_ref = b.book_ref 
		group by b.book_ref) ctf;

--6.      Вывести максимальное количество перелётов на пассажира в одной брони

INSERT INTO bookings.results 
select 6, max(cf) from (
	select count(tf.flight_id) cf, t.passenger_id, b.book_ref 
		from ticket_flights tf 
		left join tickets t on t.ticket_no = tf.ticket_no
		left join bookings b on t.book_ref = b.book_ref 
		group by b.book_ref, t.passenger_id ) ctf;

--7.      Вывести максимальное количество перелётов на пассажира

INSERT INTO bookings.results 
select 7, max(cf) from (
	select count(tf.flight_id) cf, t.passenger_id
		from ticket_flights tf 
		left join tickets t on t.ticket_no = tf.ticket_no
		group by t.passenger_id ) ctf;

--8.      Вывести контактную информацию по пассажиру(ам) (passenger_id, passenger_name, contact_data) и
-- общие траты на билеты, для пассажира потратившему минимальное количество денег на перелеты

with sum_am as(select t.passenger_id, t.passenger_name, t.contact_data, sum(tf.amount) s_am
	from tickets t
		left join ticket_flights tf using (ticket_no)
		left join flights f using (flight_id)
		where f.status <> 'Cancelled'
		group by t.passenger_id,t.passenger_name, t.contact_data
		order by t.passenger_id, t.passenger_name, t.contact_data)
INSERT INTO bookings.results 
select 8, concat(passenger_id,'|', passenger_name, '|', contact_data, '|', s_am) from sum_am
	where s_am in (select min(s_am) from sum_am);
	
--9.      Вывести контактную информацию по пассажиру(ам) (passenger_id, passenger_name, contact_data) и
-- общее время в полётах, для пассажира, который провёл максимальное время в полётах

with sum_time as(select t.passenger_id, t.passenger_name, t.contact_data, sum(f.actual_arrival - f.actual_departure) as time_fly
	from tickets t
		left join ticket_flights tf using (ticket_no)
		left join flights f using (flight_id)
		where f.status = 'Arrived'
		group by t.passenger_id, t.passenger_name, t.contact_data
		order by t.passenger_id, t.passenger_name, t.contact_data)
INSERT INTO bookings.results 
select 9, concat(passenger_id,'|', passenger_name, '|', contact_data, '|', time_fly) from sum_time
	where time_fly in (select max(time_fly) from sum_time);
	
--10.   Вывести город(а) с количеством аэропортов больше одного

INSERT INTO bookings.results 
select 10, city
	from airports
	group by city
	having count(city) > 1
	order by city;
	
--11.   Вывести город(а), у которого самое меньшее количество городов прямого сообщения

with city_c as (
	select departure_city, count(distinct arrival_city) as c_c
	from routes r
	group by departure_city)
insert into results
select 11, departure_city
	from city_c
	where c_c = (select min(c_c)
				from city_c)
order by departure_city;

--12.   Вывести пары городов, у которых нет прямых сообщений исключив реверсные дубликаты

with table0 as(select distinct departure_city, arrival_city from routes)
insert into results
select 12, concat(d_c, '|', a_c)
from(select t1.departure_city d_c, t2.arrival_city a_c from table0 t1, table0 t2
	where t1.departure_city < t2.arrival_city
except
select * from table0) t
order by d_c, a_c;

--13.   Вывести города, до которых нельзя добраться без пересадок из Москвы?

with table0 as (select departure_city, arrival_city from flights_v 
	where departure_city = 'Москва'
	group by departure_city, arrival_city)
INSERT INTO bookings.results 
select 13, fv.arrival_city from flights_v fv
	where fv.arrival_city <> 'Москва'
except
select 13, arrival_city from table0
	order by arrival_city;

--14.   Вывести модель самолета, который выполнил больше всего рейсов

with table1 as(
select ad.model, count(f.flight_no) c_f  from flights f 
join aircrafts_data ad using(aircraft_code)
where f.status in ('Departed', 'Arrived')
group by ad.model)
INSERT INTO bookings.results 
select 14, model from table1
	where table1.c_f = (select max(table1.c_f) from table1);

--15.   Вывести модель самолета, который перевез больше всего пассажиров

with table1 as(
select ad.model, count(tickets.passenger_id) c_p  from flights f 
join aircrafts_data ad using(aircraft_code)
join ticket_flights using(flight_id)
join tickets using(ticket_no)
where f.status in ('Departed', 'Arrived')
group by ad.model)
INSERT INTO bookings.results 
select 15, model from table1
	where table1.c_p = (select max(table1.c_p) from table1);

--16.   Вывести отклонение в минутах суммы запланированного времени перелета от фактического по всем перелётам

with table0 as(select (f.scheduled_arrival - f.scheduled_departure) t_s,(f.actual_arrival - f.actual_departure) t_a from flights f
where status in ( 'Arrived'))
INSERT INTO bookings.results 
select 16, (DATE_PART('day', d_t) * 24 + DATE_PART('hour', d_t)) * 60 + DATE_PART('minute',d_t)
from (select (sum(t_a) - sum(t_s)) as d_t from table0) table1;

--17.   Вывести города, в которые осуществлялся перелёт из Санкт-Петербурга 2016-09-13

INSERT INTO bookings.results 
select distinct 17, arrival_city
from flights_v fv 
where departure_city = 'Санкт-Петербург' and actual_departure::date = '2016-09-13'
order by arrival_city;

--18.   Вывести перелёт(ы) с максимальной стоимостью всех билетов

with table0 as (select flight_id, sum(amount) s_a
      from ticket_flights
      group by flight_id)
INSERT INTO bookings.results
select 18, flight_id from table0
where s_a = (select max(s_a) from table0);

--19.   Выбрать дни в которых было осуществлено минимальное количество перелётов

with table0 as(select count(flight_id) c_f, actual_departure::date ad  from flights f
	where status in ('Cancelled', 'Arrived') 
	and actual_departure::date  is not null
	group by ad
	order by c_f asc)
INSERT INTO bookings.results 
select 19, ad from table0
	where c_f = (select min(c_f) from table0);

--20.   Вывести среднее количество вылетов в день из Москвы за 09 месяц 2016 года

INSERT INTO bookings.results 
select 20, avg(c_f) from (
select count(flight_id) c_f from flights_v fv 
	where fv.departure_city = 'Москва' and 
	actual_departure_local is not null and
	date_trunc('month', actual_departure_local) = '2016-09-01') avg_flight;

--21.   Вывести топ 5 городов у которых среднее время перелета до пункта назначения больше 3 часов

INSERT INTO bookings.results 
select 21, t0.departure_city from (
	select fv.departure_city, avg(DATE_PART('day', fv.scheduled_duration) * 24 + DATE_PART('hour', fv.scheduled_duration) * 60 + DATE_PART('minute',fv.scheduled_duration)) as avg_tf from flights_v fv 
	group by fv.departure_city
	order by avg_tf desc) t0
where avg_tf >180
limit 5;
