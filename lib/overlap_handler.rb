class OverlapHandler
  ATTRS = [:overlap_time]
  attr_accessor *ATTRS

  def initialize event = Event.new
    @event = event
    place_name = @event.place_name || @event.name_place
    @db_events = generate_db_events @event.calendar_id,
      place_name, @event.parent_id || @event.id
    @temp_events = generate_temp_events event
    @repeat_events = []
    if (parent = @event.parent) && parent.is_repeat?
      @repeat_events = generate_temp_events parent
    end
  end

  def overlap?
    return true if check_overlap_event @repeat_events, @temp_events
    return true if check_overlap_event @db_events, @temp_events
    false
  end

  private
  def check_overlap_event events, temp_events
    events.each do |event|
      temp_events.each do |temp_event|
        if compare_time? event, temp_event
          @overlap_time = event.start_date
          return true
        end
      end
    end
    false
  end

  def generate_db_events calendar_id, place_name, parent_id
    events = Event.of_calendar_and_in_place(calendar_id, place_name)
             .reject_with_id parent_id

    calendar_service = CalendarService.new(events, @start_time, @end_time)
    calendar_service.repeat_data.select do |event|
      event.exception_type.nil? || (!event.delete_only? && !event.delete_all_follow?)
    end.sort_by(&:start_date)
  end

  def generate_temp_events event
    calendar_service = CalendarService.new([event], @start_time, @end_time)
    calendar_service.generate_event
  end

  def compare_time? db_event, temp_event
    if db_event.all_day || temp_event.all_day
      temp_event.start_date.day == db_event.start_date.day ||
        temp_event.finish_date.day == db_event.finish_date.day
    elsif db_event.start_date.day == temp_event.start_date.day
      # follow solution at http://wiki.c2.com/?TestIfDateRangesOverlap
      (db_event.start_date < temp_event.finish_date) &&
        (temp_event.start_date < db_event.finish_date)
    end
  end
end
