require 'sinatra'
require 'data_mapper'
require 'sinatra/flash'

enable :sessions
set :session_secret, 'eat a Banana skunk!'

SITE_TITLE = "Note Tracker"   
SITE_DESCRIPTION = "'cause jimbonk told you so"

DataMapper::setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/recall.db")

class Note   
  include DataMapper::Resource   
  
  property :id, Serial   
  property :content, Text, required: true
  property :complete, Boolean, required: true, default: false
  property :created_at, DateTime
  property :updated_at, DateTime  
end

DataMapper.finalize.auto_upgrade!

helpers do
  include Rack::Utils   
  alias_method :h, :escape_html  
end

get '/' do
  @notes = Note.all :order => :id.desc  
  @title = 'All notes'
  erb :home  
end

post '/' do
  n = Note.new  
  n.content = params[:content]  
  n.created_at = Time.now
  n.updated_at = Time.now
  n.save
  redirect '/'
end

get '/rss.xml' do   
  @notes = Note.all :order => :id.desc
  builder :rss  
end

get '/:id' do   
  @note = Note.get params[:id].to_i  
  @title = "Edit note ##{params[:id]}"
  erb :edit
end

put '/:id' do   
  n = Note.get params[:id].to_i
  n.content = params[:content]
  n.complete = params[:complete] ? 1 : 0
  n.updated_at = Time.now
  n.save
  redirect '/' 
end

delete '/:id' do
  n = Note.get params[:id].to_i
  n.destroy   
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