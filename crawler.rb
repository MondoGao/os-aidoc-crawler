require 'find'
require 'open-uri'
require 'thread'
require 'uri'
require 'fileutils'
require 'bundler/setup'
Bundler.require

class Crawler
  @@skip_num = 0

  def initialize(url, name)
    @agent = Mechanize.new
    @name = name.gsub(/\:/, "：").gsub(/\"/, "“").gsub(/\</, "《").gsub(/\>/, "》").gsub(/[\*\\\/\|]/, "-")
    @url = url
    @path = "results/#{@name}.pdf"

    if Dir[@path].size > 0
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

    workers = (0..0).map do
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
    begin
      uri = URI(@real_url)
      download_path = "downloading/#{@name}.pdf"

      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Get.new uri

        http.request request do |response|
          total = response['Content-Length'].to_i
          finish = 0

          File.open download_path, 'w+', binmode: true do |io|
            response.read_body do |chunk|
              io.write chunk
              finish += chunk.size
              puts "#{@name}:#{finish.to_f / total * 100}%\n".colorize(:blue)
            end
          end
          FileUtils.mv download_path, @path
        end
      end

    rescue => e
      File.delete "results/#{@name}.pdf"
      puts "Timeout".colorize(:red)
      raise e

      # self.download
    end
  end

end

Crawler.start('links')
