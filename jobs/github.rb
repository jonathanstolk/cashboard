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
    status.push({label: 'issues', value: repo.open_issues_count - pulls})
    status.push({label: 'pulls', value: pulls})
    status.push({label: 'forks', value: repo.forks})
    status.push({label: 'activity', value: time_ago_in_words(repo.updated_at).capitalize})
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

