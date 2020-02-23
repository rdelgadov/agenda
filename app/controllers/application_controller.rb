require 'csv'
require 'assets/Heuristic'

class ApplicationController < ActionController::Base
  def index
    render 'layouts/search'
  end

  def show_error_charging_date
    i=0
    file = File.open(Rails.root.join('lib/tasks/reporte.txt'),'w')
    table = CSV.parse(File.read(Rails.root.join("lib/tasks/san_miguel.csv")), {headers: true, col_sep: ','})
    table.by_row!.each do |row|
      bp = row['BP_PACIENTE']
      person = Person.find_by_bp(bp)
      medic_id = row['NOMBRE_RESP_CITACION']
      begin
        medic_id = medic_id.to_i
      rescue StandardError
        print i
        next
      end
      date = row['FECHA_CITA']
      time = row['HORA_CITA']
      unless time
        next
      end
      time = time[1..-1] if time[0]=='0'
      if PersonDate.where(medic_id: medic_id.to_i, person_id: person.id, date: date, time: time).blank?
        file.puts "No se pudo cargar al paciente #{person.bp} fecha #{date} a la hora #{time} con el profesional #{medic_id} linea #{i.to_s}\n"
      end
      i+=1
    end
    file.close
    send_file Rails.root.join('lib/tasks/reporte.txt')
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

  def generate_262
    csv_file = Heuristic.generate_262 params[:date]
    send_data csv_file
  end
end
