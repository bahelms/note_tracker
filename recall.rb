require 'sinatra'
require 'data_mapper'

# Creates a sqlite db at this path
DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/recall.db")

# This class sets up a DB schema
class Note   # Creates a 'Notes' table; Convention is to pluralize it (rails/ORM)
  include DataMapper::Resource
  # Properties are table fields; name, data type, args
  property :id, Serial   # Serial is an int primary key, auto updated
  property :content, Text, required: true
  property :complete, Boolean, required: true, default: false
  property :created_at, DateTime
  property :updated_at, DateTime  
end

# Automatically update DB when changes are made
DataMapper.finalize.auto_upgrade!

get '/' do
  @notes = Note.all :order => :id.desc   # DataMapper gets all Notes from db
  @title = 'All notes'
  erb :home   # Runs layout.erb through the ERB parser and yields to home.erb
  # I guess this parses layout.erb automatically thru Sinatra magic
end

post '/' do
  n = Note.new   # New object which includes DataMapper code
  n.content = params[:content]   #params[:content] is set to textarea value (textarea name=content)
  n.created_at = Time.now
  n.updated_at = Time.now
  n.save
  redirect '/'   # takes the browser back to this link; '/' being homepage
end

get '/:id' do   # URL parameter; sinatra puts this in params[]
  @note = Note.get params[:id].to_i   # .get method is DataMapper at work
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