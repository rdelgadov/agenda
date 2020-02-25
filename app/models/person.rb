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
      self.buckets.each do |b|
        b.untake(self.id) unless person_params[:dates].include? b.date.to_s
      end
    end
    unless person_params[:ap_dates].blank?
      person_params[:ap_dates].each do |date|
        b = Bucket.where(medic_id: person_params[:medic],date: date).first
        b.take self.id
      end
      self.buckets.each do |b|
        b.untake(self.id) unless person_params[:ap_dates].include? b.date.to_s
      end
    end
  end

  def to_csv
    [self.bp,self.name,self.first_name,self.second_name,self.phone,self.rest,self.transportation,self.latitude,self.longitude,self.vehicle_type,self.town,self.address, self.address_number,self.travels_type,self.medic,self.kine,self.comment,self.reference_attention_time, self.reference_pickup_time,self.employ,self.emergency_type, self.accompanied]
  end

  def next_date
    PersonDate.next_date_of_person id
  end
end
