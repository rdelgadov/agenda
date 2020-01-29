require 'csv'
namespace :read_algorithm_data do
  desc "Read a output of algorithm"
  task load_data: :environment do
    table = CSV.parse(File.read(Rails.root.join("lib/tasks/Patients.csv")), headers: true)
    table.by_row!.each do |row|
      person = Person.find_by_bp(row["ident"])
      if !person
        transportation = false
        transportation = true if row["transportation_type"] != 'no-transportation'
        person = Person.new(bp: row["ident"], rut: row["ident"], transportation: transportation, latitude: row["lat"], longitude: row["lon"], vehicle_type: 1, rest: row["medical_rest"])
        person.save!
      end
      pd = PersonDate.new(date: row["date"].to_date, time: "00:00:00".to_time, medic_id: row["doctor_id"], person_id: person.id)
      pd.save!
    end
  end
  end

