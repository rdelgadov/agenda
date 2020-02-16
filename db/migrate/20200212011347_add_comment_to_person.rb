class AddCommentToPerson < ActiveRecord::Migration[5.2]
  def change
    add_column :people, :comment, :string, default: ''
  end
end
