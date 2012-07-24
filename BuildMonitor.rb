require 'open-uri'
require 'nokogiri'
require 'sinatra'
require 'haml'

class BuildMonitor < Sinatra::Base

  TEAMCITY_BUILDTYPE_LIST = "http://10.65.95.133:8111/httpAuth/app/rest/buildTypes/"
  TEAMCITY_BUILD_LIST = "http://10.65.95.133:8111/httpAuth/app/rest/builds/"
  TEAMCITY_USERNAME = 'helpcentre'
  TEAMCITY_PASSWORD = 'helpcentre'

  #HUDSON_projects_hash = "http://hudson-helpcentre.ocp.bskyb.com:9080/api/xml"
  HUDSON_projects_hash = "http://hudson-helpcentre.ocp.bskyb.com:9080/monitor/?"
  HUDSON_PREFIX = "http://hudson-helpcentre.ocp.bskyb.com:9080"

  def teamcity_projects_info

    projects_hash = {}
    buildtypes = Nokogiri::XML(open(TEAMCITY_BUILDTYPE_LIST, http_basic_authentication: [TEAMCITY_USERNAME, TEAMCITY_PASSWORD]))
    builds = Nokogiri::XML(open(TEAMCITY_BUILD_LIST, http_basic_authentication: [TEAMCITY_USERNAME, TEAMCITY_PASSWORD]))

    buildtypes.xpath('//buildType').each do |buildtype|

      id= buildtype.xpath('@id')
      project_name = buildtype.xpath('@projectName').text
      related_build = builds.xpath("//build[@buildTypeId='#{id}']").first
      if !related_build.nil?
        projects_hash[project_name.to_sym] ||= {url: buildtype.xpath('@webUrl').text}
        successful_so_far = projects_hash[project_name.to_sym][:successful].nil?? true : projects_hash[project_name.to_sym][:successful]
        successful = related_build.xpath('@status').text=='SUCCESS'
        projects_hash[project_name.to_sym][:successful] = successful & successful_so_far
      end

    end

    return projects_hash

  end

  def hudson_projects_info
    projects_hash = {}
    projects = Nokogiri::XML(open(HUDSON_projects_hash))
    projects.xpath("//div[@id='job_2'] | //div[@id='job_1']").each do |project|
      successful = project.xpath('@class').text == "SUCCESS"
      project_name = project.xpath("div/div/span/a").text
      url = HUDSON_PREFIX + project.xpath("div/div/span/a/@href").text
      projects_hash[project_name.to_sym] = {url: url, successful: successful}
    end
    return projects_hash
  end

  def projects_info
    teamcity_projects_info.merge hudson_projects_info
  end

  get '/status-monitor' do
    @projects_info = projects_info
    @horizontal_items = Math.sqrt(@projects_info.length).floor
    @vertical_items = (Float(@projects_info.length) / @horizontal_items).ceil
    haml :"status_monitor"
  end

end
