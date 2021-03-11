class CreateJobFunctions < ActiveRecord::Migration[6.0]
  def up
    create_table :job_functions do |t|
      t.string :name

      t.timestamps
    end

    functions = [
      "Administrative Services",
      "Arts and Design",
      "Business Development",
      "Community & Social Services",
      "Engineering",
      "Entrepreneurship",
      "Graphic Design",
      "Human Resources",
      "Military & Protective Services",
      "Operations",
      "Product Management",
      "Program Management",
      "Project Management",
      "Purchasing",
      "Quality Assurance",
      "Recruiting",
      "Research",
      "Sales",
      "Writing"
    ].sort

    tuples = functions.map { |i| "('#{i}', '#{Time.now}', '#{Time.now}')" }
    tuples_as_sql = tuples.join(', ')
    execute "INSERT INTO job_functions (name, created_at, updated_at) VALUES #{tuples_as_sql}"
  end

  def down
    drop_table :job_functions
  end
end
