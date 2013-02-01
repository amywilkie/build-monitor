require 'open-uri'
require 'nokogiri'
require 'sinatra'
require 'pry'
require 'haml'

class BuildScraper < Sinatra::Base

  TEAMCITY_BUILD_LIST = "http://10.65.95.78:8111/overview.html"
  TEAMCITY_USERNAME = 'helpcentre'
  TEAMCITY_PASSWORD = 'helpcentre'

  def teamcity_projects_info

    projects_hash = {}
    builds = Nokogiri::HTML(open(TEAMCITY_BUILD_LIST, http_basic_authentication: [TEAMCITY_USERNAME, TEAMCITY_PASSWORD]))

    builds.css('td.projectName').each do |build|
      projects_hash[build.at_css('a').text] = build.at_css('img')['src'].include?('Success')
    end

    return projects_hash
  end

  get '/' do
    @projects_info = teamcity_projects_info
    @horizontal_items = Math.sqrt(@projects_info.length).floor
    @vertical_items = (Float(@projects_info.length) / @horizontal_items).ceil
    haml :"status_monitor"
  end
end
