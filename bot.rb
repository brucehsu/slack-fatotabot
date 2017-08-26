require_relative "secret"
require_relative "db_helpers"
require "slack-ruby-bot"

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
end

module SlackRubyBot
  module Commands
    class Unknown < Base
      match(/^(?<bot>\S*)[\s]*(?<expression>.*)$/)

      def self.call(client, data, _match)
        not_found = ["大聲點我不聽見", "阿鬼你還是說中文吧", "啊我丟聽嘸啊聽嘸", "你是不是想拉安霸"]
        client.say(channel: data.channel, text: not_found.sample)
      end
    end
  end
end

SlackRubyBot.configure do |config|
  config.aliases = ['肥宅霸']
end

class Fatotabot < SlackRubyBot::Bot
  match /肥宅霸\s*set (?<weight>\d+(\.\d+)?).*$/i do |client, data, match|
    if DBHelper.insert_weight(data.user, match[:weight])
      client.say(channel: data.channel, text: "<@#{data.user}> 你現在重 #{match[:weight]}kg，不想讓人看到的話可以私訊")
    else
      client.say(channel: data.channel, text: "啊啊啊我壞掉惹")
    end
  end

  match /肥宅霸\s*\+(?<weight>\d+(\.\d+)?).*$/i do |client, data, match|
    if DBHelper.incr_weight(data.user, match[:weight])
      client.say(channel: data.channel, text: "<@#{data.user}> 你怎麼又胖 #{match[:weight]}kg 惹")
    else
      client.say(channel: data.channel, text: "啊啊啊我壞掉惹")
    end
  end

  match /肥宅霸\s*\-(?<weight>\d+(\.\d+)?).*$/i do |client, data, match|
    if DBHelper.decr_weight(data.user, match[:weight])
      client.say(channel: data.channel, text: "<@#{data.user}> 你瘦了 #{match[:weight]}kg 好棒棒")
    else
      client.say(channel: data.channel, text: "啊啊啊我壞掉惹")
    end
  end

  match /肥宅霸\s*戰.*$/i do |client, data, match|
    rankings = DBHelper.weight_diff_ranking
    if rankings
    client.say(channel: data.channel, text: rankings)
    else
      client.say(channel: data.channel, text: "啊啊啊我壞掉惹")
    end
  end
end

Fatotabot.run