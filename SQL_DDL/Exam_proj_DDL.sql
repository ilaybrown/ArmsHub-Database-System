CREATE TABLE customer (
    customer_id       INT PRIMARY KEY,
    email             VARCHAR(255) NOT NULL UNIQUE,
    password          VARCHAR(255) NOT NULL,
    full_name         VARCHAR(255) NOT NULL,
    phone_num         VARCHAR(25),
    license_expiry_date DATE
);

CREATE TABLE customer_login (
    customer_id   INT NOT NULL,
    timestamp     TIMESTAMP NOT NULL,
    ip_address    VARCHAR(45) NOT NULL,
    PRIMARY KEY (customer_id, timestamp, ip_address),
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON DELETE CASCADE
);

CREATE TABLE department (
    name VARCHAR(100) PRIMARY KEY
);

CREATE TABLE product (
    product_id      INT PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    description     VARCHAR(1000),
    price           INT NOT NULL CHECK (price >= 0),
    stock_quantity  INT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    department_name VARCHAR(100) NOT NULL,
    FOREIGN KEY (department_name) REFERENCES department(name) ON DELETE RESTRICT
);

CREATE TABLE worker (
    worker_id   INT PRIMARY KEY,
    worker_name VARCHAR(100) NOT NULL,
    role        VARCHAR(30) NOT NULL CHECK (role IN ('warehouse_worker', 'reservation_manager',
                                                     'security worker','committee_member'))
);

CREATE TABLE warehouse_worker_department (
    worker_id      INT PRIMARY KEY,
    department_name  VARCHAR(100) NOT NULL,
    FOREIGN KEY (worker_id) REFERENCES worker(worker_id) ON DELETE CASCADE,
    FOREIGN KEY (department_name) REFERENCES department(name) ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id     INT PRIMARY KEY,
    customer_id  INT NOT NULL,
    worker_id    INT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON DELETE RESTRICT,
    FOREIGN KEY (worker_id) REFERENCES worker(worker_id) ON DELETE RESTRICT
);

CREATE TABLE ordered (
    order_id    INT NOT NULL,
    product_id  INT NOT NULL,
    quantity    INT NOT NULL CHECK (quantity > 0),
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE RESTRICT
);

CREATE TABLE complaint (
    complainer_id    INT NOT NULL,
    complained_on_id INT NOT NULL,
    department_name  VARCHAR(100) NOT NULL,
    reason           VARCHAR(255) NOT NULL,
    PRIMARY KEY (complainer_id, complained_on_id, department_name),
    FOREIGN KEY (complainer_id) REFERENCES worker(worker_id) ON DELETE RESTRICT,
    FOREIGN KEY (complained_on_id) REFERENCES worker(worker_id) ON DELETE RESTRICT,
    FOREIGN KEY (department_name) REFERENCES department(name) ON DELETE RESTRICT,
    CHECK (complainer_id <> complained_on_id)
);

CREATE TABLE order_consult (
    order_id            INT PRIMARY KEY,
    worker_id           INT NOT NULL,
    consulted_worker_id INT NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (worker_id) REFERENCES worker(worker_id) ON DELETE RESTRICT,
    FOREIGN KEY (consulted_worker_id) REFERENCES worker(worker_id) ON DELETE RESTRICT,
    CHECK (worker_id <> consulted_worker_id)
);

CREATE TABLE security_login_check (
    customer_id        INT NOT NULL,
    timestamp          TIMESTAMP NOT NULL,
    ip_address         VARCHAR(45) NOT NULL,
    security_worker_id INT NOT NULL,
    PRIMARY KEY (customer_id, timestamp, ip_address),
    FOREIGN KEY (customer_id, timestamp, ip_address)
        REFERENCES customer_login(customer_id, timestamp, ip_address) ON DELETE CASCADE,
    FOREIGN KEY (security_worker_id) REFERENCES worker(worker_id) ON DELETE RESTRICT
);

CREATE TABLE security_committee_consult (
    customer_id         INT NOT NULL,
    timestamp           TIMESTAMP NOT NULL,
    ip_address          VARCHAR(45) NOT NULL,
    security_worker_id  INT NOT NULL,
    committee_member_id INT NOT NULL,
    PRIMARY KEY (customer_id, timestamp, ip_address, security_worker_id),
    FOREIGN KEY (customer_id, timestamp, ip_address)
        REFERENCES security_login_check(customer_id, timestamp, ip_address) ON DELETE CASCADE,
    FOREIGN KEY (security_worker_id) REFERENCES worker(worker_id) ON DELETE RESTRICT,
    FOREIGN KEY (committee_member_id) REFERENCES worker(worker_id) ON DELETE RESTRICT,
    CHECK (security_worker_id <> committee_member_id)
);

CREATE TABLE review (
    order_id    INT NOT NULL,
    customer_id INT NOT NULL,
    rating      INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    description VARCHAR(1000),
    PRIMARY KEY (order_id, customer_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON DELETE CASCADE
);
