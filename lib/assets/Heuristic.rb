require 'open3'
module Heuristic
  def self.load_calendar
    table = CSV.parse(File.read(Rails.root.join("lib/heuristic/input/output.csv")), {headers: true, col_sep: ','})
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
          print("La cita para el dia #{row['date']} y la hora #{time} con el doctor #{row["doctor_id"]} no existe.")
        else
          pd.update_attribute(:person_id, person.id)
        end
    end
  end

  def self.create_attention_capacity date=Date.tomorrow
    week = date.at_beginning_of_week
    attributes = %w[ident attention_type date t_start	capacity]
    CSV.open(Rails.root.join("lib/heuristic/input/attention_capacity.csv"),'wb',headers: true) do |csv|
      csv << attributes
      Medic.all.each do |medic|
        attention = "Primaria"
        attention = "Kinesiologia" unless medic.type==nil
        medic.attention.each do |date|
          date[1].each do |day|
            occupied = '1'
            occupied = '0' if PersonDate.where(medic_id: medic.id, date: (week+(day.to_i).day).to_s, time:date[0], person_id: 1).blank?
            csv << [medic.id, attention, (week+(day.to_i).day).to_s, date[0], occupied]
          end
        end
      end
    end
  end

  def self.create_patients date=Date.tomorrow
    attributes = %w[ident date attention_type transportation_type lat lon companion pickup_time attention_time doctor_id vehicle_type medical_rest required_attention_time reference_attention_time reference_pickup_time CREADO_EL]
    CSV.open(Rails.root.join("lib/heuristic/input/patients.csv"),'wb',headers: true) do |csv|
      csv << attributes
      Person.all.each do |person|
        tp = 'no-transportation'
        tp = 'pick_up-and-delivery' if person.transportation
        vt = ''
        vt = '5633' if person.vehicle_type == 0
        vt = '5632' if person.vehicle_type == 1
        person.buckets.where('date > ?',Date.tomorrow).each do |b|
          if b.date >= date
            pd = PersonDate.where(person_id: person.id, date: date, medic_id: b.medic_id).last
            medic = 'Kinesiologia'
            medic = 'Primaria' if b.medic.type.blank?
            csv << [person.bp, b.date,medic,tp,person.latitude,person.longitude,(person.accompanied? ? 1:0),'','',b.medic_id, vt, (!person.rest.blank? ? 1:0), (pd.blank? ? '':pd.time), (pd.blank? ? '':pd.time), '', b.updated_at.to_date.to_s]
          end
        end
      end
    end
  end

  def self.run_heuristic date=Date.tomorrow
    create_attention_capacity date.to_date
    create_patients date.to_date
    cmd = "python3 #{Rails.root.join("lib/heuristic/main.py")} #{Rails.root.join("lib/heuristic/input")} #{date}"
    error = nil
    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_th|
      error = stderr.read
      if error.blank?
        FileUtils.cp(Dir.glob(Rails.root.join("lib/heuristic/input/output_schedule*.csv")).max_by {|f| File.mtime(f)}, Rails.root.join("lib/heuristic/input/output.csv"))
        Dir.glob(Rails.root.join("lib/heuristic/input/output_schedule*.csv")).max_by {|f| File.delete(f)}
        Dir.glob(Rails.root.join("lib/heuristic/input/output_windows*.csv")).max_by {|f| File.delete(f)}
        load_calendar
      else
        print error
      end
    end
    error
  end

end
