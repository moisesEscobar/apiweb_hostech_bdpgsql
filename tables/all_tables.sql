
CREATE TABLE brands(
    id SERIAL NOT NULL,
    name varchar(255) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    PRIMARY KEY(id)
);


CREATE TABLE inventories(
    id SERIAL NOT NULL,
    product_id integer NOT NULL,
    quantity integer DEFAULT 0,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    PRIMARY KEY(id)
);


CREATE TABLE logs(
    id SERIAL NOT NULL,
    "action" varchar(255) NOT NULL,
    catalog varchar(255) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    user_id integer,
    detail_last jsonb,
    detail_new jsonb
);


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


CREATE TABLE payment_orders(
    id SERIAL NOT NULL,
    status varchar(255),
    payment_date date NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    PRIMARY KEY(id)
);


CREATE TABLE payment_types(
    id SERIAL NOT NULL,
    name varchar(255) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    PRIMARY KEY(id)
);


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
    PRIMARY KEY(id)
);
CREATE INDEX idx_products_brand_id ON "products" USING btree ("brand_id");


CREATE TABLE purchase_orders(
    shopping_id integer NOT NULL,
    payment_order_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    PRIMARY KEY(shopping_id,payment_order_id)
);


CREATE TABLE shoppings(
    id SERIAL NOT NULL,
    inventory_id integer NOT NULL,
    unit_price double precision NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    PRIMARY KEY(id)
);


CREATE TABLE suppliers_customers(
    id SERIAL NOT NULL,
    name varchar(255) NOT NULL,
    phone_number varchar(255),
    description text,
    type_user varchar(255) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    PRIMARY KEY(id)
);


CREATE TABLE users(
    id SERIAL NOT NULL,
    name varchar(255) NOT NULL,
    last_name varchar(255) NOT NULL,
    second_surname varchar(255) NOT NULL,
    phone_number varchar(255),
    email varchar(255) NOT NULL,
    password varchar(255) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    PRIMARY KEY(id)
);