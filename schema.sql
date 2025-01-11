-- schema.sql
CREATE TABLE example_table (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE another_table (
    id SERIAL PRIMARY KEY,
    description TEXT NOT NULL,
    example_id INT REFERENCES example_table(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
