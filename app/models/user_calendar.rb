class UserCalendar < ActiveRecord::Base
  belongs_to :user
  belongs_to :calendar
  belongs_to :permission
  belongs_to :color

  delegate :sub_calendars, to: :calendar, allow_nil: true
  delegate :email, :name, to: :user, prefix: true, alow_nil: true

  scope :get_user_calendar, ->(user_id, calendar_id) do
    where("user_id = ? AND calendar_id = ?", user_id, calendar_id)
  end

  ATTR_PARAMS = [:user_id, :permission_id, :color_id, :is_checked]
end
