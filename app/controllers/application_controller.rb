require 'csv'

class ApplicationController < ActionController::Base
  def index
    render 'layouts/search'
  end

  def create_attention_capacity
    attributes = %w[ident attention_type date t_start	capacity]
    week = Date.tomorrow.at_beginning_of_week
    file = CSV.generate(headers: true) do |csv|
      csv << attributes
      Medic.all.each do |medic|
        attention = "Primaria"
        attention = "Kinesiologia" unless medic.type==nil
        medic.attention.each do |date|
          date[1].each do |day|
            occupied = '1'
            occupied = '0' if PersonDate.where(medic_id: medic.id, date: (week+(day.to_i).day).to_s, time:date[0], person_id: 1).blank?
            csv << [medic.id, attention, (week+(day.to_i).day).to_s, date[0], occupied]
          end
        end
      end
    end
    send_data file, filename: "data-#{Date.today.to_s}.csv", disposition: :attachment
    end
end
