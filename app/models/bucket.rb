class Bucket < ApplicationRecord
  belongs_to :medic
  has_and_belongs_to_many :people

  def less_capacity
    raise StandardError if self.capacity <= 0
    update_attribute :capacity, self.capacity-1
  end

  def plus_capacity
    update_attribute :capacity, self.capacity+1
  end

  def add_person person_id
    self.people << Person.find(person_id)
  end

  def remove_person person_id
    people.delete(Person.find(person_id))
  end

  def untake person_id
    return unless people.include? Person.find(person_id)
    plus_capacity
    remove_person person_id
  end

  def take person_id
    return if people.include? Person.find(person_id)
    less_capacity
    add_person person_id
  end

  def reload_capacity
    medic = Medic.find(medic_id)
    week = self.date.at_beginning_of_week
    n_capacity = 0
    medic.attention.each do |attention|
      attention[1].each do |day|
        day = day.to_i
        day = week + day.day
        if date == day
          n_capacity += 1
        end
      end
    end
    n_capacity = n_capacity - people.count
    update_attribute :capacity, n_capacity
  end

  def self.available_for? person, medic, date
    b = Bucket.where(medic_id:medic, date:date).first
    return false if b.blank?
    b.capacity>0 or b.people.map(&:id).include? person.to_i
  end

  def to_csv person
    [self.date,person.bp, self.medic_id]
  end
end
