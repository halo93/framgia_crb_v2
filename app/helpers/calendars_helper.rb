module CalendarsHelper
  def link_to_event event_title, event
    locals = {
      event_id: event.id,
      start_date: event.start_date.strftime(t "events.time.formats.datetime_format"),
      finish_date: event.finish_date.strftime(t "events.time.formats.datetime_format")
    }.to_json
    fdata = Base64.urlsafe_encode64(locals)
    render "events/buttons/link", url: "/events/#{event.parent.id}/edit?fdata=#{fdata}",
      event_title: event_title
  end

  def btn_via_permission user, event, fdata = nil
    user_calendar = user.user_calendars.find_by calendar: event.calendar
    btn = render "events/buttons/btn_copy", url: "/events/new?fdata=#{fdata}"
    btn = "" if event.calendar.is_default? || user_calendar.permission_id == 4

    if Settings.permissions_can_make_change.include? user_calendar.permission_id
      btn += render "events/buttons/btn_cancel"
      btn += render "events/buttons/btn_edit",
        url: "/events/#{event.id}/edit?fdata=#{fdata}"
      btn += render "events/buttons/btn_save"
      btn += render "events/buttons/btn_delete"
    elsif user_calendar.permission_id == 3
      btn += render "events/buttons/btn_detail",
        url: "/events/#{event.id}"
    end
    btn.html_safe
  end

  def link_via_permission event, fdata = nil
    if !user_signed_in?
      if event.calendar.share_public?
        link = render "events/links/link_view", url: "/events/#{event.id}"
      else
        link = ""
      end
    else
      user_calendar = current_user.user_calendars.find_by calendar: event.calendar
      if Settings.permissions_can_make_change.include? user_calendar.permission_id
        link = render "events/links/link_view", url: "/events/#{event.id}"
        link += render "events/links/link_edit", url: "/events/#{event.id}/edit?fdata=#{fdata}"
      elsif user_calendar.permission_id == 3
        link = render "events/links/link_view", url: "/events/#{event.id}"
      elsif user_calendar.permission_id == 4
        link = ""
      end
    end
  end

  def confirm_popup_repeat_events action
    render "events/confirm_popup_repeat", action: action
  end

  def is_event_controller?
    params[:controller] == "events"
  end
end
