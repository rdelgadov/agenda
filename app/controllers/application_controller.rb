require 'csv'
require 'assets/Heuristic'

class ApplicationController < ActionController::Base
  def index
    render 'layouts/search'
  end

  def show_error_charging_date
    i = 0
    file = File.open(Rails.root.join('lib/tasks/reporte.txt'), 'w')
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
      time = time[1..-1] if time[0] == '0'
      if PersonDate.where(medic_id: medic_id.to_i, person_id: person.id, date: date, time: time).blank?
        file.puts "No se pudo cargar al paciente #{person.bp} fecha #{date} a la hora #{time} con el profesional #{medic_id} linea #{i.to_s}\n"
      end
      i += 1
    end
    file.close
    send_file Rails.root.join('lib/tasks/reporte.txt')
  end

  def month_avalaible_dates
    render template: 'layouts/template_mini_calendar', locals:
        {medic: Medic.find(params[:medic_id]),
         dates: params.has_key?(:person_id) ? Person.find(params[:person_id]).buckets.where(medic_id: params[:medic_id]).map(&:date) : [],
         id: params['calendar'],
         events: params['events'],
         edit: params[:edit]
        }, layout: false
  end

  def get_result_of_heuristic
    send_data Result.last.description, filename: 'resultados.txt'
  end

  def load_windwos_from_file
    Heuristic.load_pickuptime
    redirect_to person_dates_path
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
    from = params[:from].blank? ? Date.tomorrow : params[:from].to_date
    to = params[:to].blank? ? Date.new(2020,03,10) : params[:to].to_date
    ApplicationJob.delay.run_heuristic(from, to)
    flash[:info] = 'La Heuristica se esta ejecutando.'
    redirect_to person_dates_path
  end

  def dump_db
    if params.has_key? :patients
      patients = CSV.generate do |csv|
        csv << %w[id bp name first_name second_name phone rest trasnportation latitude longitude vehicle_type comuna address address_number travels_type medic kine comment reference_attention_time reference_pickup_time employ emergency_type accompanied]
        Person.all[1..-1].each do |p|
          csv << p.to_csv
        end
      end
      send_data patients, filename: 'patients.csv'

    elsif params.has_key? :dates
      dates = CSV.generate do |csv|
        csv << %w[medic_id person_bp date time]
        PersonDate.where.not(person_id: 1).each do |pd|
          csv << pd.to_csv
        end
      end
      send_data dates, filename: 'dates.csv'

    elsif params.has_key? :medics
      medics = CSV.generate do |csv|
        csv << %w[medic_id name type]
        Medic.all.each do |m|
          csv << m.to_csv
        end
      end
      send_data medics, filename: 'medics.csv'

    elsif params.has_key? :sacos
      buckets = CSV.generate do |csv|
        csv << %w[date person_bp medic_id]
        Bucket.all.each do |b|
          b.people.each do |p|
            csv << b.to_csv(p)
          end
        end
      end
      send_data buckets, filename: 'sacos.csv'
    end
  end

  def generate_262
    csv_file = Heuristic.generate_262 params[:date].to_date
    send_data csv_file, filename: '262.csv'
  end

end
