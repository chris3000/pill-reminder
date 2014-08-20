require 'sinatra'
require 'twilio-ruby'
require 'redis'
require 'yaml'
#require_relative 'sms.rb'


#set up sinatra
configure do
  set :send_sms_password, ENV["PILL_REMINDER_PASSWORD"]
  conf=YAML.load_file('twilio_conf.yml')
  set :twilio_account_sid, ENV["TWILIO_SID"] || conf['account_sid']
  set :twilio_auth_token, ENV["TWILIO_AUTH_TOKEN"] || conf['auth_token']
  set :twilio_from_number, ENV["TWILIO_NUMBER"] || conf['from_number']
  set :reminder_receive_number, ENV["PILL_REMINDER_RECEIVE"]
  set :redis, Redis.new(:host => "127.0.0.1", :port => 6379, :db => 0)
end

helpers do
  def get_msg
    msg = []
    msg << "Hi honey, did you take your pills?"
    msg << "Hey there, just making sure you took your pills.  Let me know."
    msg << "Pill Time!  Did you take them?"
    msg << "Ping, Pill time!  Let me know when you've taken them."
    msg << "Just making sure you took your pills... :)"
    msg << "Hey sexy!  Take your pills!"
    msg[rand(msg.size)]
  end

  def redis
    settings.redis
  end

  def get_reply
    response = []
    response << "yay!"
    response << ":)"
    response << "high five!"
    response << "Did I mention that you look great today?"
    response << "You Did It!"
    response << "You're the best!"
    response << "Good Job!"
    response[rand(response.size)]
  end
end

get "/" do
  ""
end

#receive SMS and see if it's a positive reply
post "/receive_sms/?" do
    puts "post receive_sms"
    puts params.inspect
  body = params["Body"].downcase
  done = (body.include?("yes") || body.include?("done") || body.include?("took") || body.include?("ok"))
  if done  # return message
    twiml = Twilio::TwiML::Response.new do |r|
      r.Sms get_reply
    end
    twiml.text
    #todo set msg in Redis
    redis.set(:took_pills, "true")
  end
end

post "/send_sms/?" do
  puts "post send_sms"
  today = Time.new.to_date.to_s
  last_send = redis.get(:last_send)
  if today != last_send
    #new day- reset
    redis.set(:took_pills, "false")
  end
  redis.set(:last_send, today)
  took_pills = (redis.get(:took_pills)=="true") ? true : false
  @message="password is incorrect.  SMS failed." if settings.send_sms_password != params["password"]
  @message="Already took pills today.  Not sending" if took_pills
  #if there's no message then the password matches and we have all of the required info
  if @message.nil?
    puts "sending sms"
    client = Twilio::REST::Client.new(settings.twilio_account_sid, settings.twilio_auth_token)
    account = client.account
    @sms_reply = account.sms.messages.create({:from => settings.twilio_from_number, :to => params["phone_number"], :body => params["message"]})
    puts "got back this: #{@sms_reply.inspect}"
  end
  @message || "SMS sent"
end