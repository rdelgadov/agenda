Rails.application.routes.draw do
  get 'persons/search', to: 'persons#search'
  post 'people/create', to: 'persons#create', as: 'people'
  get 'persons/:id/calendar', to: 'persons#calendar', as: 'person_calendar'
  get 'persons/:id/calendar/new_date', to: 'persons#new_date', as: 'person_new_date'
  get 'medics/:id/calendar', to: 'medics#calendar', as: 'medic_calendar'
  get 'kinesiologists/:id/calendar', to: 'kinesiologists#calendar', as: 'kinesiologist_calendar'
  get 'person_dates/create_medics_dates', to: 'person_dates#create_medics_dates'
  get 'person_dates/create_kine_dates', to: 'person_dates#create_kinesiologist_dates'
  get 'persons/:id/calendar/available_dates', to: 'person_dates#available_dates', as: 'available_dates'
  get 'create_attention_capacity', to: 'application#create_attention_capacity'
  get 'create_patients', to: 'application#create_patients'
  get 'month_avalaible_dates', to: 'application#month_avalaible_dates'
  get 'load_calendar_from_file', to: 'application#load_calendar_from_file'
  get 'run_heuristic', to: 'application#run_heuristic'
  resources :persons, :medics, :kinesiologists ,:person_dates
  root 'application#index'
end
