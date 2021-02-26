class AddNewToPeerReviewSubmissions < ActiveRecord::Migration[6.0]
  def change
    add_column :peer_review_submissions, :new, :boolean, default: true
  end
end
