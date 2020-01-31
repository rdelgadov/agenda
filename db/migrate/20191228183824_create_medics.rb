class CreateMedics < ActiveRecord::Migration[5.2]
  def change
    create_table :medics do |t|
      t.string :name
      t.string :rut
      t.string :phone
      t.string :type
      t.string :color
      t.string :attention


      t.timestamps
    end
  end
end
