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
end

