Rails.application.routes.draw do
  resources :nested_items
  resources :comments
  resources :problems
  resources :tasks
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
