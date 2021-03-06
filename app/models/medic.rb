class Medic < ApplicationRecord
  serialize :attention, JSON
  has_many :buckets, dependent: :destroy

  def available_dates person, date = Date.tomorrow
    return PersonDate.where(medic_id: id, person_id: 1, date: date).all if Bucket.available_for?(person, id, date)
    []
  end

  def month_available_dates date = Date.tomorrow
    available = []
    Array(date..date.end_of_month + 3.month).each do |d|
      available << d if Bucket.where(medic_id: id, date: d).where("capacity > 0").count > 0
    end
    available
  end

  def patients_for_today
    dates = []
    PersonDate.where(medic_id: id, date: Date.current).where.not(person_id: 1).sort_by { |d| d.time.to_time }.each do |pd|
      next_date = pd.next_dates.first
      dates << [pd, next_date]
      if !pd.next_dates.second.blank? and next_date.date == pd.next_dates.second.date
        dates << [pd, pd.next_dates.second]
      end
    end
    dates
  end

  def next_dates_for_my_patients date = Date.current
    dates = []
    PersonDate.where(medic_id: id, date: date).where.not(person_id: 1).each do |pd|
      unless pd.next_date(date + 1.day).blank?
        dates << pd.next_date(date + 1.day)
      end
    end
    dates.uniq.sort_by { |d| [d.date, d.time.to_time] }
  end

  def create_dates date = Date.current
    week = date.at_beginning_of_week
    attention.each do |attention|
      attention[1].each do |d|
        d = d.to_i
        day = week + d.day
        b = Bucket.where(medic_id: self.id, date: day).first_or_create!
        time = attention[0]
        pd = PersonDate.where(date: day, time: time, medic_id: self.id).first_or_create! do |personal|
          personal.person_id = 1
          b.update_attribute :capacity, b.capacity + 1
        end
      end
    end
  end

  def to_csv
    [self.id, self.name, self.type.blank? ? 'Atencion Primaria' : 'Kinesiologia']
  end
end
