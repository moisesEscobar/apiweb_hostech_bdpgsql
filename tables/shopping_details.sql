CREATE TABLE shopping_details(
    id SERIAL NOT NULL,
    inventory_id integer NOT NULL,
    unit_price double precision NOT NULL,
    shopping_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    PRIMARY KEY(id)
);