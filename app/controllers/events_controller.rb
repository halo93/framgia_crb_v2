class EventsController < ApplicationController
  load_and_authorize_resource
  skip_before_action :authenticate_user!, only: :show
  before_action :load_calendars, :load_places, only: [:new, :edit]
  before_action only: [:edit, :update, :destroy] do
    validate_permission_change_of_calendar @event.calendar
  end
  before_action only: :show do
    validate_permission_see_detail_of_calendar @event.calendar
  end

  serialization_scope :current_user

  def index
    @events = Event.in_calendars params[:calendar_ids]
    calendar_service = CalendarService.new(@events, params[:start_time_view],
      params[:end_time_view])
    calendar_service.user = current_user
    @events = calendar_service.repeat_data
    render json: @events, each_serializer: FullCalendar::EventSerializer,
      root: :events,
      adapter: :json,
      meta: t("api.request_success"),
      meta_key: :message,
      status: :ok
  end

  def show
    locals = {
      event_id: @event.id,
      start_date: params[:start],
      finish_date: params[:end]
    }.to_json

    @event.start_date = params[:start]
    @event.finish_date = params[:end]

    respond_to do |format|
      format.html do
        render partial: "events/popup",
          locals: {
            event: @event,
            fdata: Base64.urlsafe_encode64(locals)
          }
      end
    end
  end

  def new
    if params[:fdata]
      hash_params = begin
                      JSON.parse(Base64.decode64 params[:fdata])
                    rescue
                      {"event": {}}
                    end
      @event = if hash_params["event_id"].present?
                 Event.find(hash_params["event_id"]).dup
               elsif hash_params["title"].present?
                 Event.new title: hash_params["title"]
               else
                 Event.new hash_params["event"]
      end
    end

    load_related_data
  end

  def create
    create_service = Events::CreateService.new current_user, params
    respond_to do |format|
      if create_service.perform
        format.html do
          flash[:success] = t "events.flashs.created"
          redirect_to root_path
        end
        format.json do
          render json: create_service.event.json_data(current_user.id)
        end
      else
        if @is_overlap = create_service.is_overlap
          flash[:error] = t "events.flashs.overlap"
          format.html{redirect_to :back}
        else
          format.html{render :new}
        end
        format.json do
          render json: {is_overlap: @is_overlap, is_errors: @event.errors.any?}
        end
      end
    end
  end

  def edit
    if params[:fdata]
      hash_params = begin
                      JSON.parse(Base64.decode64 params[:fdata])
                    rescue
                      {"event": {}}
                    end
      @event.start_date = hash_params["start_date"]
      @event.finish_date = if @event.all_day?
                             @event.start_date.end_of_day
                           else
                             hash_params["finish_date"]
      end
    end
    load_related_data
  end

  def update
    update_service = Events::UpdateService.new current_user, @event, params
    respond_to do |format|
      if update_service.perform
        format.json do
          render json: update_service.event, serializer: EventSerializer,
            meta: t("events.flashs.updated"), meta_key: :message, status: :ok
        end
      else
        @is_overlap = update_service.is_overlap
        format.json{render json: {is_overlap: @is_overlap}, status: 422}
      end
    end
  end

  def destroy
    delete_service = Events::DeleteService.new(@event, params)

    respond_to do |format|
      if delete_service.perform
        format.html do
          flash[:success] = t "events.flashs.deleted"
          redirect_to root_path
        end
        format.json{render json: {message: t("events.flashs.deleted")}, status: :ok}
      else
        format.html do
          flash[:danger] = t "events.flashs.not_deleted"
          redirect_to root_path
        end

        format.json{render json: {message: t("events.flashs.not_deleted")}}
      end
    end
  end

  private
  def event_params
    params.require(:event).permit Event::ATTRIBUTES_PARAMS
  end

  def handle_event_params
    params.require(:event).permit Event::ATTRIBUTES_PARAMS[1..-2]
  end

  def load_calendars
    @calendars = current_user.manage_calendars
  end

  def load_places
    @places = current_user.places.pluck :name, :id
    @places.push [@event.name_place, 0] if @event.persisted? && @event.place.nil?
  end

  def load_related_data
    Notification.all.each do |notification|
      @event.notification_events.find_or_initialize_by notification: notification
    end

    DaysOfWeek.all.each do |days_of_week|
      @event.repeat_ons.find_or_initialize_by days_of_week: days_of_week
    end

    @repeat_ons = @event.repeat_ons.sort{|a, b| a.days_of_week_id <=> b.days_of_week_id}
  end
end
