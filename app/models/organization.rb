class Organization < ActiveRecord::Base
  has_many :user_organizations, dependent: :destroy
  has_many :users, through: :user_organizations
  belongs_to :owner, class_name: User.name, foreign_key: :owner_id
  has_many :teams, dependent: :destroy
  has_many :calendars

  validates :name, presence: true, uniqueness: {case_sensitive: false}

  delegate :name, to: :owner, prefix: :owner, allow_nil: true

  after_create :add_owner_to_organization

  scope :accepted_by_user, ->(user) do
    select("organizations.*")
      .joins("INNER JOIN user_organizations
      ON organizations.id = user_organizations.organization_id
      WHERE user_organizations.status = 1
      AND user_organizations.user_id = #{user.id}")
  end

  ATTRIBUTE_PARAMS = [:name, :owner_id]

  private

  def add_owner_to_organization
    @user_organization = UserOrganization.create status: :accept,
      user_id: owner_id, organization_id: id
  end
end
