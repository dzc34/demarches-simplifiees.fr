class FranceConnectInformation < ApplicationRecord
  belongs_to :user, optional: true

  validates :france_connect_particulier_id, presence: true, allow_blank: false, allow_nil: false
end
