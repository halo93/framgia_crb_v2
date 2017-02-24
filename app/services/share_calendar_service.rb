class ShareCalendarService
  def initialize calendar
    @calendar = calendar
  end

  def share_sub_calendar
    @calendar.parent? ? when_share_parent_calendar : when_create_sub_calendar
  end

  private
  def when_share_parent_calendar
    parent_shared = UserCalendar.where calendar_id: @calendar.id
    parent_shared.each do |share|
      next unless @calendar.sub_calendars.any?
      @calendar.sub_calendars.each do |sub_calendar|
        user_calendar = UserCalendar.get_user_calendar share.user_id, sub_calendar.id
        if user_calendar.any?
          user_calendar.first.update_attributes permission_id: share.permission_id
        else
          UserCalendar.create(user_id: share.user_id, calendar_id: sub_calendar.id,
            permission_id: share.permission_id, color_id: sub_calendar.color_id)
        end
      end
    end
  end

  def when_create_sub_calendar
    parent = Calendar.find_by id: @calendar.parent_id
    parent_shared = UserCalendar.where calendar_id: parent.id
    parent_shared.each do |user_share|
      unless user_share.user_id == parent.user_id
        UserCalendar.create(user_id: user_share.user_id, calendar_id: @calendar.id,
          permission_id: user_share.permission_id, color_id: @calendar.color_id)
      end
    end
  end
end
