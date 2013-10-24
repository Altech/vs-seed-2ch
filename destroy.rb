#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

__dir__ ||= File.dirname(__FILE__) # for Ruby 1.x

require 'pstore'
require 'twitter'

require __dir__ + '/lib.rb'

VSSEED2ch.configure(File.dirname(__FILE__) + '/secret.json')

db = PStore.new(VSSEED2ch::DATABASE)
db.transaction(true) do
  tweets = db[VSSEED2ch::THREAD_NUMBER][:tweets]
  tweets.each do |tweet|
    next if tweet.nil?
    Twitter.status_destroy tweet[:id]
  end
end

db.transaction do
  db[VSSEED2ch::THREAD_NUMBER][:tweets] = nil
end
