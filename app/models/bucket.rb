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
end
