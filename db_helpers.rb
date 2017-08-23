require_relative "secret"
require 'pg'

@conn = PG.connect(host: 'db',
				   port: 5432,
				   dbname: POSTGRE_DB,
				   user: POSTGRE_USER,
				   password: POSTGRE_PASSWORD)

# Initialize DB tables
@conn.exec("CREATE TABLE IF NOT EXISTS users(
			id BIGSERIAL PRIMARY KEY,
			slack_id TEXT UNIQUE,
			slack_name TEXT);")

@conn.exec("CREATE TABLE IF NOT EXISTS users(
			id BIGSERIAL PRIMARY KEY,
			weight DECIMAL(4,2),
			user_id BIGSERIAL REFERENCES users(id),
			timestamp TIMESTAMP);")