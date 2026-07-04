class CreateInvoices < ActiveRecord::Migration[7.2]
  def change
    create_table :invoices do |t|
      t.references :client, null: false, foreign_key: true
      t.string :invoice_number, null: false
      t.date :issue_date, null: false
      t.date :due_date, null: false
      t.integer :status, null: false, default: 0
      t.integer :tax_rate, null: false, default: 10
      t.date :paid_on
      t.text :notes

      t.timestamps
    end

    add_index :invoices, :invoice_number, unique: true
    add_index :invoices, :status
  end
end
