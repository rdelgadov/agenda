require 'csv'
require 'assets/Heuristic'

class ApplicationController < ActionController::Base
  def index
    render 'layouts/search'
  end

  def month_avalaible_dates
    render template:'layouts/template_mini_calendar', locals:
        {medic: Medic.find(params[:medic_id]),
         dates:[],
         id:params['calendar'],
         events: params['events'],
         edit: params[:edit]
    },layout: false
  end

  def load_calendar_from_file
    Heuristic.load_calendar
    redirect_to person_dates_path
  end

  def create_attention_capacity
    Heuristic.create_attention_capacity params[:date].to_date
    redirect_to person_dates_path
  end

  def create_patients
    Heuristic.create_patients params[:date].to_date
    redirect_to person_dates_path
  end

  def run_heuristic
    date = params[:date].blank? ? Date.tomorrow : params[:date]
    output_err = (Heuristic.run_heuristic date)
    if !output_err.blank?
      flash[:danger] = "La Ejecucion de la heuristica tuvo los problemas: #{output_err}"
    else
      flash[:info] = 'La Ejecucion de la heuristica fue correcta.'
    end
    redirect_to person_dates_path
  end
end
