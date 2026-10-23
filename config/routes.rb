Rails.application.routes.draw do
  resources :diaries
  root "diaries#index"

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end
