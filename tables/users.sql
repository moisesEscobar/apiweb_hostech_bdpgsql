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