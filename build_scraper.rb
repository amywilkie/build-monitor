require 'open-uri'
require 'nokogiri'
require 'sinatra'
require 'haml'

class BuildScraper < Sinatra::Base
  TEAMCITY_BUILD_LIST = "http://teamcity:8111/overview.html"
  TEAMCITY_USERNAME   = ENV['TEAMCITY_USER']
  TEAMCITY_PASSWORD   = ENV['TEAMCITY_PASS']

  def builds
    Nokogiri::HTML(open(TEAMCITY_BUILD_LIST, http_basic_authentication: [TEAMCITY_USERNAME, TEAMCITY_PASSWORD]))
  end

  def teamcity_projects_info
    builds.css('td.projectName').each_with_object({}) { |build, projects_hash|
      projects_hash[build.at_css('a').text] = build.at_css('img')['src'].include?('Success')
    }
  end

  def style
    "width: #{Float(89) / @horizontal_items}%;\
     margin-left: #{Float(3) / @horizontal_items}%;\
     margin-right: #{Float(3) / @horizontal_items}%;\
     height: #{Float(89) / @vertical_items}%;\
     margin-top: #{Float(3) / @vertical_items}%;\
     margin-bottom: #{Float(3) / @vertical_items}%"
  end

  get '/' do
    begin
      @projects_info    = teamcity_projects_info.reject { |k| k.include? 'Helpproxy' }
      @horizontal_items = Math.sqrt(@projects_info.length).floor
      @vertical_items   = (Float(@projects_info.length) / @horizontal_items).ceil
      haml :"status_monitor"
    rescue Exception => e
      puts "project info: #{@projects_info} - horizontal items: #{@horizontal_items} - vertical items: #{@vertical_items}"
      puts e.message
      halt 500
    end
  end
end
