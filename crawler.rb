require 'find'
require 'open-uri'
require 'thread'
require 'bundler/setup'
Bundler.require

class Crawler
  @@skip_num = 0

  def initialize(url, name)
    @agent = Mechanize.new
    @name = name.gsub(/\:/, "：").gsub(/\"/, "“").gsub(/\</, "《").gsub(/\>/, "》").gsub(/[\*\\\/\|]/, "-")
    @url = url
    if Dir["results/#{@name}.pdf"].size > 0
      @@skip_num += 1
      puts "Skip #{@@skip_num}th #{@name}\n".colorize(:light_yellow)
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

    workers = (0..3).map do
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
    begin
      page = @agent.get(@url)
      @real_url = 'http://f.wanfangdata.com.cn/' + page.search('#doDownload').attribute('href').value
    rescue => e
      puts e
      self.get_real_url
    end
  end

  def download
    puts "Downloading #{@name} #{@url}\n".colorize(:light_blue)
    begin
      paper = open(@real_url) do |f|
        f.read
      end

      file = File.new "results/#{@name}.pdf", 'w+'
      file.binmode
      file << paper
      file.flush
      file.close

      puts "#{@name} download complete.\n".colorize(:green)
    rescue => e
      puts e
      # self.download
      puts "Timeout".colorize(:red)
    end
  end

end

Crawler.start('links')
