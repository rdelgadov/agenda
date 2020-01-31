class PersonDate < ApplicationRecord
  belongs_to :person
  belongs_to :medic

  def start_time
    print(self.time)
    ntime = time.split(':')
    DateTime.now.change(year: date.year,
                        month: date.month,
                        day: date.day,
                        hour: ntime[0].to_i,
                        min: ntime[1].to_i)
  end

  def taked
    return true if person.id == 1
    false
  end

  def color
    return medic.color unless taked
    'gray'
  end
end
