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
    user_id = user_id_by(slack_id)

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

  def self.incr_weight(slack_id, weight)
    user_id = user_id_by(slack_id)
    weight = lastest_weight_by(user_id).to_f + weight.to_f

    begin
      @@conn.exec_params("INSERT INTO weights(weight, user_id) VALUES($1, $2)", [weight, user_id])
      true
    rescue PG::Error => err
      STDERR.puts err
      false
    end
  end

  def self.decr_weight(slack_id, weight)
    user_id = user_id_by(slack_id)
    weight = lastest_weight_by(user_id).to_f - weight.to_f

    begin
      @@conn.exec_params("INSERT INTO weights(weight, user_id) VALUES($1, $2)", [weight, user_id])
      true
    rescue PG::Error => err
      STDERR.puts err
      false
    end
  end

  def self.weight_diff_ranking
    begin
      users = {}
      @@conn.exec("SELECT id, slack_id FROM users") do |result|
        result.each do |row|
          users[row.values[0]] = row.values[1]
        end
      end

      text = ""

      @@conn.exec("SELECT comp.user_id, comp.last-comp.first AS diff FROM
                  (SELECT DISTINCT ON(user_id) FIRST_VALUE(weight) OVER (PARTITION BY user_id ORDER BY timestamp ASC) AS first,
                    LAST_VALUE(weight) OVER (PARTITION BY user_id ORDER BY timestamp DESC) AS last,
                    user_id FROM weights) AS comp ORDER BY diff ASC") do |result|
        result.each do |row|
          text += sprintf("- <@#{users[row.values[0]]}> %+.2fkg\n", row.values[1])
        end
      end

      text
    rescue PG::Error => err
      STDERR.puts err
      false
    end
  end

  def self.user_id_by(slack_id)
    begin
      user_id = @@conn.exec_params("SELECT id FROM users WHERE slack_id = $1", [slack_id])&.values&.at(0)&.at(0)
      
      if user_id.nil?
        user_id = @@conn.exec_params("INSERT INTO users(slack_id) VALUES($1) RETURNING id", [slack_id]).getvalue(0, 0)
      end

      user_id
    rescue PG::Error => err
      STDERR.puts err
      nil
    end
  end

  def self.lastest_weight_by(user_id)
    begin
      @@conn.exec_params("SELECT weight FROM weights WHERE user_id = $1 ORDER BY timestamp DESC LIMIT 1", [user_id]).getvalue(0, 0)
    rescue PG::Error => err
      STDERR.puts err
      nil
    end
  end
end
