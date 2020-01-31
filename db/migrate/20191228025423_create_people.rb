class CreatePeople < ActiveRecord::Migration[5.2]
  def change
    create_table :people do |t|
      t.string :name
      t.string :rut
      t.string :phone
      t.bigint :bp
      t.string :first_name
      t.string :second_name
      t.boolean :rest
      t.boolean :transportation
      t.string :latitude
      t.string :longitude
      t.integer :vehicle_type
      t.string :town
      t.string :address
      t.boolean :accompanied
      t.string :address_number
      t.integer :number_of_days
      t.integer :travels_type
      t.date :dates, array: true, default: [].to_yaml

      t.timestamps
    end
  end
end
