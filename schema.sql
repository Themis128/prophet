-- Create the database
CREATE DATABASE prophet_db;

-- Create the user and set a password
CREATE USER user WITH PASSWORD 'password';

-- Grant privileges to the user
GRANT ALL PRIVILEGES ON DATABASE prophet_db TO user;

-- Connect to the database
\c prophet_db;

-- Define the schema
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
