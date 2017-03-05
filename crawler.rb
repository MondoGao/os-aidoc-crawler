require 'find'
require 'open-uri'
require 'thread'
require 'bundler/setup'
Bundler.require

class Crawler

  def initialize(url, name)
    @agent = Mechanize.new
    @name = name
    @url = url
    if Dir["results/#{name}.pdf"].size > 0
      puts "Skip #{name}\n".colorize(:light_yellow)
    else
      self.get_real_url
      self.download
    end
  end

  def self.start(path)
    files = self.get_url_files(path)
    work_q = Queue.new
    files.each do |file|
      work_q << file
    end

    workers = (0...2).map do
      Thread.new do
          while file = work_q.pop(true)
            self.new_from_path(file)
          end
      end
    end
    workers.map(&:join)
  end

  def self.get_url_files(path)
    list = []
    Find.find(path) do |file|
      list << file unless file == path
    end
    list
  end

  def self.new_from_path(path)
    file = File.new(path, 'r')
    doc = Nokogiri::HTML(file)
    doc.css('a')[1..-1].each do |a|
      self.new(a.attribute('href').value, a.text)
    end
  end

  def get_real_url
    page = @agent.get(@url)
    @real_url = 'http://f.wanfangdata.com.cn/' + page.search('#doDownload').attribute('href').value
  end

  def download
    puts "Downloading #{@name}\n".colorize(:light_blue)
    paper = open(@real_url) do |f|
      f.read
    end

    file = File.new "results/#{@name}.pdf", 'w+'
    file.binmode
    file << paper
    file.flush
    file.close

    puts "#{@name} download complete.\n".colorize(:green)
  end

end

Crawler.start('links')
