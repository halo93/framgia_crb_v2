class Team < ActiveRecord::Base
  belongs_to :organization, dependent: :destroy
  has_many :user_teams, dependent: :destroy
  has_many :users, through: :user_teams
  has_many :event_teams, dependent: :destroy
  has_many :events, through: :event_teams

  validates :name, presence: true, length: {maximum: 50}
end
