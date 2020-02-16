class CreateBuckets < ActiveRecord::Migration[5.2]
  def change
    create_table :buckets do |t|
      t.date :date
      t.references :medic, foreign_key: true

      t.timestamps
    end
  end
end
