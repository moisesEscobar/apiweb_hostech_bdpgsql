CREATE TABLE products(
    id SERIAL NOT NULL,
    name varchar(255) NOT NULL,
    description text,
    sku varchar(255) NOT NULL,
    price double precision DEFAULT '0'::double precision,
    reorder_point integer DEFAULT 0,
    supplier_customer_id integer NOT NULL,
    brand_id integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    path_file varchar(255),
    PRIMARY KEY(id)
);
CREATE INDEX idx_products_brand_id ON "products" USING btree ("brand_id");