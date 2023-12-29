CREATE TABLE inventories(
    id SERIAL NOT NULL,
    product_id integer NOT NULL,
    quantity integer DEFAULT 0,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    PRIMARY KEY(id)
);