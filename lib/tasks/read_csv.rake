require 'csv'
namespace :read_csv do
  desc "Read a csv file"
  task read_csv: :environment do
    table = CSV.parse(File.read(Rails.root.join("lib/tasks/Patients.csv")), headers: true)
    table.by_row!.each do |row|
      person = Person.find_by_bp(row["ident"])
      if !person
        transportation = false
        transportation = true if row["transportation_type"] != 'no-transportation'
        person = Person.new(bp: row["ident"], rut: row["ident"], transportation: transportation, latitude: row["lat"], longitude: row["lon"], vehicle_type: 1, rest: row["medical_rest"])
        person.save!
      end
    end
  end
  desc "Load data from output"
  task load_data: :environment do
    table = CSV.parse(File.read(Rails.root.join("lib/tasks/output.csv")), {headers: true, col_sep: ';'})
    table.by_row!.each do |row|
      time = row["t_start"]
      time = row["t_start"][1..-1] if row['t_start'][0]=='0'
      person = Person.find_by_bp(row["patient_id"])
      unless person
        person = Person.new(bp: row["patient_id"], rut: row["patient_id"])
        person.save!
      end
        pd = PersonDate.where(medic_id: row["doctor_id"], date: row["date"].to_date, time: time).first
        if !pd
          print("fecha desconocida")
        else
          pd.update_attribute(:person_id, person.id)
        end

    end
  end
  desc "Load from achs csv"
  task load_from_csv: :environment do
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
      if PersonDate.where(medic_id: medic_id.to_i, person_id: person.id.to_i, date: date, time: time).blank?
        file.puts "No se pudo cargar al paciente #{person.bp} fecha #{date} a la hora #{time} con el profesional #{medic_id} linea #{i.to_s}\n"
      end
      i+=1
    end
    file.close
  end
  desc "Load directions"
  task load_directions: :environment do
    table = CSV.parse(File.read(Rails.root.join("lib/tasks/direcciones.csv")), {headers: true, col_sep: ','})
    table.by_row!.each do |row|
      begin
        bp = row['perfil'].to_i
      rescue StandardError => e
        next
      end
      person = Person.find_by_bp(bp)
      if person
        person.update_attribute :latitude, row['latitud_perfil']
        person.update_attribute :longitude, row['longitud_perfil']
      end
    end
  end
  desc "Load 262"
  task load_262: :environment do
    table = CSV.parse(File.read(Rails.root.join("lib/tasks/262_febrero.csv")),{headers:true, col_sep:';'})
    table.by_row do |row|
      person = Person.find(row['Paciente'])
      if person
        person.update_attribute :rut, row['Nº documento'] if person.rut.blank?
        person.update_attribute :travels_type, row['Transporte'] if person.travels_type.blank?
        person.update_attribute :accompanied, row['Acompañante']==1 ? true : false
        person.update_attribute :name, row['Nombre de pila estandarizado']
        person.update_attribute :first_name, row['Apellido 1 estandarizado']
        person.update_attribute :second_name, row['Apellido 2 estandarizado']
        person.update_attribute :phone, row['Teléfono 1']
      end
    end
  end
end

