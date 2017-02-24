class CalendarService
  attr_accessor :events, :base_events, :user

  def initialize base_events = nil, start_time_view = nil, end_time_view = nil
    @events = Array.new
    @base_events = base_events
    @start_time_view = start_time_view
    @end_time_view = end_time_view
  end

  def repeat_data
    event_no_repeats = @base_events.no_repeats.not_delete_only
    event_no_repeats.each do |event|
      @events << FullCalendar::Event.new(event, user, true)
    end

    (@base_events - event_no_repeats).each do |event|
      next unless event.parent?
      generate_repeat_from_event_parent event
    end

    @events
  end

  def generate_event
    event = @base_events.first

    if event.is_repeat?
      generate_repeat_from_event_parent event
    else
      @events << FullCalendar::Event.new(event, user)
    end

    @events
  end

  def generate_event_delay
    generate_repeat_from_event_parent @base_events, Settings.notify_type.email
  end

  private
  def generate_repeat_from_event_parent event, function = nil
    if event.repeat_daily?
      repeat_daily event, event.start_repeat.to_date, function
    elsif event.repeat_weekly?
      start_day = event.start_repeat.wday
      if event.repeat_ons.present?
        @repeat_on_days = event.repeat_ons.map{|repeat_on| repeat_on.days_of_week.name}
        @repeat_on_days.each do |repeat_on|
          @repeat_on_day = Settings.event.repeat_data.index repeat_on
          repeat_date = event.start_repeat.to_date

          if @repeat_on_day == start_day
            start = repeat_date
          elsif @repeat_on_day > start_day
            start = repeat_date + (@repeat_on_day - start_day).days
          else
            start = repeat_date + (Settings.seven + @repeat_on_day - start_day).days
          end

          repeat_weekly event, start, function
        end
      else
        event.days_of_weeks.each do |days_of_week|
          @repeat_on_day = Settings.event.repeat_data.index(days_of_week.name)
          repeat_date = event.start_repeat.to_date

          if @repeat_on_day == start_day
            start = repeat_date
          elsif @repeat_on_day > start_day
            start = repeat_date + (@repeat_on_day - start_day).days
          else
            start = repeat_date + (Settings.seven + @repeat_on_day - start_day).days
          end

          repeat_weekly event, start, function
        end
      end
    elsif event.repeat_monthly?
      repeat_monthly event, event.start_repeat.to_date, function
    elsif event.repeat_yearly?
      repeat_yearly event, event.start_repeat.to_date, function
    end
  end

  def repeat_daily event, start, function = nil
    show_repeat_event event, event.repeat_every.days, start, function
  end

  def repeat_weekly event, start, function = nil
    show_repeat_event event, event.repeat_every.weeks, start, function
  end

  def repeat_monthly event, start, function = nil
    show_repeat_event event, event.repeat_every.months, start, function
  end

  def repeat_yearly event, start, function = nil
    show_repeat_event event, event.repeat_every.years, start, function
  end

  def weekly_start_exception event
    exception_day = event.exception_time.wday
    exception_date = event.exception_time.to_date

    if @repeat_on_day == exception_day
      return exception_date
    elsif @repeat_on_day > exception_day
      return exception_date + (@repeat_on_day - exception_day).days
    else
      return exception_date + (Settings.seven - exception_day).days
    end
  end

  def show_repeat_event event, step, start, function = nil
    ex_destroy_events = Array.new
    ex_update_events = Array.new
    ex_edit_follow = Array.new
    ex_update_follow = Array.new

    if @start_time_view.present?

      if event.end_repeat < @start_time_view.to_date || (@end_time_view.to_date < start)
        repeat_event = []
      elsif @start_time_view.to_date > start && (event.daily? || event.weekly?)
        mod = ((@start_time_view.to_date - start).to_i.days % step) / Settings.second_in_day
        if mod == 0
          repeat_event = [@start_time_view.to_date]
        else
          repeat_event = [@start_time_view.to_date + (step - mod.days)]
        end
      else
        repeat_event = [start]
      end
    else
      repeat_event = [start]
    end

    if event.exception_type.present?
      if event.delete_only?
        ex_destroy_events << event.start_date.to_date
      elsif event.delete_all_follow?
        if event.repeat_weekly?
          ex_destroy_events << weekly_start_exception(event)
        else
          ex_destroy_events << event.exception_time.to_date
        end

        if @end_time_view.present? && event.end_repeat > @end_time_view
          end_repeat = @end_time_view
        else
          end_repeat = event.end_repeat
        end

        while ex_destroy_events.last <= end_repeat.to_date - step
          ex_destroy_events << ex_destroy_events.last + step
        end
      end
    end

    event.event_exceptions.each do |exception_event|
      if exception_event.delete_only?
        ex_destroy_events << exception_event.exception_time.to_date
        if exception_event.old_exception_edit_all_follow?
          ex_edit_follow << exception_event
        end
      elsif exception_event.delete_all_follow?
        if event.repeat_weekly?
          ex_destroy_events << weekly_start_exception(exception_event)
        else
          ex_destroy_events << exception_event.exception_time.to_date
        end

        if @end_time_view.present? && exception_event.end_repeat > @end_time_view
          end_repeat = @end_time_view
        else
          end_repeat = exception_event.end_repeat
        end

        while ex_destroy_events.last <= end_repeat.to_date - step
          ex_destroy_events << ex_destroy_events.last + step
        end
      elsif exception_event.edit_only?
        unless event.repeat_weekly? && start.wday != exception_event.exception_time.wday
          ex_update_events << exception_event.exception_time.to_date
          event_fullcalendar = FullCalendar::Event.new exception_event, user, true
          @events << event_fullcalendar

          if function.present?
            NotificationService.new(event, event_fullcalendar).perform
          end
        end
      elsif exception_event.edit_all_follow?
        ex_edit_follow << exception_event
      end
    end

    ex_edit_follow.each do |exception_event|
      times_occurs = []
      if event.repeat_weekly?
        start_exceptiop_date = weekly_start_exception exception_event
        ex_update_follow << start_exceptiop_date
        times_occurs << start_exceptiop_date
      else
        ex_update_follow << exception_event.exception_time.to_date
        times_occurs << exception_event.exception_time.to_date
      end

      if @end_time_view.present? && exception_event.end_repeat > @end_time_view
        end_repeat = @end_time_view
      else
        end_repeat = exception_event.end_repeat
      end

      while ex_update_follow.last <= end_repeat.to_date - step
        ex_update_follow << ex_update_follow.last + step
        times_occurs << times_occurs.last + step
      end

      (times_occurs - ex_destroy_events - ex_update_events).each do |follow_time|
        event_fullcalendar = FullCalendar::Event.new exception_event, user
        event_fullcalendar.update_info(follow_time)

        @events << event_fullcalendar

        if function.present?
          NotificationService.new(event, event_fullcalendar).perform
        end
      end
    end

    if @end_time_view.present? && event.end_repeat > @end_time_view
      end_repeat = @end_time_view
    else
      end_repeat = event.end_repeat
    end

    if repeat_event.any?
      while repeat_event.last <= end_repeat.to_date - step
        repeat_event << repeat_event.last + step
      end
    end

    range_repeat_time = repeat_event - ex_destroy_events -
                        ex_update_events - ex_update_follow

    range_repeat_time.each do |repeat_date|
      event_temp = FullCalendar::Event.new event, user
      if repeat_date <= event.end_repeat
        event_temp.update_info(repeat_date)
        @events << event_temp
      end

      NotificationService.new(event, event_temp).perform if function.present?
    end
  end
end
