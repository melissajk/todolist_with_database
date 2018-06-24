require 'pg'

class DatabasePersistence

  def initialize(logger)
    @db = if Sinatra::Base.production?
      PG.connect(ENV['DATABASE_URL'])
    else
      PG.connect(dbname: "todos")
    end
    @logger = logger
  end
  
  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end
  
  def disconnect
    @db.close
  end

  def find_list(id)
    sql = "SELECT * FROM lists WHERE id = $1"
    result = query(sql, id)
  
    tuple = result.first
    
    list_id = tuple["id"].to_i
    todos = find_todos_for_list(list_id)
    {id: list_id, name: tuple["name"], todos: todos}
  end

  def all_lists
    sql = "SELECT * FROM lists;"
    result = query(sql)
    result.map do |tuple|
      list_id = tuple["id"].to_i
      todos = find_todos_for_list(list_id)
      {id: list_id, name: tuple["name"], todos: todos}
    end
  end
  
  def find_todos_for_list(list_id)
    todo_sql = "SELECT * FROM todos WHERE list_id = $1;"
    todo_result = query(todo_sql, list_id)
    
    todo_result.map do |todo_tuple|
      {id: todo_tuple["id"].to_i,
       name: todo_tuple["name"], 
       completed: todo_tuple["completed"] == "t"}
    end
  end
  
  def add_list(list_name)
    sql = "INSERT INTO lists (name) VALUES ($1);"
    query(sql, list_name)
  end
  
  def delete_list(list_id)
    sql = "DELETE FROM lists WHERE id = $1;"
    query(sql, list_id)
  end
  
  def update_list_name(list_id, new_name)
    sql = "UPDATE lists SET name = $1 WHERE id = $2;"
    query(sql, new_name, list_id)
  end
  
  def add_todo_to_list(list_id, todo_name)
    sql = "INSERT INTO todos (name, list_id) VALUES ($1, $2);"
    query(sql, todo_name, list_id)
  end
  
  def delete_todo_from_list(list_id, todo_id)
    sql = "DELETE FROM todos WHERE id = $1 AND list_id = $2;"
    query(sql, todo_id, list_id)
  end
  
  def update_todo(list_id, todo_id, new_status)
    sql = "UPDATE todos SET completed = $1 WHERE id = $2 AND list_id = $3;"
    query(sql, new_status, todo_id, list_id)
  end
  
  def complete_all_todos(list_id)
    sql = "UPDATE todos SET completed = true WHERE list_id = $1;"
    query(sql, list_id)
  end
  
end