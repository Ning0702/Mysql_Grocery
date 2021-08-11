-- Find the orders in the current year
USE sql_store;

-- Method 1
SELECT *
FROM orders
WHERE order_date > '2018-12-31';

-- Method 2
SELECT *
FROM orders
WHERE YEAR(order_date) = YEAR(NOW());

-- Method 3
USE sql_store;
SELECT *
FROM orders
WHERE order_date >= CONCAT (EXTRACT(YEAR FROM NOW()), '-01-01');


-- Query the products in a few possibilities
SELECT * FROM products;
SELECT *
FROM products
WHERE quantity_in_stock IN (49, 38, 72);


-- Query data produced in a period of time
SELECT *
FROM customers
WHERE birth_date BETWEEN '1990-01-01' AND '2000-01-01';


-- Query data containing some critical words
SELECT *
FROM customers
WHERE address LIKE '%trail%' OR address LIKE '%avenue%';
SELECT *
FROM customers
WHERE phone NOT LIKE '%9';


-- Regular expression search with critical words
SELECT * FROM customers;
SELECT * 
FROM customers
WHERE first_name REGEXP 'elka|ambur';
SELECT *
FROM customers
WHERE last_name REGEXP 'ey$|on$';
SELECT *
FROM customers
WHERE last_name REGEXP '^my|se';
SELECT *
FROM customers
WHERE last_name REGEXP 'b[ru]';


-- Iner join
SELECT p.product_id, name, quantity, oi.unit_price
FROM order_items oi 
JOIN products p 
     ON oi.product_id = p.product_id;

USE sql_invoicing;
SELECT p.date, c.name AS client, p.amount, pm.name
FROM payments p
JOIN clients c
	USING (client_id)
JOIN payment_methods pm
	ON p.payment_method = pm.payment_method_id;
  
USE sql_invoicing;
SELECT c.client_id, c.name, p.date, pm.name AS method
FROM clients c
JOIN payments p
    ON c.client_id = p.client_id
JOIN payment_methods pm
    ON p.payment_method = pm.payment_method_id;


-- outer join
SELECT p.product_id, name, quantity
FROM products p
LEFT JOIN order_items oi
     ON p.product_id = oi.product_id
ORDER BY p.product_id;

SELECT o.order_date, o.order_id, c.first_name AS shipper, os.name AS status
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
LEFT JOIN order_statuses os
    ON o.status = os.order_status_id
ORDER BY status;


-- Cross join
USE sql_store;
SELECT *
FROM shippers s 
CROSS JOIN products;


-- Union
SELECT customer_id, first_name, points, 'Bronze' AS type
FROM customers
WHERE points < 2000
UNION
SELECT customer_id, first_name, points, 'Silver' AS type
FROM customers
WHERE points BETWEEN 2000 AND 3000
UNION
SELECT customer_id, first_name, points, 'Gold' AS type
FROM customers
WHERE points > 3000
ORDER BY first_name;

SELECT 
  'First half of 2019' AS date_range,
  SUM(invoice_total) AS total_sales,
  SUM(payment_total) AS total_payments,
  SUM(invoice_total - payment_total) AS what_we_expect
FROM invoices
WHERE due_date BETWEEN '2019-01-01' AND '2019-06-30'
UNION
SELECT 
  'Second half of 2019' AS date_range,
  SUM(invoice_total) AS total_sales,
  SUM(payment_total) AS total_payments,
  SUM(invoice_total - payment_total) AS what_we_expect
FROM invoices
WHERE due_date BETWEEN '2019-07-01' AND '2019-12-31'
UNION
SELECT 
  'Total' AS date_range,
  SUM(invoice_total) AS total_sales,
  SUM(payment_total) AS total_payments,
  SUM(invoice_total - payment_total) AS what_we_expect
FROM invoices
WHERE due_date BETWEEN '2019-01-01' AND '2019-12-31';


-- Insert values	
INSERT INTO products 
VALUES (DEFAULT, 'formula', 2, 25.99),
	   (DEFAULT, 'diaper', 3, 26.99),
       (DEFAULT, 'babyfood', 4, 10.99);


-- Create table
CREATE TABLE invoice_archive AS
SELECT i.invoice_id, i.invoice_date, c.name, i.payment_date
FROM invoices i 
JOIN clients c USING (client_id)
WHERE i.payment_date NOT LIKE 'NULL';


-- Update table
UPDATE customers
SET points = points + 50
WHERE birth_date < '1990-001-01';

UPDATE orders
SET comments = 'Gold'
WHERE customer_id IN 
				(SELECT customer_id
				FROM customers c
				WHERE points > 3000);


