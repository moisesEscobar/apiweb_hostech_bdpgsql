CREATE TABLE product_sales(
    id SERIAL NOT NULL,
    supplier_customer_id integer NOT NULL,
    date_sale date NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    PRIMARY KEY(id)
);