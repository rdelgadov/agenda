class AddCapacityToBuckets < ActiveRecord::Migration[5.2]
  def change
    add_column :buckets, :capacity, :integer, default: 0
  end
end
