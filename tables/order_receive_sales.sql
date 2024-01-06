CREATE TABLE order_receive_sales(
    product_sale_id integer NOT NULL,
    order_receive_id integer NOT NULL,
    amount double precision NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    PRIMARY KEY(product_sale_id,order_receive_id)
);