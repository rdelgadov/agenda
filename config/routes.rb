Rails.application.routes.draw do
  get 'persons/search', to: 'persons#search'
  get 'persons/:id/calendar', to: 'persons#calendar', as: 'person_calendar'
  get 'persons/:id/calendar/new_date', to: 'persons#new_date', as: 'person_new_date'
  get 'medics/:id/calendar', to: 'medics#calendar', as: 'medic_calendar'
  get 'kinesiologists/:id/calendar', to: 'kinesiologists#calendar', as: 'kinesiologist_calendar'

  resources :persons, :medics, :kinesiologists ,:person_dates
  root 'application#index'
end
