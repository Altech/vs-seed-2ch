# -*- coding: utf-8 -*-
require 'twitter'
require 'json'

class VSSEED2ch

  BASE_DIR = File.dirname(__FILE__)

  thread = JSON.parse(File.read(BASE_DIR + '/thread.json'))
  THREAD_URI = thread['uri']
  THREAD_NUMBER = thread['number']

  DATABASE = BASE_DIR + '/database'

  def self.configure(credential_path)
    credential = JSON.parse(File.read credential_path)
    @@client = Twitter::REST::Client.new do |config|
      %w[consumer_key consumer_secret access_token access_token_secret].each do |member|
        config.send "#{member}=", credential[member]
      end
    end
  end

  # spam?(tweet)==true iff tweet is replied to a spam tweet
  def self.spam?(text,respond_to,tweets)
    reply_tweet = tweets[respond_to]
    return true if reply_tweet.nil?
    res = Net::HTTP.get_response(URI("https://twitter.com/vs_seed_2ch/status/#{reply_tweet.id}"))
    return true if res.is_a? Net::HTTPNotFound
    return false
  end

  def self.update(tweets,str,index,response_index=nil,response_id=nil)
    tw = if response_index
           @@client.update to_tweet(str,index,response_index), {"in_reply_to_status_id"=>response_id}
         else
           @@client.update to_tweet(str,index)
         end
    tweets[index] = tw
  end
  
  def self.to_tweet(str,index,response_index=nil)
    str = str.encode('utf-8')
    tw = if response_index
           <<TWEET
##{index} ≫ ##{response_index}
#{str.size > 125 ? str[0..100] + '.. ' + THREAD_URI + '/' + index.to_s : str}
TWEET
         else
           <<TWEET
##{index}
#{str.size > 130 ? str[0..105] + '.. ' + THREAD_URI + '/' + index.to_s : str}
TWEET
         end
  end
  
end
