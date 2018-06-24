
class SessionPersistence

  def initialize(session)
    @session = session
    @session[:lists] ||= []
  end
  
  def find_list(id)
    @session[:lists].find { |l| l[:id] == id }
  end
  
  def all_lists
    @session[:lists]
  end
  
  def add_list(list_name)
    id = next_element_id(@session[:lists])
    @session[:lists] << {id: id, name: list_name, todos: []}
  end
  
  def delete_list(list_id)
    @session[:lists].reject! { |list| list[:id] == list_id }
  end
  
  def update_list_name(list_id, new_name)
    list = find_list(list_id)
    list[:name] = new_name
  end
  
  def add_todo_to_list(list_id, todo_name)
    list = find_list(list_id)
    id = next_element_id(list[:todos])
    list[:todos] << {id: id, name: todo_name, completed: false}
  end
  
  def delete_todo_from_list(list_id, todo_id)
    list = find_list(list_id)
    list[:todos].reject! { |todo| todo[:id] == todo_id}
  end
  
  def update_todo(list_id, todo_id, new_status)
    list = find_list(list_id)
    todo_to_update = list[:todos].find { |todo| todo[:id] == todo_id }
    todo_to_update[:completed] = new_status
  end
  
  def complete_all_todos(list_id)
    list = find_list(list_id)
    list[:todos].each { |todo| todo[:completed] = true }
  end
  
  private
  
  def next_element_id(element)
    max = element.map { |element| element[:id] }.max || 0
    max + 1
  end
end
