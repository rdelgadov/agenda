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
      if !person
        transportation = row['IND_TRANSPORTE']=='SI' ? true : false
        latitude = row['LATITUD']
        longitude = row['LONGITUD']
        address = row['DIRECCION']
        number = row['NUMERO']
        town = row['COMUNA']
        person = Person.new(bp:bp, transportation: transportation, latitude: latitude, longitude: longitude, rest: true, town: town, address: address, address_number: number)
        person.save!
      end
      date = row['FECHA_CITA']
      time = row['HORA_CITA']
      unless time
        next
      end
      time = time[1..-1] if time[0]=='0'
      begin
        params = { medic_id: medic_id.to_i, person_id: person.id.to_i, date: date, time: time}
        PersonDate.take params
      rescue StandardError => e
        print e.message
        print "No se pudo cargar la fecha #{date} a la hora #{time} con el profesional #{medic_id} linea #{i.to_s}\n"
      end
      i+=1
    end
  end
end

