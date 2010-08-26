ActiveRecord::Schema.define(:version => 2) do
  create_table :audited_records, :force => true do |t|
    t.string :name
    t.integer :number_to_change
    t.datetime :date_to_change
    t.timestamps
  end
  create_table :audits, :force => true do |t|
    t.integer :audited_record_id
    t.text :description
    t.string :initial_value, :changed_value
    t.integer :changed_by
    t.string :visibility
    t.timestamps
  end
  create_table :quick_audits, :force => true do |t|
    t.text :description
    t.string :visibility
    t.timestamps
  end
end
