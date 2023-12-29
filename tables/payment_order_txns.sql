CREATE TABLE payment_order_txns(
    id SERIAL NOT NULL,
    status varchar(255) NOT NULL,
    amount double precision NOT NULL DEFAULT '0'::double precision,
    user_id integer,
    payment_type_id integer NOT NULL,
    payment_order_id integer NOT NULL,
    supplier_customer_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    PRIMARY KEY(id)
);