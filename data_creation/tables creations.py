import pandas as pd
import random
import numpy as np
import products  # Must contain product lists

def create_synthetic_data(seed, test_index):
    random.seed(seed)
    np.random.seed(seed)

    departments = [
        "Handguns", "Assault Rifles", "Ammunition", "Rifle Scopes", "Pistol Sights",
        "Grips", "Stocks", "Flashlights", "Lasers"
    ]

    department_price_ranges = {
        "Handguns": (1200, 7000),
        "Assault Rifles": (3000, 15000),
        "Ammunition": (5, 80),
        "Rifle Scopes": (300, 3500),
        "Pistol Sights": (80, 900),
        "Grips": (50, 500),
        "Stocks": (200, 1500),
        "Flashlights": (100, 1200),
        "Lasers": (120, 2000),
    }

    all_products = (
        products.assault_rifles +
        products.handguns +
        products.ammunition +
        products.rifle_scopes +
        products.pistol_sights +
        products.grips +
        products.stocks +
        products.flashlights +
        products.lasers
    )

    for idx, prod in enumerate(all_products):
        prod['product_id'] = 1000 + idx
        dname = prod['department_name']
        price_min, price_max = department_price_ranges.get(dname, (100, 10000))
        prod['price'] = random.randint(price_min, price_max)
        prod['stock_quantity'] = random.randint(0, 150)

    products_df = pd.DataFrame(all_products)[
        ["product_id", "name", "description", "price", "stock_quantity", "department_name"]
    ]
    products_df.to_csv(f'products_test{test_index}.csv', index=False)

    # WORKERS: Assign each worker to a department randomly, guarantee no empty departments
    num_workers = 40
    worker_ids = list(range(800, 800 + num_workers))
    departments_list = departments.copy()

    worker_to_dept = {}
    workers_per_dept = {d: [] for d in departments}

    # Step 1: Random assignment
    for wid in worker_ids:
        dept = random.choice(departments_list)
        worker_to_dept[wid] = dept
        workers_per_dept[dept].append(wid)

    # Step 2: Move workers if any department is empty
    empty_departments = [d for d in departments if len(workers_per_dept[d]) == 0]
    while empty_departments:
        max_dept = max(workers_per_dept, key=lambda d: len(workers_per_dept[d]))
        wid_to_move = random.choice(workers_per_dept[max_dept])
        workers_per_dept[max_dept].remove(wid_to_move)
        new_dept = empty_departments.pop()
        workers_per_dept[new_dept].append(wid_to_move)
        worker_to_dept[wid_to_move] = new_dept

    assert len(set(worker_to_dept.values())) == len(departments)
    assert all(len(wids) > 0 for wids in workers_per_dept.values())
    assert sum(len(wids) for wids in workers_per_dept.values()) == num_workers

    # ORDERS
    num_orders = 500
    order_ids = list(range(3000, 3000 + num_orders))
    product_ids = list(products_df["product_id"])
    order_rows = []
    for order_id in order_ids:
        products_in_order = random.sample(product_ids, random.randint(1, 5))
        for pid in products_in_order:
            quantity = random.randint(1, 7)
            order_rows.append([order_id, pid, quantity])
    ordered_df = pd.DataFrame(order_rows, columns=["order_id", "product_id", "quantity"])
    ordered_df.to_csv(f'ordered_test{test_index}.csv', index=False)

    # COMPLAINTS: Only inside same department, no self-complaints, one complaint per pair max
    complaint_reasons = [
        "Inventory mistake", "Unprofessional behavior",
        "Wrong product", "Bad communication", "Safety violation"
    ]
    complaint_rows = set()
    for dept, wids in workers_per_dept.items():
        for complainer_id in wids:
            # Targets = all other workers in department except self
            possible_targets = [wid for wid in wids if wid != complainer_id]
            if not possible_targets:
                continue  # Only one worker in department, skip complaints
            # Choose how many unique workers to complain about (at most one per target)
            num_complaints = random.randint(0, min(4, len(possible_targets)))
            if num_complaints > 0:
                targets = random.sample(possible_targets, num_complaints)
                for complained_on_id in targets:
                    reason = random.choice(complaint_reasons)
                    complaint_rows.add((complainer_id, complained_on_id, dept, reason))
    complaint_df = pd.DataFrame(list(complaint_rows), columns=[
        "complainer_id", "complained_on_id", "department_name", "reason"
    ])
    complaint_df.to_csv(f'complaint_test{test_index}.csv', index=False)

    # REVIEWS
    num_customers = 120
    customer_ids = list(range(2000, 2000 + num_customers))
    review_rows = set()
    extreme_means = [0.1, 1, 2, 3, 4, 4.8]
    std = 1.2

    for order_id in ordered_df["order_id"].unique():
        num_reviews = random.randint(1, 3)
        chosen_customers = random.sample(customer_ids, num_reviews)
        for cust_id in chosen_customers:
            mean = random.choice(extreme_means)
            rating = np.clip(np.random.normal(mean, std), 1, 5)
            rating = int(np.clip(np.round(np.random.normal(mean, std)), 1, 5))
            description = random.choice([
                "Fast delivery", "Great product", "Not satisfied", "Will order again",
                "Packing was bad", "Excellent service", "Product as described", "Late delivery"
            ])
            review_rows.add((order_id, cust_id, description, rating))

    review_df = pd.DataFrame(list(review_rows), columns=[
        "order_id", "customer_id", "description", "rating"
    ])
    review_df.to_csv(f'review_test{test_index}.csv', index=False)

# Generate 5 datasets as before
for idx, seed in enumerate([0, 1, 2, 3, 4]):
    create_synthetic_data(seed, idx)
