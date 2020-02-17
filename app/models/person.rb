class Person < ApplicationRecord
  has_and_belongs_to_many :buckets

  def medic_dates medic
    PersonDate.where(person_id: 1,medic_id: medic).where(date: Date.today..30.days.from_now).all
  end

  def take_buckets person_params
    unless person_params[:dates].blank?
      person_params[:dates].each do |date|
        b = Bucket.where(medic_id: person_params[:kine],date: date).first
        b.take self.id
      end
    end
    unless person_params[:ap_dates].blank?
      person_params[:ap_dates].each do |date|
        b = Bucket.where(medic_id: person_params[:medic],date: date).first
        b.take self.id
      end
    end
  end

  def next_date
    PersonDate.next_date_of_person id
  end
end
