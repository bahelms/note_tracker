require 'sinatra'
require 'data_mapper'
require 'sinatra/flash'

enable :sessions
set :session_secret, 'eat a Banana skunk!'

SITE_TITLE = "Note Tracker"   # Sinatra global constants
SITE_DESCRIPTION = "'cause jimbonk told you so"

# Creates a environment dependent OR sqlite3 db at this path
DataMapper::setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/recall.db")

# This class sets up a DB schema
class Note   # Creates a 'Notes' table; Convention is to pluralize it (rails/ORM)
  include DataMapper::Resource   # This adds all the DM functionality to Note objects
  # Properties are table fields; name, data type, args
  property :id, Serial   # Serial is an int primary key, auto updated
  property :content, Text, required: true
  property :complete, Boolean, required: true, default: false
  property :created_at, DateTime
  property :updated_at, DateTime  
end

# Automatically update DB when changes are made
DataMapper.finalize.auto_upgrade!

helpers do
  include Rack::Utils   # Gives access to html escaping method (prevents XSS)
  alias_method :h, :escape_html   # Makes :h a copy of :escape_html
end

get '/' do
  @notes = Note.all :order => :id.desc   # DataMapper gets all Notes from db
  @title = 'All notes'
  if @notes.empty? 
    flash.now[:error] = "No notes found. Add your first below."
  end
  erb :home   # Runs layout.erb through the ERB parser and yields to home.erb
end

post '/' do
  n = Note.new   # New object which includes DataMapper code
  n.content = params[:content]   #params[:content] is set to textarea value (textarea name=content)
  n.created_at = Time.now
  n.updated_at = Time.now
  if n.save 
    redirect '/', notice: "Note created successfully."
  else 
    redirect '/', :error => "Failed to save note." 
  end
end

get '/rss.xml' do   # RSS feed
  @notes = Note.all :order => :id.desc
  builder :rss   # Process .builder file like erb
end

get '/:id' do   # URL parameter; sinatra puts this in params[]
  @note = Note.get params[:id].to_i   # .get method is DataMapper at work
  @title = "Edit note ##{params[:id]}"
  if @note then erb :edit
  else redirect '/', flash.now[:error] = "Can't find that note!" end
end

put '/:id' do   
  n = Note.get params[:id].to_i
  n.content = params[:content]
  n.complete = params[:complete] ? 1 : 0
  n.updated_at = Time.now
  n.save
  redirect '/'  # takes the browser back to this link; '/' being homepage
end

delete '/:id' do
  n = Note.get params[:id].to_i
  n.destroy   # DataMapper at work
  redirect '/'
end

get '/:id/delete' do
  @note = Note.get params[:id].to_i
  @title = "Confirm deletion of note ##{params[:id]}"
  erb :delete
end

get '/:id/complete' do
  n = Note.get params[:id].to_i
  n.complete = n.complete ? 0 : 1
  n.updated_at = Time.now
  n.save
  redirect '/'
end