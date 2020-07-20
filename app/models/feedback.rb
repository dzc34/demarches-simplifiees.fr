class Feedback < ApplicationRecord
  belongs_to :user, optional: false

  enum rating: {
    happy:    'happy',
    neutral:  'neutral',
    unhappy:  'unhappy'
  }

  validates :rating, presence: true
end
