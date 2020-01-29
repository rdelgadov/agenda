class PersonDate < ApplicationRecord
  belongs_to :person
  belongs_to :medic

  def start_time
    DateTime.new(date.year, date.month, date.day, time.hour, time.min, time.sec, time.zone)
  end

  def color
    medic.color
  end
end
