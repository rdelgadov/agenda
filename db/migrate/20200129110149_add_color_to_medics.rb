class AddColorToMedics < ActiveRecord::Migration[5.2]
  def change
    add_column :medics, :color, :string, default: 'red'
  end
end
