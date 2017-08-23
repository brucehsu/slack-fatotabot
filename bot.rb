require_relative "secret"
require_relative "db_helpers"
require "slack-ruby-bot"

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
end

class Fatotabot < SlackRubyBot::Bot
  match /set (?<weight>\d+(\.\d+)?)$/i do |client, data, match|
    if DBHelper.insert_weight(data.user, match[:weight])
      client.say(channel: data.channel, text: "<@#{data.user}> 你現在重 #{match[:weight]}，不想讓人看到的話可以私訊")
    else
      client.say(channel: data.channel, text: "啊啊啊我壞掉惹")
    else
      client.say(channel: data.channel, text: "啊啊啊我壞掉惹")
    end
  end
end

Fatotabot.run