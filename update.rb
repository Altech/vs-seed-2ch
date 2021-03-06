#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

__dir__ ||= File.dirname(__FILE__) # for Ruby 1.x

require 'pry'
require 'pstore'
require __dir__ + '/lib.rb'
require 'net/http'

debug = false

puts "===#{Time.now}==="

# Collect
res = Net::HTTP.get_response(URI(VSSEED2ch::THREAD_URI))
if not res.is_a?(Net::HTTPSuccess)
  abort 'Cannot get HTTPSuccess'
end
str = res.body.force_encoding("Windows-31J")

responses = str.lines.select{|l|
  case l
  when /^<dt>\d+/
    true
  when /^<dt>(\d+).+<dd>(.+)$/
    `post "@Altech_2014 2chパーサーに例外が出現しました！修正待ちなう。"` unless debug
    binding.pry
  else
    false
  end
}.inject([]){|a,l|
  l =~ /^<dt>(\d+).+<dd> (.+)$/m
  a[$1.to_i] = CGI.unescapeHTML($2.gsub("<br> ","\n") # 改行は保持
                                  .gsub("http://","ttp://") # リンクされないように切る
                                  .gsub(/(<[^>]*>)|\t/s){" "} # 残りのタグは削除
                                  .strip)
  a
}

# OAuth
VSSEED2ch.configure(File.dirname(__FILE__) + '/secret.json')

# Tweet
db = PStore.new(VSSEED2ch::DATABASE)
db.transaction do
  # Schema
  thread = db[VSSEED2ch::THREAD_NUMBER] ||= Hash.new
  thread[:tweets] ||= Array.new
  thread[:uri] ||= VSSEED2ch::THREAD_URI
end

# for parformance
skip = db.transaction do
  tweets = db[VSSEED2ch::THREAD_NUMBER][:tweets]
  index = tweets.drop(1).find_index{|tweet| tweet.nil?}
  index ? index+1 : tweets.size
end

responses.each_with_index do |response, index|
  break if index > 1000
  next if response.nil?
  next if index < skip
  db.transaction do
    tweets = db[VSSEED2ch::THREAD_NUMBER][:tweets]
    next if tweets[index]

    begin
      case response.lines.first
      when /^ *>>(\d+)/m
        respond_to = $1.to_i
        text = response[/^ *>>(\d+) *\n*(.*)/m,2]
        next if VSSEED2ch.spam?(text,respond_to,tweets)
        if reply_tweet = tweets[respond_to]
          VSSEED2ch.update(tweets,text,index,respond_to,reply_tweet.id)
        else
          VSSEED2ch.update(tweets,text,index)
        end
      else
        VSSEED2ch.update(tweets,response,index)
      end

      `post @Altech_2013 "スレが1000超えたよ!"` if index == 1000
    rescue => e
      `post "@Altech_2013 2ch投稿中に例外が出現しました！修正待ちなう。"` unless debug
      binding.pry
    end
  end
end
