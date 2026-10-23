Rails.application.routes.draw do
  resources :diaries
  resources :users, only: %i[new create]
  root "diaries#index"

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end
