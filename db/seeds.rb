# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

def yaml label
  YAML.load(File.read("#{Rails.root}/db/seeds/#{label}.yml"))
end

if User.count == 0
  bz_admin = User.create! [{first_name: 'Dev', last_name: 'AdminBZ', email: 'admin@beyondz.org', password: "#{ENV['DEV_ENV_USER_PASSWORD']}", confirmed_at: DateTime.now}]
  bz_admin.add_role :admin
  bv_admin = User.create! [{first_name: 'Dev', last_name: 'AdminBV', email: 'admin@bebraven.org', password: "#{ENV['DEV_ENV_USER_PASSWORD']}", confirmed_at: DateTime.now}]
  bv_admin.add_role :admin
end
