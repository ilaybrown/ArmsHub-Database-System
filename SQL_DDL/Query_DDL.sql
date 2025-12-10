CREATE TABLE products_test0 (
    product_id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(1000) NOT NULL,
    price INT NOT NULL CHECK (price >= 0),
    stock_quantity INT NOT NULL CHECK (stock_quantity >= 0),
    department_name VARCHAR(255) NOT NULL CHECK (
        department_name IN (
            'Handguns', 'Assault Rifles', 'Ammunition',
            'Rifle Scopes', 'Pistol Sights',
            'Grips', 'Stocks', 'Flashlights', 'Lasers'
        )
    )
);

CREATE TABLE complaint_test0 (
    complainer_id INT NOT NULL,
    complained_on_id INT NOT NULL,
    department_name VARCHAR(255) NOT NULL CHECK (
        department_name IN (
            'Handguns', 'Assault Rifles', 'Ammunition',
            'Rifle Scopes', 'Pistol Sights',
            'Grips', 'Stocks', 'Flashlights', 'Lasers'
        )
    ),
    reason VARCHAR(255) NOT NULL CHECK (
        reason IN (
            'Inventory mistake', 'Unprofessional behavior',
            'Wrong product', 'Bad communication', 'Safety violation'
        )
    ),
    PRIMARY KEY (complainer_id, complained_on_id, department_name)
);

CREATE TABLE ordered_test0 (
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity BETWEEN 1 AND 7),
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (product_id) REFERENCES products_test0(product_id)
);

CREATE TABLE review_test0 (
    order_id    INT NOT NULL,
    customer_id INT NOT NULL,
    description VARCHAR(1000),
    rating      INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    PRIMARY KEY (order_id, customer_id)
);