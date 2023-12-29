CREATE TABLE payment_orders(
    id SERIAL NOT NULL,
    status varchar(255),
    payment_date date NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    PRIMARY KEY(id)
);