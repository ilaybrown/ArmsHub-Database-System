
#Query 1

-- Counts departments with problematic workers

CREATE OR ALTER VIEW department_problematic_count AS
SELECT
    complaint.department_name,
    COUNT(*) AS num_problematic_workers
FROM (
    SELECT
        department_name,
        complained_on_id
    FROM
        complaint_test0
    GROUP BY
        department_name,
        complained_on_id
    HAVING
        COUNT(*) >= 2
) AS complaint
GROUP BY
    complaint.department_name;

-- Finds problematic departments

CREATE OR ALTER VIEW departments_low_rating_and_most_problematic AS
SELECT
    sub.department_name,
    AVG(CAST(sub.rating AS FLOAT)) AS avg_rating
FROM (
    SELECT DISTINCT
        ord.order_id,
        prod.department_name,
        rev.rating
    FROM products_test0 AS prod
    JOIN ordered_test0 AS ord
        ON prod.product_id = ord.product_id
    JOIN review_test0 AS rev
        ON ord.order_id = rev.order_id
) AS sub
WHERE
    sub.department_name IN (
        SELECT department_name
        FROM department_problematic_count
        WHERE num_problematic_workers = (
            SELECT MAX(num_problematic_workers) FROM department_problematic_count
        )
    )
GROUP BY
    sub.department_name
HAVING
    AVG(CAST(sub.rating AS FLOAT)) < 3;

-- Aggregates product data

CREATE OR ALTER VIEW products_with_orders_and_rating AS
SELECT
    p.product_id,
    p.name,
    p.department_name,
    p.stock_quantity,
    t.total_quantity_ordered,
    AVG(CAST(sub.rating AS FLOAT)) AS avg_rating
FROM
    products_test0 AS p
    LEFT JOIN (
        SELECT product_id, SUM(quantity) AS total_quantity_ordered
        FROM ordered_test0
        GROUP BY product_id
    ) t
        ON p.product_id = t.product_id
    LEFT JOIN (
        SELECT
            o.product_id,
            o.order_id,
            r.rating
        FROM ordered_test0 o
        LEFT JOIN review_test0 r
            ON o.order_id = r.order_id
        WHERE r.rating IS NOT NULL
    ) sub
        ON p.product_id = sub.product_id
GROUP BY
    p.product_id, p.name, p.department_name, p.stock_quantity, t.total_quantity_ordered;

-- Returns products from problematic

SELECT
    prod_view.name,
    prod_view.total_quantity_ordered - prod_view.stock_quantity AS missing_quantity,
    prod_view.avg_rating
FROM
    products_with_orders_and_rating AS prod_view
WHERE
    prod_view.department_name IN (
        SELECT department_name
        FROM departments_low_rating_and_most_problematic
    )
    AND prod_view.total_quantity_ordered > prod_view.stock_quantity
    AND prod_view.avg_rating < 2.5
ORDER BY
    prod_view.product_id;


#Query 2

-- demanded_products:

CREATE OR ALTER VIEW demanded_products AS
SELECT
    prd.product_id,
    prd.name AS product_name,
    prd.department_name,
    COUNT(DISTINCT ord.order_id) AS demand_level,
    SUM(ord.quantity) AS total_quantity
FROM products_test0 prd
JOIN ordered_test0 ord ON prd.product_id = ord.product_id
GROUP BY prd.product_id, prd.name, prd.department_name
HAVING
    COUNT(DISTINCT ord.order_id) >= ALL (
        SELECT COUNT(DISTINCT ord2.order_id)
        FROM products_test0 prd2
        JOIN ordered_test0 ord2 ON prd2.product_id = ord2.product_id
        WHERE prd2.department_name = prd.department_name
        GROUP BY prd2.product_id
    )
    AND SUM(ord.quantity) > (
        SELECT AVG(total_q)
        FROM (
            SELECT SUM(ord3.quantity) AS total_q
            FROM products_test0 prd3
            JOIN ordered_test0 ord3 ON prd3.product_id = ord3.product_id
            GROUP BY prd3.product_id
        ) avg_tbl
    );

-- qualified_departments:

CREATE OR ALTER VIEW qualified_departments AS
SELECT
    sub.department_name,
    COALESCE(c.num_employees_with_complaints, 0) AS num_employees_with_complaints,
    ROUND(AVG(sub.rating * 1.0), 4) AS avg_rating
FROM (
    SELECT DISTINCT
        ord.order_id,
        rvw.customer_id,
        prd.department_name,
        rvw.rating
    FROM products_test0 prd
    JOIN ordered_test0 ord ON prd.product_id = ord.product_id
    JOIN review_test0 rvw ON ord.order_id = rvw.order_id
) sub
LEFT JOIN (
    SELECT
        department_name,
        COUNT(DISTINCT complained_on_id) AS num_employees_with_complaints
    FROM complaint_test0
    GROUP BY department_name
) c ON sub.department_name = c.department_name
GROUP BY sub.department_name, c.num_employees_with_complaints
HAVING
    ROUND(AVG(sub.rating * 1.0), 4) > 2.5
    AND COALESCE(c.num_employees_with_complaints, 0) <= 3;

-- best_department:

CREATE OR ALTER VIEW best_department AS
SELECT MIN(qdf.department_name) AS best_department
FROM qualified_departments qdf
JOIN demanded_products dmd ON dmd.department_name = qdf.department_name
GROUP BY qdf.department_name
HAVING COUNT(dmd.product_id) = (
    SELECT MAX(num_demanded)
    FROM (
        SELECT COUNT(dmd2.product_id) AS num_demanded
        FROM qualified_departments qdf2
        JOIN demanded_products dmd2 ON dmd2.department_name = qdf2.department_name
        GROUP BY qdf2.department_name
    ) sub_tbl
);

-- Returns all demanded products of the most qualified department

SELECT
    dmd.product_name,
    dmd.department_name,
    ROUND(AVG(rvw.rating * 1.0), 4) AS avg_product_rating
FROM demanded_products dmd
JOIN best_department bst ON dmd.department_name = bst.best_department
JOIN ordered_test0 ord ON dmd.product_id = ord.product_id
JOIN review_test0 rvw ON ord.order_id = rvw.order_id
GROUP BY dmd.product_id, dmd.product_name, dmd.department_name
ORDER BY avg_product_rating DESC, dmd.product_name;


