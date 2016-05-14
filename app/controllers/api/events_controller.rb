class Api::EventsController < ApplicationController
  respond_to :json

  def index
    if params[:page].present? || params[:calendar_id]
      @data = current_user.events.upcoming_event(params[:calendar_id]).
        page(params[:page]).per Settings.users.upcoming_event
      respond_to do |format|
        format.html {
          render partial: "users/event", locals: {events: @data, user: current_user}
        }
      end
    else
      @events = Event.in_calendars params[:calendars]
      @data = @events.map{|event| event.json_data(current_user.id)}
      render json: @data
    end
  end

  def update
    @event = Event.find_by id: params[:id]
    if params[:start_repeat].nil?
      @start_repeat = params[:start]
    else
      @start_repeat = params[:start_repeat]
    end
    if params[:end_repeat].nil?
      difference = (params[:start].to_date - @event.start_date.to_date).to_i
      @end_repeat = @event.end_repeat + difference.days
    else
      @end_repeat = params[:end_repeat].to_date + 1.days
    end

    render text: @event.update_attributes(title: params[:title], 
      start_date: params[:start], finish_date: params[:end],
      start_repeat: @start_repeat, end_repeat: @end_repeat, 
      all_day: params[:all_day]) ? 
      t("events.flashs.updated") : t("events.flashs.not_updated")
  end

  def destroy
    @event = Event.find_by id: params[:id]
    render text: @event.destroy ? 
      t("events.flashs.deleted") : t("events.flashs.not_deleted")
  end
end
