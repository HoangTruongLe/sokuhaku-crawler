Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  resources :crawlers, only: [] do
    collection do
      post :homes
      post :rooms
    end
  end
end
