ARGV[0] ||= 5

require 'find'
require 'open-uri'
require 'thread'
require 'uri'
require 'fileutils'
require 'bundler/setup'
Bundler.require

class Crawler
  @@skip_num = 0

  def initialize(url, name, progress_index)
    @agent = Mechanize.new
    @name = name.gsub(/\:/, "：").gsub(/\"/, "“").gsub(/\</, "《").gsub(/\>/, "》").gsub(/[\*\\\/\|]/, "-")
    @url = url
    @path = "results/#{@name}.pdf"
    @progress_index = progress_index
    @fail_num = 0

    if Dir[@path].size > 0
      @@skip_num += 1
      puts "Skip #{@@skip_num}th #{@name}\n".colorize(:light_yellow)
    else
      self.get_real_url
      self.download
    end
  end

  def self.start(path, progress_num)
    files = self.get_url_files(path)
    work_q = Queue.new
    files.each do |file|
      work_q << file
    end

    begin
      workers = (0..progress_num - 1).map do |i|
        Thread.new(i) do |i|
          while file = work_q.pop(true)
            self.new_from_path(file, i)
          end
        end
      end
      workers.map(&:join)
    rescue ThreadError => e
      if e.to_s == 'queue empty'
        puts "Download complete".colorize(:green)
      else
        raise e
      end
    end
  end

  def self.get_url_files(path)
    list = []
    Find.find(path) do |file|
      list << file unless file == path
    end
    list
  end

  def self.new_from_path(path, progress_index)
    file = File.new(path, 'r')
    doc = Nokogiri::HTML(file)
    doc.css('a')[1..-1].each do |a|
      self.new(a.attribute('href').value, a.text, progress_index)
    end
  end

  def get_real_url
    begin
      page = @agent.get(@url)
      @real_url = 'http://f.wanfangdata.com.cn/' + page.search('#doDownload').attribute('href').value
    rescue => e
      puts e
      @fail_num += 1
      sleep(10)
      if @fail_num < 3
        self.get_real_url
      end
    end
  end

  def download
    begin
      uri = URI(@real_url)
      download_path = "downloading/#{@name}.pdf.uncomplete"

      Net::HTTP.start(uri.host, uri.port, open_timeout: 600) do |http|
        request = Net::HTTP::Get.new uri

        http.request request do |response|
          total = response['Content-Length'].to_i
          finish = 0
          control = 0

          File.open download_path, 'w+', binmode: true do |io|
            response.read_body do |chunk|
              io.write chunk
              finish += chunk.size
              control += 1
              if control > 80
                puts "Progress #{@progress_index + 1}\t#{@name[0..10]}\t#{(finish.to_f / total * 100).to_s[0..3]}%".colorize(:blue)
                control = 0
              end
            end
          end
          unless response.code == '200'
            raise Excepction.new('Fail')
          end
          puts "#{@name}:100%".colorize(:green)
          FileUtils.mv download_path, @path
        end
      end

    rescue => e
      puts "Download error for #{@name} #{@url}, pause for one minute.".colorize(:red)
      @fail_num += 1
      sleep 60
      if @fail_num < 3
        self.download
      end
    end
  end
end

Crawler.start('links', ARGV[0].to_i)