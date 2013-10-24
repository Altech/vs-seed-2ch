#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'pry'
require 'open-uri'
require 'twitter'

THREAD_URI = 'http://toro.2ch.net/test/read.cgi/arc/1379376057'

current_thread_number = 326

str = File.read(open(THREAD_URI)).force_encoding("Windows-31J")

responses = str.lines.select{|l|
  case l
  when /^<dt>\d+/
    true
  when /^<dt>(\d+).+<dd>(.+)$/
    `post "@Altech_2013 2chパーサーに例外が出現しました！修正待ちなう。"`
    binding.pry
  else
    false
  end
}.inject([]){|a,l|
  l =~ /^<dt>(\d+).+<dd> (.+)$/
  a[$1.to_i] = CGI.unescapeHTML($2.gsub("<br> ","\n").gsub("http://","ttp://").gsub(/(<[^>]*>)|\t/s){" "})
  a
}

TwitterConfig = JSON.parse(File.read(__dir__ + '/secret.json'))

# Set OAuth
Twitter.configure {|config|
  %w[consumer_key consumer_secret oauth_token oauth_token_secret].each do |member|
    config.send "#{member}=", TwitterConfig[member.to_sym]
  end
}

def to_tweet(str,index,id=nil)
  
  ret = if id
    <<TWEET
@vs_seed_2ch #{str.size > 120 ? str[0..100] + '...' + THREAD_URI + '/' + index.to_s : str}
##{index}
TWEET
        else
    <<TWEET
#{str.size > 130 ? str[0..110] + '...' + THREAD_URI + '/' + index.to_s : str}
##{index}
TWEET
        end
  binding.pry if ret.size > 140
  ret.encode 'utf-8'
end

require 'pstore'

db = PStore.new('/Users/Altech/db')
db.transaction do
  thread = db[current_thread_number] ||= Hash.new
  tweets = db[current_thread_number][:tweets] ||= Array.new

  thread[:uri] ||= THREAD_URI
  
  responses.each_with_index do |response, index|
    next if response.nil?
    next if tweets[index]
    
    case response
    when /^ >>(\d+) *\n*(.*)/m
      respond_to, text = $1.to_i, $2
      reference = tweets[respond_to]
      if reference
        tw = Twitter.update to_tweet(text,index,reference[:id]), {"in_reply_to_status_id"=>reference[:id]}
        tweets[index] = tw
      else
        tw = Twitter.update to_tweet(text,index)
        tweets[index] = tw
      end
    else
      tw = Twitter.update to_tweet(response, index)
      tweets[index] = tw
    end
    break if index > 1000
  end

end
