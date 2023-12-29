CREATE TABLE product_sales(
    id SERIAL NOT NULL,
    product_id integer NOT NULL,
    quantity integer NOT NULL,
    total_amount double precision NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    PRIMARY KEY(id)
);