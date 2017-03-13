require 'find'
require 'open-uri'
require 'thread'
require 'uri'
require 'fileutils'
require 'json'
require 'bundler/setup'
Bundler.require

data_file = File.open('./benke_template_data.json', 'r+')
data = JSON.parse(data_file.read)

agent = Mechanize.new
page = agent.get('http://www.kuai65.com/users/sign_in')
login_form = page.forms[0]
login_form['user[phone]'] = '18672310260'
login_form['user[password]'] = '#&&j8jKa9YW3'
agent.submit login_form

data.each do |paper|
  unless Dir["templates/#{paper['name']}.pdf"].size > 0
    puts "#{paper['name']} start"
    agent.get('http://www.kuai65.com/theses/3242/templates/edit')
    agent.page.form['standard_id'] = paper['id']
    agent.submit agent.page.form
    agent.click agent.page.at_css('.ke-icon-generate_word')
    agent.submit agent.page.form
    download_link = agent.page.links.select {|link| link.href.match /ft\=pdf/}[0]
    while !download_link
      sleep 1
      agent.get agent.page.uri.to_s
      download_link = agent.page.links.select {|link| link.href.match /ft\=pdf/}[0]
    end
    agent.download(download_link.href, "templates/#{paper['name']}.pdf")
    puts "#{paper['name']} downloaded"
  else
    puts "Skip #{paper['name']}"
  end
end
