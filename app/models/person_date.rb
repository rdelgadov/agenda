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

  def self.take params
    pd = self.where(medic_id: params[:medic_id], date: params[:date], time: params[:time], person_id: 1).first
    pd.update_attribute(:person_id, params[:person_id])
  end

  def taked?
    return true unless person.id == 1
    false
  end

  def color
    medic.color
  end
end
