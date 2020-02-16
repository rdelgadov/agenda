class AddApDates < ActiveRecord::Migration[5.2]
  def change
    add_column :people, :medic, :integer, default: 1
    add_column :people, :kine, :integer, default: 2
    add_column :people,  :ap_dates, :date, {array: true, default: []}
  end
end
