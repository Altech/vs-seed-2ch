require 'twitter'
require 'json'

module VSSEED2ch
  module_function
  
  BASE_DIR = File.dirname(__FILE__)

  thread = JSON.parse(File.read(BASE_DIR + '/thread.json'))
  THREAD_URI = thread['uri']
  THREAD_NUMBER = thread['number']

  DATABASE = BASE_DIR + '/database'

  def configure(credential_path)
    credential = JSON.parse(File.read credential_path)
    Twitter.configure {|config|
      %w[consumer_key consumer_secret oauth_token oauth_token_secret].each do |member|
        config.send "#{member}=", credential[member]
      end
    }
  end

  def update(tweets,str,index,id=nil)
    tw = if id
           Twitter.update to_tweet(str,index,id), {"in_reply_to_status_id"=>id}
         else
           Twitter.update to_tweet(str,index)
         end
    tweets[index] = tw
  end
  
  def to_tweet(str,index,id=nil)
    tw = if id
           <<TWEET
@vs_seed_2ch #{str.size > 120 ? str[0..100] + '.. ' + THREAD_URI + '/' + index.to_s : str}
##{index}
TWEET
         else
           <<TWEET
#{str.size > 130 ? str[0..110] + '.. ' + THREAD_URI + '/' + index.to_s : str}
##{index}
TWEET
         end
    tw.encode('utf-8')
  end
  
end
