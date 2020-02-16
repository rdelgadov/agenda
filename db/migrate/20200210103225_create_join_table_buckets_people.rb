class CreateJoinTableBucketsPeople < ActiveRecord::Migration[5.2]
  def change
    create_join_table :buckets, :people do |t|
      # t.index [:bucket_id, :person_id]
      # t.index [:person_id, :bucket_id]
    end
  end
end
