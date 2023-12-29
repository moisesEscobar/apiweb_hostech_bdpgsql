CREATE TABLE purchase_orders(
    shopping_id integer NOT NULL,
    payment_order_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    PRIMARY KEY(shopping_id,payment_order_id)
);
