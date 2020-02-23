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
        if person.reference_attention_time.blank?
          person.update_attribute(:reference_attention_time,time)
        end
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
            csv << [medic.id, attention, (week+(day.to_i).day).to_s, date[0], 1]
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
        tp = person.transportation ? 'pick_up-and-delivery' : 'no-transportation'
        vt = ''
        vt = '5632'
        b = person.buckets.where(date: date).first
        if b.blank?
          next
        end
        reference_attention = person.reference_attention_time
        pd = PersonDate.where(person_id: person.id, medic_id: b.medic_id).where(date: date-7.day .. date).last
        if pd.blank?
          required_attention = ''
        else
          required_attention = pd.time if pd.is_next? and date == pd.date
        end
        medic = b.medic.type.blank? ? 'Primaria' : 'Kinesiologia'
        csv << [person.bp, b.date,medic,tp,person.latitude,person.longitude,(person.accompanied? ? 1:0),'','',b.medic_id, vt, (!person.rest.blank? ? 1:0), required_attention, reference_attention, '', b.updated_at.to_date.to_s]

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
        FileUtils.cp(Dir.glob(Rails.root.join("lib/heuristic/input/output_windows*.csv")).max_by {|f| File.mtime(f)}, Rails.root.join("lib/heuristic/input/window.csv"))
        Dir.glob(Rails.root.join("lib/heuristic/input/output_schedule*.csv")).max_by {|f| File.delete(f)}
        Dir.glob(Rails.root.join("lib/heuristic/input/output_windows*.csv")).max_by {|f| File.delete(f)}
        load_calendar
      else
        print error
      end
    end
    error
  end

  def self.generate_262 date=Date.tomorrow
    csv = CSV.generate do |csv|
      csv << ['Paciente','Transporte','Descripcion Acompañante','UO que documenta','Fecha ejecución Transporte','Hora Ejecución Transporte','Descripción estado','Número Entrega','Apellido 1 estandarizado','Nombre de pila estandarizado','Desc. Sentido','Población','Calle Origen','Número Origen','Población','Calle Destino','Número Destino','Teléfono 1','Hora Entrega','Latitud','Longitud']
      PersonDate.where(date: date).where.not(person_id: 1).each do |pd|
        person = Person.find(pd.person_id)
        unless person.transportation
          next
        end
        companion = person.accompanied ? 'Si':'No'
        uo = Medic.find(pd.medic_id).type.blank? ? 'MIGTCAPR':'MIGTTF'
        csv << [person.bp,person.travels_type,companion,uo,date.strftime('%d-%m-%Y'),pd.time.to_time.strftime('%I:%M%p'),'Solicitado','',person.first_name,person.name,]
      end
    end

  end

end
