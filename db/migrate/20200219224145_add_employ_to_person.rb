class AddEmployToPerson < ActiveRecord::Migration[5.2]
  def change
    add_column :people, :employ, :string
    add_column :people, :emergency_type, :string
  end
end
