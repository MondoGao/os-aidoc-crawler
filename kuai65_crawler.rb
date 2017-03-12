require 'find'
require 'open-uri'
require 'thread'
require 'uri'
require 'fileutils'
require 'bundler/setup'
Bundler.require


agent = Mechanize.new
page = agent.get('http://www.kuai65.com/users/sign_in')
login_form = page.forms[0]
login_form['user[phone]'] = '18672310260'
login_form['user[password]'] = '#&&j8jKa9YW3'
agent.submit login_form
agent.click agent.page.link_with(:href => '/theses').click
agent.click agent.page.link_with(:href => "/theses/3242/covers/common")
agent.click agent.page.at_css('.ke-icon-generate_word')
binding.pry
