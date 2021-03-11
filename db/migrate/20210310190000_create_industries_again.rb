class CreateIndustriesAgain < ActiveRecord::Migration[6.0]
  def up
    create_table :industries do |t|
      t.string :name

      t.timestamps
    end

    industries = [
      'Accounting',
      'Advertising',
      'Aerospace',
      'Banking',
      'Beauty / Cosmetics',
      'Biotechnology',
      'Business',
      'Chemical',
      'Communications',
      'Computer Engineering',
      'Computer Hardware',
      'Education',
      'Electronics',
      'Employment / Human Resources',
      'Energy',
      'Fashion',
      'Film',
      'Financial Services',
      'Fine Arts',
      'Food & Beverage',
      'Health',
      'Information Technology',
      'Insurance',
      'Journalism / News / Media',
      'Law',
      'Non-profit Management',
      'Management / Strategic Consulting',
      'Manufacturing',
      'Medical Devices & Supplies',
      'Performing Arts',
      'Pharmaceutical',
      'Public Administration',
      'Public Relations',
      'Publishing',
      'Marketing',
      'Racial Equity Consulting',
      'Real Estate',
      'Sports',
      'Technology',
      'Telecommunications',
      'Tourism',
      'Transportation / Travel',
      'Writing'
    ].sort

    tuples = industries.map { |i| "('#{i}', '#{Time.now}', '#{Time.now}')" }
    tuples_as_sql = tuples.join(', ')
    execute "INSERT INTO industries (name, created_at, updated_at) VALUES #{tuples_as_sql}"
  end

  def down
    drop_table :industries
  end
end
