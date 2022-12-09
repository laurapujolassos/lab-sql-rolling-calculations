#SQL Rolling calculations
# 1. Get number of monthly active customers.
select * from sakila.rental;
create or replace view sakila.rental_activity as
select rental_id, convert(rental_date, date) as rental_date,
	date_format(convert(rental_date,date), '%m') as Activity_Month, 
	date_format(convert(rental_date,date), '%Y') as Activity_year
from sakila.rental;

select * from sakila.rental_activity;

create or replace view bank.monthly_active_users as
select Activity_year, Activity_Month, count(distinct rental_id) as Active_users
from sakila.rental_activity
group by Activity_year, Activity_Month;

select * from monthly_active_users;

# 2. Active users in the previous month.
select 
   Activity_year, 
   Activity_month,
   Active_users, 
   lag(Active_users) over (order by Activity_year, Activity_Month) as Previous_month  -- partition by Activity_year
from monthly_active_users;

# 3. Percentage change in the number of active customers.
create or replace view bank.diff_monthly_active_users as
with cte_view as 
(
	select 
	Activity_year, 
	Activity_month,
	Active_users, 
	lag(Active_users) over (order by Activity_year, Activity_Month) as Previous_month
	from monthly_active_users
)
select 
   Activity_year, 
   Activity_month, 
   Active_users, 
   Previous_month, 
   (((Active_users - Previous_month)/Previous_month)*100) as Percentage_change
from cte_view;

select * from diff_monthly_active_users;

# 4. Retained customers every month.
create or replace view sakila.distinct_users as
select
	distinct 
	rental_id as Active_id, 
	Activity_year, 
	Activity_month
from sakila.rental_activity
order by Activity_year, Activity_month, rental_id;

select * from sakila.distinct_users;

create or replace view sakila.retained_users as
select d1.Active_id, d1.Activity_year, d1.Activity_month, d2.Activity_month as Previous_month from sakila.distinct_users d1
join sakila.distinct_users d2
on d1.Activity_year = d2.Activity_year 
and d1.Activity_month = d2.Activity_month 
and d1.Active_id = d2.Active_id 
order by d1.Active_id, d1.Activity_year, d1.Activity_month;

select * from sakila.retained_users;

create or replace view sakila.total_recurrent_users as
select Activity_year, Activity_month, count(Active_id) as Retained_users from sakila.retained_users
group by Activity_year, Activity_month;

select * from sakila.total_recurrent_users;