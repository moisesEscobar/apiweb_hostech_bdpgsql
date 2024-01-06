CREATE TABLE shoppings(
    id SERIAL NOT NULL,
    date_purchase date,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    supplier_customer_id integer NOT NULL DEFAULT 1,
    PRIMARY KEY(id)
);