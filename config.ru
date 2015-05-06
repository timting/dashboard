require 'dashing'
require 'octokit'

enable :sessions
CLIENT_ID = ENV['GH_APP_CLIENT_ID']
CLIENT_SECRET = ENV['GH_APP_CLIENT_SECRET']
configure do
  set :auth_token, ENV['DASHING_AUTH_TOKEN']

  helpers do
    def authenticate!
      client = Octokit::Client.new
      url = client.authorize_url(CLIENT_ID, :scope => 'repo')
      redirect url
    end

    def protected!
      anon_client = Octokit::Client.new(:client_id => CLIENT_ID, :client_secret => CLIENT_SECRET)
      if (!session[:access_token] && !request.env['rack.request.query_hash']['code'])
        authenticate!
      else
        client = Octokit::Client.new(:client_id => CLIENT_ID, :client_secret => CLIENT_SECRET)

        begin
          client.check_application_authorization(session[:access_token])
        rescue => e
          session[:access_token] = nil
          return authenticate!
        end

        get_repos
      end
    end

    def get_repos
      Octokit.auto_paginate = true
      client = Octokit::Client.new(:access_token => session[:access_token])
      my_organization = "ElasticSuite"
      if request.path_info == '/skillet'
        params[:repos] = client.organization_repositories(my_organization).map { |repo| repo.name }.select { |name| /spice/ =~ name }
      elsif request.path_info == '/scramble'
        params[:repos] = client.organization_repositories(my_organization).map { |repo| repo.name }.select { |name| /-scramble/ =~ name || 'oakley' == name }
      end
    end
  end

  get '/auth/callback' do
    session_code = request.env['rack.request.query_hash']['code']
    result = Octokit.exchange_code_for_token(session_code, CLIENT_ID, CLIENT_SECRET)
    session[:access_token] = result[:access_token]
    redirect '/'
  end
end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

run Sinatra::Application