-- Combo
SELECT 
     p.date,
     pm.name AS payment_method,
     SUM(p.amount) AS total_paymentscustomerscustomers
FROM payments p
JOIN payment_methods pm
    ON p.payment_method = pm.payment_method_id
GROUP BY date, payment_method
ORDER BY date;

SELECT 
   c.customer_id,
   c.first_name,
   c.last_name,
   c.state,
   SUM(oi.quantity * oi.unit_price) AS total_spend
FROM customers c
JOIN orders o
    USING (customer_id)
JOIN order_items oi
    USING (order_id)
WHERE state = 'VA'
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING total_spend >100;
   
   
 -- Join vs. Subquery
USE sql_invoicing;
SELECT 
     pm.name AS payment_method,
     SUM(amount) AS total
FROM payments p
JOIN payment_methods pm
    ON p.payment_method = pm.payment_method_id
GROUP BY pm.name WITH ROLLUP;

USE sql_store;
SELECT *
FROM products
WHERE unit_price > (
      SELECT unit_price 
	  FROM products
	  WHERE product_id = 3);
      
USE sql_hr;
SELECT *
FROM employees
WHERE salary > (
     SELECT AVG(salary)
     FROM employees
     # GROUP BY employee_id
     );
     
USE sql_store;
SELECT *
FROM products
WHERE name NOT IN (
	SELECT p.name
	FROM order_items oi
		JOIN products p
		USING (product_id)
	GROUP BY p.name
);

SELECT *
FROM products
WHERE product_id NOT IN (
	SELECT DISTINCT product_id
    FROM order_items
);


 -- Find clients without invoices
USE sql_invoicing;
SELECT *
FROM clients
WHERE client_id NOT IN (
	SELECT DISTINCT client_id
    FROM invoices
);


-- Find customers who have ordered lettuce
USE sql_store;
SELECT customer_id, first_name, last_name
FROM customers
WHERE customer_id IN (
	SELECT customer_id
	FROM orders
	WHERE order_id IN (
		SELECT order_id
		FROM order_items
		WHERE product_id = 3
));

SELECT DISTINCT o.customer_id, c.first_name, c.last_name
FROM orders o
JOIN order_items oi USING (order_id)
JOIN customers c USING(customer_id)
WHERE oi.product_id = 3;

SELECT *
FROM customers
WHERE customer_id IN (
	SELECT o.customer_id
	FROM order_items OI
	JOIN orders o USING (order_id)
	WHERE product_id = 3
);

-- Select invoices larger than all invoices of client 3
USE sql_invoicing;
SELECT client_id, COUNT(invoice_id)
FROM invoices
GROUP BY client_id
HAVING COUNT(invoice_id) > (
	SELECT COUNT(invoice_id)
	FROM invoices 
	WHERE client_id = 3
);

-- Select clients with at least two invoices
USE sql_invoicing;
SELECT *
FROM clients
WHERE client_id IN (
	SELECT client_id
	FROM invoices
	GROUP BY client_id
	HAVING COUNT(invoice_id) >= 2
);

-- Select employees whose salary is above the average in their office
USE sql_hr;
SELECT *
FROM employees e
WHERE salary > (
	SELECT AVG(salary) 
	FROM employees
	WHERE office_id = e.office_id
);

-- Select the invoice_total is larger than the avg of this client's all invoices
USE sql_invoicing;
SELECT *
FROM invoices i
WHERE invoice_total > (
	SELECT AVG(invoice_total)
	FROM invoices
	WHERE client_id = i.client_id
);


-- Find the products that have never been ordered -- Not EXISTS
USE sql_store;
SELECT *
FROM products p
WHERE NOT EXISTS (
	SELECT product_id
    FROM order_items
    WHERE product_id = p.product_id
);


-- Subquery reuse
SELECT 
	invoice_id, 
	invoice_total, 
	(SELECT AVG(invoice_total)
		FROM invoices) AS invoice_average,
	 invoice_total - (SELECT invoice_average) AS difference
FROM invoices;

SELECT
	client_id,
	name,
	(SELECT SUM(invoice_total)
		FROM invoices
        WHERE client_id = c.client_id
		GROUP BY client_id) AS total_sales,
	(SELECT AVG(invoice_total)
		FROM invoices) AS average,
	(SELECT total_sales) - (SELECT average) AS difference
FROM clients c;


SELECT NOW(), CURDATE(), CURTIME();
SELECT DAYNAME(NOW());
SELECT CONCAT (EXTRACT(YEAR FROM NOW()), '-01-01') AS time;


