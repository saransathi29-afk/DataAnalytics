-- 1.What is the total revenue generated from all rentals in the database?
		select sum(amount) as Total_revenue from payment;
        
-- 2.How many rentals were made in each month_name? 
		select monthname(rental_date) as Month_name, count(*) as Month_wise_rental_count 
        from rental 
        group by Month_name 
        order by Month_name desc ;
        
-- 3.What is the rental rate of the film with the longest title in the database? 
		select  rental_rate, title from film  order by length(title)desc limit 1;
        -- or
        select rental_rate,title from film where length(title)= (select max(length(title)) from film);
        
-- 4.What is the average rental rate for films that were taken from the last 30 days from the date("2005-05-05 22:04:30")?         
        select  avg(F.rental_rate) from film F
		inner join inventory I 
		on F.film_id=I.film_id 
		inner join rental R
		on R.inventory_id=I.inventory_id
		where R.rental_date between '2005-05-05' and (date_add('2005-05-05', interval 30 day));
        
-- 5.What is the most popular category of films in terms of the number of rentals?       
		select c.name, fc.category_id,count(r.rental_id) as count_of_rental_id
		from category c
		inner join film_category fc
		on c.category_id=fc.category_id
		inner join film f
		on fc.film_id=f.film_id
		inner join inventory i
		on f.film_id=i.film_id
		inner join rental r
		on i.inventory_id=r.inventory_id
		group by c.name, fc.category_id
		order by count_of_rental_id desc limit 1;
        
-- 6.Find the longest movie duration from the list of films that have not been rented by any customer.      
		select f.film_id, f.title, f.length
        from film f
        left join inventory i
        on i.film_id=f.film_id
        WHERE NOT EXISTS (
        select 1
        from rental r
        where r.inventory_id=i.inventory_id)
        order by f.length desc limit 1;

-- 7.What is the average rental rate for films, broken down by category? 
		select fc.category_id, avg(f.rental_rate) as Avg_rental_rate
		from film f
		inner join film_category fc
		on f.film_id=fc.film_id
		group by fc.category_id;
        
 -- 8.What is the total revenue generated from rentals for each actor in the database? 
		select fa.actor_id, a.first_name as Actor_Name, sum(p.amount) as Total_revenue
        from payment p
        inner join rental r
        on p.rental_id=r.rental_id
        inner join inventory i
        on i.inventory_id=r.inventory_id
        inner join film_actor fa
        on i.film_id=fa.film_id
        inner join actor a
        on fa.actor_id=a.actor_id
        group by fa.actor_id;       
        
-- 9.Show all the actresses who worked in a film having a "Wrestler" in the description. 
		select concat(a.first_name,' ',a.last_name) as Actor_name, f.title, f.description
        from actor a
        inner join film_actor fa
        on a.actor_id=fa.actor_id
        inner join film f
        on fa.film_id=f.film_id
        where f.description like '%wrestler%';
        
-- 10.Which customers have rented the same film more than once? 
		select c.customer_id, concat(c.first_name, ' ', c.last_name) as customer_name,
        f.title as film_title,
        COUNT(r.rental_id) as rental_count
        from customer c
        join rental r on c.customer_id = r.customer_id
        join inventory i on r.inventory_id = i.inventory_id
        join film f on i.film_id = f.film_id
        group by c.customer_id, customer_name, f.film_id, f.title
        having COUNT(r.rental_id) > 1
        order by rental_count DESC, customer_name;
        
-- 11.How many films in the comedy category have a rental rate higher than the average rental rate?
		select count(c.name) as No_of_films
		from category c
		inner join film_category fc
		on c.category_id=fc.category_id
		inner join film f
		on fc.film_id=f.film_id
		where f.rental_rate >(select avg(f.rental_rate) from film f) AND c.name ="comedy";
        
 -- 12.	Which films have been rented the most by customers living in each city? 
		with RentalCount_ByCity as(
		select c.city_id,c.city,f.title,f.film_id,
		count(rental_id) as rental_count,
		row_number() over(partition by c.city_id order by count(rental_id) desc,f.title asc) as rownumber
		from city c
		join address a on c.city_id=a.city_id
		join store s on a.address_id= s.address_id
		join inventory i on s.store_id=i.inventory_id
		join rental r on i.inventory_id=r.inventory_id
		join film f on i.film_id=f.film_id
		group by c.city_id,c.city,f.film_id,f.title
		)
		select city,title,rental_count from RentalCount_ByCity where rownumber=1       
        
-- 13.What is the total amount spent by customers whose rental payments exceed $200? 
	   select customer_id, sum(amount) as Total_amount from payment group by customer_id having Total_amount>200;
       
-- 14.Display the fields which are having foreign key constraints related to the "rental" table. [Hint: using Information_schema] 
	   select constraint_name from information_schema.key_column_usage
	   where
       referenced_table_schema='film_rental' and
       REFERENCED_TABLE_NAME ='rental';
  
 -- 15.Create a View for the total revenue generated by each staff member, broken down by store city with the country name.  
		CREATE VIEW Total_revenue_by_city AS
		select  s.staff_id,s.first_name as Name,sum(p.amount) as Total_revenue,c.city,ct.country from payment p
		join staff s
		on p.staff_id=s.staff_id
		join address a
		on s.address_id= a.address_id
		join city c
		on a.city_id=c.city_id
		join country ct
		on c.country_id=ct.country_id
		group by s.staff_id,c.city,ct.country;

		select * from Total_revenue_by_city;
        
-- 16.Create a view based on rental information consisting of visiting_day, customer_name, the title of the film,    
		create view Rental_Information as
		select r.rental_date as Visting_day,c.first_name as Name, f.title, 
		abs(datediff(r.rental_date,r.return_date)) as No_of_rental_days, p.amount as amount_paid,
		round((p.amount*100.0 / sum(p.amount) over(PARTITION BY c.customer_id)),2)as percentage
		from rental r 
		inner  join payment p on r.rental_id=p.rental_id
		inner join customer c on r.customer_id=c.customer_id 
		inner join inventory i on r.inventory_id= i.inventory_id
		inner join film f on i.film_id=f.film_id;
  
        select * from Rental_Information;
   -- 17.	Display the customers who paid 50% of their total rental costs within one day.      
        select distinct c.customer_id, c.first_name, sum(p.amount) as total_amount, date(r.rental_date),date(p.payment_date),
        sum(p.amount)/2 as half_of_total_amount
        from payment p
		inner join customer c
		on p.customer_id=c.customer_id
		inner join rental r
		on r.rental_id=p.rental_id
		-- where r.rental_date= p.payment_date
		WHERE date(p.payment_date) <= DATE_ADD(date(r.rental_date), INTERVAL 1 DAY)
		group by c.customer_id,r.rental_date,p.payment_date
		having r.rental_date= p.payment_date;
