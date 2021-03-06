require 'dotenv/load'
require 'slack-ruby-client'

raise 'Missing ENV[SLACK_API_TOKENS]!' unless ENV.key?('SLACK_API_TOKENS')

$stdout.sync = true
logger = Logger.new($stdout)
logger.level = Logger::DEBUG

threads = []
exclusions = ENV['EXCLUDE_CHANNELS'].split

ENV['SLACK_API_TOKENS'].split.each do |token|
  logger.info "Starting #{token[0..12]} ..."

  client = Slack::RealTime::Client.new(token: token)

  client.on :hello do
    logger.info "Successfully connected, welcome '#{client.self.name}' to the '#{client.team.name}' team at https://#{client.team.domain}.slack.com."
  end

  client.on(:user_typing) do |data|
    name = if client.channels[data.channel]
            client.channels[data.channel]['name']
          else
            client.users[data.user]['name']
          end

    if exclusions.include?(name)
      logger.info "Skipping #{name}"
    else
      client.typing channel: data.channel
      logger.info "#{client.users[data.user]['name']} typing in #{name}"
    end
  end

  threads << client.start_async
end

threads.each(&:join)
