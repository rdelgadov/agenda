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

  def next_date
    PersonDate.where(medic_id: medic_id,person_id: person_id).where("date>=?",Date.tomorrow).order(date: :asc).first
  end

  def is_next?
    self.id == self.next_date.id
  end

  def self.take params
    pd = self.where(medic_id: params[:medic_id], date: params[:date], time: params[:time], person_id: 1).first
    if pd
      b = Bucket.where(medic_id: params[:medic_id], date:params[:date]).first
      b.take params[:person_id]
      pd.update_attribute(:person_id, params[:person_id])
    end
  end

  def untake
    b = Bucket.where(medic_id: medic_id, date: date).first
    if b
      b.untake person_id
    end
    update_attribute :person_id, 1
  end

  def taked?
    return true unless person.id == 1
    false
  end

  def color
    medic.color
  end
end
