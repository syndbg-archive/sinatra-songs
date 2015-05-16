require 'better_errors'
require 'coffee-script'
require 'pony'
require 'sass'
require 'sinatra'
require 'sinatra/flash'
require 'slim'

current_dir = Dir.pwd
Dir["#{current_dir}/models/*.rb"].each { |file| require file }
Dir["#{current_dir}/helpers/*.rb"].each { |file| require file }

configure do
  set :views, 'views'
  enable :sessions
  set :username, 'frank'
  set :password, 'sinatra'
end

configure :development do
  use BetterErrors::Middleware
  DataMapper.setup(:default, "sqlite3://#{current_dir}/development.db")
  BetterErrors.application_root = current_dir
end

configure :production do
  # DATABASE_URL is defined in Heroku containers
  DataMapper.setup(:default, ENV['DATABASE_URL'])
end

helpers do
  def css(*stylesheets)
    stylesheets.map do |stylesheet|
      "<link href=\"#{stylesheet}.css\" media=\"screen, projection\" rel=\"stylesheet\" />"
    end.join
  end

  def current?(path = '/')
    (request.path == path || request.path == path + '/') ? 'current' : nil;
  end

  def set_title
    @title ||= 'Songs by Sinatra'
  end

  def send_message
    Pony.mail(
        :from                 => params[:name] + '<' + params[:email] + '>',
        :to                   => 'syndbg',
        :subject              => params[:name] + ' has contacted you',
        :body                 => params[:message],
        :port                 => '587',
        :via                  => :smtp,
        :via_options          => {
          :address              => 'smtp.gmail.com',
          :port                 => '587',
          :enable_starttls_auto => true,
          :user_name            => 'secret',
          :password             => 'secret',
          :authentication       => :plain,
          :domain               => 'localhost.localdomain'
        }
    )
  end
end

get('/styles.css') { scss :styles }
get('/javascripts/application.js') { coffee :application }

before do
  @title = set_title
end

get '/set/:name' do
  session[:name] = params[:name]
end

get '/hello' do
  "Hello #{session[:name]}"
end

get '/' do
  slim :home
end

get '/login' do
  slim :login
end

post '/login' do
  if params[:username] == settings.username && params[:password] == settings.password
    session[:admin] = true
    redirect to('/songs')
  else
    slim :login
  end
end

get '/logout' do
  session.clear
  redirect to('/')
end

get '/about' do
  @title = 'All About This Website'
  slim :about
end

get '/contact' do
  slim :contact
end

post '/contact' do
  send_message
  flash[:notice] = 'Message sent'
  redirect to('/')
end

not_found do
  slim :not_found
end

get '/songs' do
  @songs = Song.all
  slim :songs
end

get '/songs/new' do
  protected!
  @song = Song.new
  slim :new_song
end

get '/songs/:id' do
  @song = Song.get(params[:id])
  slim :show_song
end

get '/songs/:id/edit' do
  @song = Song.get(params[:id])
  slim :edit_song
end

post '/songs' do
  protected!
  flash[:notice] = 'Song successfully added' if Song.create(params[:song])
  redirect to("/songs/#{song.id}")
end

put '/songs/:id' do
  protected!
  song = Song.get(params[:id])
  if song.update(params[:song])
    flash[:notice] = 'Song successfully updated'
  end
  redirect to("/songs/#{song.id}")
end

post '/songs/:id/like' do
  @song = Song.get(params[:id])
  @song.likes = @song.likes.next
  @song.save
  redirect to "/songs/#{@song.id}" unless request.xhr?
  slim :like, layout: false
end

delete '/songs/:id' do
  protected!
  if Song.get(params[:id]).destroy
    flash[:notice] = 'Song deleted'
  end
  redirect to('/songs')
end
