class Medic < ApplicationRecord
    serialize :attention, JSON

    def available_dates date=Date.tomorrow
        PersonDate.where(medic_id: id, person_id: 1, date: date).all
    end

    def create_dates date=Date.today
        week = date.at_beginning_of_week
        attention.each do |attention|
            attention[1].each do |d|
                d = d.to_i
                day = week + d.day
                time = attention[0]
                pd = PersonDate.where(date: day, time: time, medic_id: self.id).first_or_create! do |personal|
                    personal.person_id = 1
                end

            end
        end
    end
end
