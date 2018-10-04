Rails.application.routes.draw do
  resources :problems do
    resources :comments
  end
  resources :tasks do
    resources :nested_items
    resources :problems do
      resources :comments
    end
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
