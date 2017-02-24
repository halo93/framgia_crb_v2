module NotifyDesktop
  private
  def notify_desktop_event event, action_name
    if action_name == Settings.create_event
      set_notify_data event, I18n.t("events.notification.remind_create")
    elsif action_name == Settings.start_event
      set_notify_data event, I18n.t("events.notification.remind_start_event")
    elsif action_name == Settings.destroy_event
      set_notify_data event, I18n.t("events.notification.remind_delete_event")
    elsif action_name == Settings.destroy_all_following_event
      set_notify_data event,
        I18n.t("events.notification.remind_delete_all_following_event")
    elsif action_name == Settings.destroy_all_event
      set_notify_data event,
        I18n.t("events.notification.remind_delete_all_event")
    elsif action_name == Settings.edit_event
      set_notify_data event, I18n.t("events.notification.remind_edit_event")
    elsif action_name == Settings.edit_all_following_event
      set_notify_data event,
        I18n.t("events.notification.remind_edit_all_following_event")
    elsif action_name == Settings.edit_all_event
      set_notify_data event,
        I18n.t("events.notification.remind_edit_all_event")
    end
  end

  def set_notify_data event, remind_message
    event_title = event.title
    event_start = event.start_date.strftime Settings.event.format_datetime
    event_finish = event.finish_date.strftime Settings.event.format_datetime
    event_desc = event.description
    from_user = event.owner.name
    notify_to_attendees = Array.new
    event.attendees.each do |attendee|
      notify_to_attendees << attendee.user_name
    end

    notify_data = {title: event_title, start: event_start,
                   finish: event_finish, desc: event_desc,
                   attendees: notify_to_attendees.join(", "),
                   from_user: from_user, remind_message: remind_message}

    event.attendees.each do |attendee|
      notify_data[:to_user] = attendee.user_name
      if event.owner.id != attendee.user_id
        WebsocketRails.users[attendee.user_id]
          .send_message(:websocket_notify, notify_data)
      end
    end
  end
end
