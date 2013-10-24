#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

__dir__ ||= File.dirname(__FILE__) # for Ruby 1.x

require 'pry'
require 'open-uri'
require 'pstore'
require __dir__ + '/lib.rb'

debug = false

# Collect
str = File.read(open(VSSEED2ch::THREAD_URI)).force_encoding("Windows-31J")
responses = str.lines.select{|l|
  case l
  when /^<dt>\d+/
    true
  when /^<dt>(\d+).+<dd>(.+)$/
    `post "@Altech_2013 2chパーサーに例外が出現しました！修正待ちなう。"` unless debug
    binding.pry
  else
    false
  end
}.inject([]){|a,l|
  l =~ /^<dt>(\d+).+<dd> (.+)$/m
  a[$1.to_i] = CGI.unescapeHTML($2.gsub("<br> ","\n") # 改行は保持
                                  .gsub("http://","ttp://") # リンクされないように切る
                                  .gsub(/(<[^>]*>)|\t/s){" "}) # 残りのタグは削除
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

responses.each_with_index do |response, index|
  db.transaction do
    tweets = db[VSSEED2ch::THREAD_NUMBER][:tweets]
    
    break if index > 1000
    next if response.nil?
    next if tweets[index]
    begin
      case response.lines.first
      when /^ *>>(\d+)/m
        respond_to = $1.to_i
        text = response[/^ *>>(\d+) *\n*(.*)/m,2]
        reference = tweets[respond_to]
        if reference
          VSSEED2ch.update(tweets,text,index,reference[:id])
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
