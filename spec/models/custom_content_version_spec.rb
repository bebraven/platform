require 'rails_helper'

RSpec.describe CustomContentVersion, type: :model do
  it { should belong_to :custom_content }
end
