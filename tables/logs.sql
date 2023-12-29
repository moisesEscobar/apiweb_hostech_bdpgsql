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