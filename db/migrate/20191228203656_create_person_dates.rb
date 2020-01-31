class CreatePersonDates < ActiveRecord::Migration[5.2]
  def change
    create_table :person_dates do |t|
      t.date :date
      t.string :time
      t.references :person, foreign_key: true
      t.references :medic, foreign_key: true

      t.timestamps
    end
  end
end
