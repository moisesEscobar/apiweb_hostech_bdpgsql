CREATE TABLE suppliers_customers(
    id SERIAL NOT NULL,
    name varchar(255) NOT NULL,
    phone_number varchar(255),
    address text,
    type_user varchar(255) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    PRIMARY KEY(id)
);