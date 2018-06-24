require "sinatra"
require "sinatra/content_for"
require "tilt/erubis"

require_relative "database_persistence"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

configure(:development) do
  require "sinatra/reloader"
  also_reload "database_persistence.rb"
end

before do
  @storage = DatabasePersistence.new(logger)
end

after do
  @storage.disconnect
end

helpers do
  def list_complete?(list)
    todos_count(list) > 0 && 
    todos_remaining_count(list).zero?
  end
  
  def list_class(list)
    "complete" if list_complete?(list)
  end
  
  def todos_remaining_count(list)
    list[:todos].reject { |todo| todo[:completed] }.size
  end
  
  def todos_count(list)
    list[:todos].size
  end
  
  def sort_lists(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| list_complete?(list)}
  
    incomplete_lists.each(&block)
    complete_lists.each(&block)
  end
  
  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    incomplete_todos.each(&block)
    complete_todos.each(&block)
  end
  
  def load_list(id)
    list = @storage.find_list(id)
    return list if list
  
    session[:error] = "The specified list was not found"
    redirect "/lists"
  end
end

get "/" do
  redirect "/lists"
end

# View list of lists
get "/lists" do
  @lists = @storage.all_lists
  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# Return an error message if the name is Invalid. Return nil if name is valid.

def error_for_list_name(name)
  if !(1..100).cover? name.size
    "List name must be between 1 and 100 characters."
  elsif @storage.all_lists.any? { |list| list[:name] == name }
    "List name must be unique."
  end
end

# Create a new list
post "/lists" do
  list_name = params[:list_name]

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    @storage.add_list(list_name)
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

# View list
get "/lists/:id" do
  id = params[:id].to_i
  @list = load_list(id)
  @list_id = @list[:id]
  erb :list, layout: :layout
end


# Edit an existing todo list
get "/lists/:id/edit" do
  list_id = params[:id].to_i
  @list = load_list(list_id)
  erb :edit_list, layout: :layout
end

# Update an existing todo list
post "/lists/:id" do
  list_name = params[:list_name].strip
  list_id = params[:id].to_i

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @storage.update_list_name(list_id, list_name)
    session[:success] = "The list has been updated."
    redirect "/lists/#{list_id}"
  end
end

# Delete a todo list
post "/lists/:id/delete" do
  list_id = params[:id].to_i
  @storage.delete_list(list_id)

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:success] = "The list has been deleted."
    redirect "/lists"
  end
end

def error_for_todo_name(name)
  error_message = "Todo name must be between 1 and 100 characters."
  return error_message unless (1..100).cover? name.size
  nil
end

# Add a new todo to the list
post "/lists/:list_id/todos" do
  text = params[:todo].strip
  @list_id = params[:list_id].to_i

  error = error_for_todo_name(text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @storage.add_todo_to_list(@list_id, text)
    session[:success] = "A new todo has been added to your list."
    redirect "/lists/#{@list_id}"
  end
end

# Delete a todo from a list
post "/lists/:list_id/todos/:todo_id/delete" do
  @list_id = params[:list_id].to_i
  
  todo_id = params[:todo_id].to_i
  @storage.delete_todo_from_list(@list_id, todo_id)
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = "The todo has been deleted."
    redirect "/lists/#{@list_id}"
  end
end

# Update the status of a todo
post "/lists/:list_id/todos/:todo_id" do
  @list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  is_completed = params[:completed] == "true"

  @storage.update_todo(@list_id, todo_id, is_completed)

  session[:success] = "The todo has been updated."
  redirect "/lists/#{@list_id}"
end

# Mark all todos as complete for a list
post "/lists/:list_id/complete_all" do
  @list_id = params[:list_id].to_i
  
  @storage.complete_all_todos(@list_id)
  
  session[:success] = "All todos have been completed."
  redirect "/lists/#{@list_id}"
end