require 'sinatra'
require 'omniauth'

PUBLIC_URLS = ['/', '/logout', '/auth/github', '/auth/github/callback', '/auth/failure']

load '.settings' if File.exists? '.settings'
if ENV['GITHUB_CLIENT_ID']
  set :github_client_id, ENV['GITHUB_CLIENT_ID']
  set :github_secret, ENV['GITHUB_SECRET']
end

enable :sessions

use OmniAuth::Builder do
  provider :github, settings.github_client_id, settings.github_secret, :scope => "user,repo"
end

before do
  protected! unless PUBLIC_URLS.include? request.path_info
end

helpers do
  def user_token
    session["user_token"]
  end

  def logged_in
    !!user_token
  end

  def protected!
    redirect '/auth/github' unless logged_in 
  end
end

get '/' do
  erb <<-HTML
<!doctype html>
<html lang="en">
<body>
<% if logged_in %>
<script>
  var user = { token: '<%= user_token %>' };
</script>
  <div>Make requests to Github API via javascript with user.token.</div>
  <div><a href="/logout">Logout</a></div>
<% else %>
  <div><a href='/auth/github'>Sign in to GitHub</a></div>
<% end %>
</body></html>
  HTML
end

get '/auth/github/callback' do
  omniauth = request.env['omniauth.auth']
  session["user_token"] = omniauth['credentials']['token']
  redirect '/'

  #content_type 'text/plain'
  #request.env['omniauth.auth'].to_hash.inspect
end

get '/auth/failure' do
  content_type 'text/plain'
  "Failed to authenticate: #{params[:message]}"
end

get '/logout' do
  session["user_token"] = nil
  redirect '/'
end
