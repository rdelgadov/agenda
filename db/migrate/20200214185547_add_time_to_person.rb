class AddTimeToPerson < ActiveRecord::Migration[5.2]
  def change
    add_column :people, :required_attention_time, :string, default: ''
    add_column :people, :reference_attention_time, :string, default: ''
    add_column :people, :reference_pickup_time, :string, default: ''
  end
end
