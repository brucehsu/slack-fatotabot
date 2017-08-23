require_relative "secret"
require 'pg'

class DBHelper
  @@conn = PG.connect(host: 'db',
                     port: 5432,
                     dbname: POSTGRE_DB,
                     user: POSTGRE_USER,
                     password: POSTGRE_PASSWORD)

  # Initialize DB tables
  @@conn.exec("CREATE TABLE IF NOT EXISTS users(
              id BIGSERIAL PRIMARY KEY,
              slack_id TEXT UNIQUE,
              slack_name TEXT);")

  @@conn.exec("CREATE TABLE IF NOT EXISTS weights(
              id BIGSERIAL PRIMARY KEY,
              weight DECIMAL(4,2),
              user_id BIGSERIAL REFERENCES users(id),
              timestamp TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'utc'));")

  def self.insert_weight(slack_id, weight)
    begin
      user_id = @@conn.exec_params("SELECT id FROM users WHERE slack_id = $1", [slack_id])&.values&.at(0)&.at(0)
      
      if user_id.nil?
        user_id = @@conn.exec_params("INSERT INTO users(slack_id) VALUES($1) RETURNING id", [slack_id]).getvalue(0, 0)
      end

      @@conn.exec_params("INSERT INTO weights(weight, user_id) VALUES($1, $2)", [weight, user_id])
      true
    rescue PG::Error => err
      STDERR.puts err
      false
    end
  end
end
