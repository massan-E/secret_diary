Rails.application.routes.draw do
  resources :diaries
  resources :users, only: %i[new create]
  resource :session, only: %i[new create destroy]
  resources :passwords, param: :token, only: %i[new create edit update]
  root "diaries#index"

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end
