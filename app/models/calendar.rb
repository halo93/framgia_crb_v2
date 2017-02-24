class Calendar < ActiveRecord::Base
  has_many :events, dependent: :destroy
  has_many :user_calendars, dependent: :destroy
  has_many :users, through: :user_calendars
  has_many :sub_calendars, class_name: Calendar.name, foreign_key: :parent_id

  accepts_nested_attributes_for :user_calendars, allow_destroy: true
  belongs_to :color
  belongs_to :owner, class_name: User.name, foreign_key: :user_id
  belongs_to :organization

  ATTRIBUTES_PARAMS = [:name, :google_calendar_id, :description, :user_id,
    :color_id, :parent_id, :status,
    user_calendars_attributes: [:id, :user_id, :permission_id, :color_id, :_destroy]]

  after_create :create_user_calendar

  enum status: [:no_public, :share_public, :public_hide_detail]

  scope :calendars_public, ->(calendars_id) do
    where(id: calendars_id).where.not status: Calendar.statuses[:no_public]
  end
  scope :of_user, ->(user) do
    select("calendars.*, uc.user_id, uc.calendar_id, uc.permission_id, \n
      uc.is_checked, uc.color_id as uc_color_id")
      .joins("INNER JOIN user_calendars as uc \n
        ON calendars.id = uc.calendar_id \n
        AND calendars.user_id = uc.user_id WHERE calendars.user_id = #{user.id}")
  end
  scope :shared_with_user, ->(user) do
    select("calendars.*, uc.user_id, uc.calendar_id, uc.permission_id, \n
      uc.is_checked, uc.color_id as uc_color_id")
      .joins("INNER JOIN user_calendars as uc \n
        ON uc.calendar_id = calendars.id \n
        WHERE uc.user_id = #{user.id} AND calendars.user_id <> #{user.id}")
  end
  scope :managed_by_user, ->(user) do
    select("calendars.*, uc.user_id, uc.calendar_id, uc.permission_id, \n
      uc.is_checked, uc.color_id as uc_color_id")
      .joins("INNER JOIN user_calendars as uc \n
        ON uc.calendar_id = calendars.id \n
        WHERE uc.user_id = #{user.id} AND uc.permission_id IN (1,2)")
  end

  def get_color user_id
    user_calendar = user_calendars.find_by user_id: user_id
    color_id = user_calendar.color_id
  end

  def parent?
    parent_id.nil?
  end

  private
  def create_user_calendar
    user_calendars.create({user_id: user_id, permission_id: 1,
                           color_id: color_id})
  end
end
