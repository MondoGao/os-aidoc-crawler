require 'find'
require 'open-uri'
require 'thread'
require 'uri'
require 'fileutils'
require 'bundler/setup'
require 'json'
Bundler.require


agent = Mechanize.new
data = []
agent.get('http://www.kuai65.com/standards?province=%E5%85%A8%E9%83%A8&degree=%E5%AD%A6%E5%A3%AB')
while true
  page = agent.page
  page.css('.home-text-overflow').each do |li|
      data << {name: li.attribute('title').value, id: li.attribute('href').value.gsub('/standards/', '')}
  end
  next_button = page.at_css('[rel=next]')
  if !!next_button
    agent.click next_button
  else
    break
  end
end
file = File.open('benke_template_data.json', 'w+')
file << data.to_json