-- Replace Null data -- IFNULL
SELECT 
	CONCAT(first_name, ' ', last_name) AS customer,
    IFNULL(phone, 'Unknown') AS phone 
FROM customers;


-- IF 
SELECT 
	product_id,
    name,
    COUNT(*) AS orders,
    IF( COUNT(*) > 1, 'Many times', 'Once') AS frequency
FROM products
JOIN order_items USING(product_id)
GROUP BY product_id, name;


-- Multiple situations -- CASE
SELECT 
	CONCAT(first_name, ' ', last_name),
    points,
    CASE
		WHEN points>3000 THEN 'Gold'
        WHEN points>2000 AND points <= 3000 THEN 'Silver'
        ELSE 'Bronze'
	END AS category
FROM customers
ORDER BY points DESC;


-- CREATE VIEW
CREATE VIEW clients_balance AS 
SELECT 
	client_id,
    name,
    SUM(invoice_total) - SUM(payment_total) AS balance
FROM clients c
JOIN invoices i USING(client_id)
GROUP BY client_id, name;


-- Create the stored procedure and Call it
DROP PROCEDURE IF EXISTS get_invoices_with_balance;
DELIMITER $$
CREATE PROCEDURE get_invoices_with_balance()
BEGIN
	SELECT *
    FROM invoices
    WHERE invoice_total - payment_total > 0;
END $$
DELIMITER ; 

DROP PROCEDURE IF EXISTS get_clients_by_state;
DELIMITER $$
CREATE PROCEDURE get_clients_by_state(state CHAR(2))
BEGIN
	SELECT * FROM clients c
    WHERE c.state = IFNULL(state, c.state); -- If the value is null, return all the info, otherwise return the asked
END $$
DELIMITER ;
CALL get_clients_by_state('NY');


DROP PROCEDURE IF EXISTS get_invoices_by_client;
DELIMITER $$
CREATE PROCEDURE get_invoices_by_client( client_id CHAR(1))
BEGIN
	SELECT * FROM invoices i
    WHERE i.client_id = client_id;
END $$
DELIMITER ;
CALL get_invoices_by_client(3);
    
DROP PROCEDURE IF EXISTS get_payments;
DELIMITER $$
CREATE PROCEDURE get_payments(client_id INT(4), payment_method_id TINYINT(1))
BEGIN
	SELECT * 
    FROM payments p
    JOIN payment_methods pm
    ON p.payment_method = pm.payment_method_id
    -- WHERE CASE
	-- 		WHEN client_id IS NULL AND payment_method_id IS NULL THEN p.client_id = p.client_id
    --      WHEN client_id IS NOT NULL AND payment_method_id IS NULL THEN p.client_id = client_id
    --      ELSE p.client_id = client_id AND pm.payment_method_id = payment_method_id
	--	  END;
    WHERE p.client_id = IFNULL(client_id, p.client_id) AND
		  pm.payment_method_id = IFNULL(payment_method_id, pm.payment_method_id);
END $$
DELIMITER ;


-- Update stored procedure data
DELIMITER $$
CREATE PROCEDURE invoice_payment (
	invoice_id INT,
    payment_total DECIMAL(9, 2),
    payment_date DATE
)
BEGIN
	IF payment_total <= 0 THEN 
		SIGNAL SQLSTATE '22003' 
			SET MESSAGE_TEXT = 'Invalid payment amount';
	END IF;
	UPDATE invoice i
    SET 
		i.payment_total = payment_total,
        i.payment_date = payment_date
	WHERE i.invoice_id = invoice_id;
END $$
DELIMITER ;


-- Build Functions with Local variable 
DROP FUNCTION IF EXISTS get_risk_factor_for_client;
DELIMITER $$
CREATE FUNCTION get_risk_factor_for_client(client_id INT)
RETURNS INTEGER
READS SQL DATA
BEGIN
	DECLARE risk_factor DECIMAL(9, 2) DEFAULT 0;
    DECLARE invoices_total DECIMAL(9, 2);
    DECLARE invoices_count INT;
    
    SELECT COUNT(*), SUM(invoice_total)
    INTO invoices_count, invoices_total
    FROM invoices i
    WHERE i.client_id = client_id;
    
    SET risk_factor = invoices_total / invoices_count * 5;
    
    RETURN IFNULL(risk_factor, 0);
END $$
DELIMITER ;


-- call function
SELECT 
	client_id,
    name,
    get_risk_factor_for_client(client_id) AS risk_factor
FROM clients;