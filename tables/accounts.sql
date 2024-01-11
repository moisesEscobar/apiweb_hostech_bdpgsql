CREATE TABLE accounts(
    id SERIAL NOT NULL,
    account_name varchar(255),
    initial_balance double precision DEFAULT '0'::double precision,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    PRIMARY KEY(id)
);