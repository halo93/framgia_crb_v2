class EventSerializer < ActiveModel::Serializer
  include SharedMethods

  attributes :id, :title, :description, :status, :color, :all_day,
    :repeat_type, :repeat_every, :user_id, :calendar_id, :start_date,
    :finish_date, :start_repeat, :end_repeat, :exception_time, :exception_type,
    :old_exception_type, :parent_id, :name_place, :place_id, :chatwork_room_id,
    :task_content, :message_content, :google_event_id, :google_calendar_id, :deleted_at

  has_many :attendees
  has_many :users, through: :attendees
  has_many :days_of_weeks
  has_many :event_exceptions, class_name: Event.name, foreign_key: :parent_id
  has_many :notification_events

  belongs_to :calendar
  belongs_to :owner, class_name: User.name, foreign_key: :user_id
  belongs_to :event_parent, class_name: Event.name, foreign_key: :parent_id
  belongs_to :place

  def color
    object.color || object.calendar.color.try(:color_hex)
  end

  private
  def timezone
    @timezone ||= begin
                    object.calendar.owner.setting.timezone
                  rescue
                    7
                  end
  end
end
