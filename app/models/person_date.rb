class PersonDate < ApplicationRecord
  belongs_to :person
  belongs_to :medic

  def start_time
    ntime = time.split(':')
    DateTime.now.change(year: date.year,
                        month: date.month,
                        day: date.day,
                        hour: ntime[0].to_i,
                        min: ntime[1].to_i)
  end

  def self.next_date_of_person id
    PersonDate.where(person_id: id).where("date>=?",Date.tomorrow).order(date: :asc).first
  end

  def next_date date=Date.tomorrow
    PersonDate.where(medic_id: medic_id,person_id: person_id).where("date>=?",date).order(date: :asc).first
  end

  def is_next?
    self.id == self.next_date.id
  end

  def take person_id
    b = Bucket.where(medic_id: medic_id, date: date).first
    b.take person_id
    update_attribute(:person_id, person_id)
  end

  def self.take params
    pd = self.where(medic_id: params[:medic_id], date: params[:date], time: params[:time], person_id: 1).first
    pd.take params[:person_id] if pd
  end

  def untake
    b = Bucket.where(medic_id: medic_id, date: date).first
    if b
      if PersonDate.where(medic_id: medic_id, date: date, person_id: person_id).count == 1
        b.untake person_id
      end
    end
    update_attribute :person_id, 1
  end

  def taked?
    return true unless person.id == 1
    false
  end

  def to_csv
    [self.medic_id, Person.find(person_id).bp, self.date.strftime("%F"), self.time]
  end

  def color
    medic.color
  end
end
