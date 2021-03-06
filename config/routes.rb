Rails.application.routes.draw do
  get 'persons/search', to: 'persons#search'
  post 'people/create', to: 'persons#create', as: 'people'
  get 'persons/:id/calendar', to: 'persons#calendar', as: 'person_calendar'
  get 'persons/:id/calendar/new_date', to: 'persons#new_date', as: 'person_new_date'
  get 'persons/:id/calendar/edit', to: 'persons#calendar_edit', as: 'person_calendar_edit'
  get 'medics/:id/calendar', to: 'medics#calendar', as: 'medic_calendar'
  get 'medics/:id/next_dates', to: 'medics#next_dates', as: 'medic_next_dates'
  get 'kinesiologists/:id/calendar', to: 'kinesiologists#calendar', as: 'kinesiologist_calendar'
  get 'person_dates/create_medics_dates', to: 'person_dates#create_medics_dates'
  get 'person_dates/create_kine_dates', to: 'person_dates#create_kinesiologist_dates'
  get 'persons/:id/calendar/available_dates', to: 'person_dates#available_dates', as: 'available_dates'
  get 'create_attention_capacity', to: 'application#create_attention_capacity'
  get 'create_patients', to: 'application#create_patients'
  get 'month_avalaible_dates', to: 'application#month_avalaible_dates'
  get 'load_calendar_from_file', to: 'application#load_calendar_from_file'
  get 'run_heuristic', to: 'application#run_heuristic'
  get 'person_dates/:id/untake', to: 'person_dates#untake', as:'untake_person_date'
  get 'persons/:id/untake_bucket/:bucket_id', to: 'persons#untake_bucket', as:'untake_bucket'
  get 'get_file', to: 'application#show_error_charging_date'
  get 'medics/:id/next_date_for_patients', to: 'person_dates#next_date_for_patients'
  get 'dump_db', to: 'application#dump_db'
  get '262', to: 'application#generate_262'
  get 'load_windwos_from_file', to: 'application#load_windwos_from_file'
  get 'load_calendar_from_file', to: 'application#load_calendar_from_file'
  get 'file_heuristic', to: 'application#get_result_of_heuristic'

  resources :persons, :medics, :kinesiologists ,:person_dates
  root 'application#index'
end
