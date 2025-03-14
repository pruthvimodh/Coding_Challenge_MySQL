-- Question 1: Total Sales Revenue by Product

select prod.id as product_id, prod.name as product_name, sum(ordi.quantity * ordi.price) as total_revenue
from order_items as ordi
inner join products as prod on ordi.product_id = prod.id
group by prod.id, prod.name
order by total_revenue desc;

-- Question 2: Top Customers by Spending

select c.id as customer_id, c.name as customer_name, sum(ordi.quantity * ordi.price) as total_spent
from customers as c
inner join orders as ord on c.id = ord.customer_id
inner join order_items as ordi on ord.id = ordi.order_id
group by c.id, c.name
order by total_spent desc
limit 5;


-- Question 3: Average Order Value per Customer

select c.id as customer_id, c.name as customer_name, sum(ordi.quantity * ordi.price) / count(DISTINCT ord.id) as avg_order_value
from customers as c
inner join orders as ord on c.id = ord.customer_id
inner join order_items as ordi on ord.id = ordi.order_id
group by c.id, c.name
order by avg_order_value desc;


-- Question 4: Recent Orders

select ord.id as order_id, c.name as customer_name, ord.order_date, ord.status
from orders as ord
inner join customers as c on ord.customer_id = c.id
where ord.order_date >= NOW() - INTERVAL 30 DAY;


-- Question 5: Running Total of Customer Spending

select ord.customer_id, ord.id as order_id, ord.order_date, sum(ordi.quantity * ordi.price) as order_total,sum(sum(ordi.quantity * ordi.price)) OVER (PARTITION BY ord.customer_id order by ord.order_date) as running_total
from orders as ord
inner join order_items as ordi on ord.id = ordi.order_id
group by ord.customer_id, ord.id, ord.order_date
order by ord.customer_id, ord.order_date;


-- Question 6: Product Review Summary
select p.id as product_id, p.name as product_name, COALESCE(AVG(r.rating), 0) as avg_rating, count(r.id) as total_reviews
from products as p
left join reviews as r on p.id = r.product_id
group by p.id, p.name
order by avg_rating desc, total_reviews desc;


-- Question 7: Customers Without Orders
select c.id as customer_id, c.name as customer_name
from customers as c
left join orders as ord on c.id = ord.customer_id
where ord.id is null;


-- Question 8: Update Last Purchased Date
update products as p
SET last_purchased = (select MAX(ord.order_date) from orders as ord inner join order_items as ordi on ord.id = ordi.order_id where ordi.product_id = p.id)
where EXISTS (select 1 from order_items as ordi where ordi.product_id = p.id);


-- Question 9: Transaction Scenario
START TRANSACTION;

    -- Deducts the ordered quantity from a product’s stock.
    UPDATE products 
    SET stock = stock - 3 
    where id = 1;

    -- Inserts a new record in the orders table.
    INSERT INTO orders (customer_id, order_date, status) 
    VALUES (5, NOW(), 'Completed');

    -- Inserts one or more records in the order_items table for that order.
    SET @order_id = LAST_INSERT_ID();
    INSERT INTO order_items (order_id, product_id, quantity, price) 
    VALUES (@order_id, 1, 3, (select price from products where id = 1));

    -- Updates the product’s last_purchased timestamp with the order date.
    UPDATE products 
    SET last_purchased = NOW() 
    where id = 1;

COMMIT;

-- Question 10: Query Optimization and Indexing (Short Answer)
    -- EXPLAIN statement
    EXPLAIN select c.id as customer_id, c.name, sum(ordi.quantity * ordi.price) as total_spent
    from customers as c
    inner join orders as ord on c.id = ord.customer_id
    inner join order_items as ordi on ord.id = ordi.order_id
    group by c.id, c.name
    order by total_spent desc;

    -- indexing
    CREATE INDEX idx_orders_customer_id on orders(customer_id);
    CREATE INDEX idx_order_items_order_id on order_items(order_id);

-- Question 11: Query Optimization Challenge
select c.id as customer_id, c.name, sum(ordi.quantity * ordi.price) as total_spent
from customers as c
inner join orders as ord on c.id = ord.customer_id
inner join order_items as ordi on ord.id = ordi.order_id
group by c.id, c.name
order by total_spent desc;
