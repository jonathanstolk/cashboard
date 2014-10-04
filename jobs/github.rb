require 'octokit'
require 'action_view'
include ActionView::Helpers::DateHelper

Octokit.configure do |c|
  c.auto_paginate = true
  c.access_token = ENV['GITHUB_ACCESS_TOKEN']
end

repos = {
  'SafetyAppsServer' => 'changer/safetyapps-server',
  'SafetyAppsClient' => 'changer/safetyapps-client',
  'SocialSchools' => 'changer/cp'
}

class MyGithub
  def initialize(widget_id, repo_name)
    @widget_id = widget_id
    @repo_name = repo_name
  end

  def widget_id()
    @widget_id
  end

  def repo_name()
    @repo_name
  end

  def status_list()
    status = Array.new
    repo = Octokit::Client.new.repository(@repo_name)
    pulls = Octokit.pulls(@repo_name, :state => 'open').count
    stats = Octokit::contributors_stats(@repo_name).sort! { |a,b| b.weeks[-1].c <=> a.weeks[-1].c }
    stats.each do |stat|
      if (stat.weeks[-1].c > 0)
        status.push({label: stat.author.login, value: "#{stat.weeks[-1].c} commits"})
      end
    end
    status.push({label: 'pulls', value: pulls})
    status.push({label: 'issues', value: repo.open_issues_count - pulls})
    status
  end
end

@MyGithub = []
repos.each do |widget_id, repo_name|
  begin
    @MyGithub.push(MyGithub.new(widget_id, repo_name))
  rescue Exception => e
    puts e.to_s
  end
end

SCHEDULER.every '5m', :first_in => 0 do |job|
  @MyGithub.each do |repo|
    status = repo.status_list()
    send_event(repo.widget_id, { :items => status })
  end
end

