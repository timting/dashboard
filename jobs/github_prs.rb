require 'octokit'

SCHEDULER.every '1m', :first_in => 0 do |job|
  Octokit.auto_paginate = true
  client = Octokit::Client.new(:access_token => ENV['GH_ACCESS_TOKEN'])
  my_organization = "ElasticSuite"
  repos = client.organization_repositories(my_organization).map { |repo| repo.name }.select {|name| /spice/ =~ name || name == "skillet" }

  open_pull_requests = repos.inject({}) { |pulls, repo|
    client.pull_requests("#{my_organization}/#{repo}", :state => 'open').each do |pull|
      pulls[repo] ||= []
      pulls[repo] << {
        title: pull.title,
        repo: repo,
        updated_at: pull.updated_at.strftime("%b %-d %Y, %l:%m %p"),
        creator: "@" + pull.user.login,
        html_url: pull.html_url
      }
    end
    pulls
  }

  repos.each do |repo|
    send_event(repo, { pulls: open_pull_requests[repo] })
  end
end
