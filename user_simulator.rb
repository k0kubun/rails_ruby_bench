#!/usr/bin/env ruby

# Initially based on Discourse's user_simulator script

require 'optparse'
require 'gabbler'

#require File.expand_path(File.join(File.dirname(__FILE__), "work/discourse/config/environment"))

unless ["profile", "development", nil].include? ENV["RAILS_ENV"]
  puts "User simulator prefers to be run in profile or development, not #{ENV["RAILS_ENV"].inspect}."
  exit -1
end

user_id = nil
random_seed = nil
delay = nil
iterations = 100
warmup_iterations = 50

OptionParser.new do |opts|
  opts.banner = "Usage: ruby user_simulator.rb [options]"
  opts.on("-u", "--user NUMBER", "user id") do |u|
    user_id = u.to_i
  end
  opts.on("-r", "--random-seed NUMBER", "random seed") do |r|
    random_seed = r.to_i
  end
  opts.on("-d", "--delay NUMBER", "delay") do |d|
    delay = d.to_f
  end
  opts.on("-n", "--number NUMBER", "number of iterations") do |n|
    iterations = n.to_i
  end
  opts.on("-w", "--warmup NUMBER", "number of warm-up iterations") do |n|
    warmup_iterations = n.to_i
  end
end.parse!

unless user_id
  puts "user must be specified"
  exit -1
end

# We want our script to generate a consistent output, so
# we monkeypatch Array#sample to use our RNG.
RNG = Random.new(random_seed)
class Array
  def sample
    self[RNG.rand(size)]
  end
end

def sentence
  @gabbler ||= Gabbler.new.tap do |gabbler|
    story = File.read(File.dirname(__FILE__) + "/alice.txt")
    gabbler.learn(story)
  end

  sentence = ""
  until sentence.length > 800 do
    sentence << @gabbler.sentence
    sentence << "\n"
  end
  sentence
end

user = User.find(user_id)
last_topics = Topic.order('id desc').limit(10).pluck(:id)

puts "Simulating activity for user id #{user.id}: #{user.name}"

# We want four actions - read, write, update and reply
ACTION_TYPES = 4

# Randomize which action(s) to take, and randomize topic and reply data, plus a random number for offsets.
actions = (1..(iterations + warmup_iterations)).map { |i| [ i, RNG.rand() * ACTION_TYPES + 1, sentence, RNG.rand() ] }

# URL example: http://localhost:4567/t/she-said-aloud-how-brave-theyll-all-think-me-at/63

(iterations + warmup_iterations).times do |i|
  case actions[i][1]
  when 1
    # Read
    sleep 0.1
  when 2
    # Write
    sleep 0.1
  when 3
    # Update
    sleep 0.1
  when 4
    # Reply
    sleep 0.1
  else
    raise "Something is wrong!"
  end
end

=begin
while true
  puts "Creating a random topic"
  category = Category.where(read_restricted: false).order('random()').first
  PostCreator.create(user, raw: sentence, title: sentence[0..50].strip, category:  category.name)

  puts "creating random reply"
  PostCreator.create(user, raw: sentence, topic_id: last_topics.sample)

  sleep 2
end
=end