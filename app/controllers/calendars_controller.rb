class CalendarsController < ApplicationController
  load_and_authorize_resource
  before_action :load_colors, except: [:show, :destroy]
  before_action :load_users, :load_permissions, only: [:new, :edit]
  before_action :load_user_calendar, only: [:edit, :update]
  before_action :load_place
  before_action only: [:edit, :update] do
    unless current_user.permission_manage? @calendar
      flash[:alert] = t("flash.messages.not_permission")
      redirect_to root_path
    end
  end

  def index
    @event = Event.new
    @my_calendars = current_user.my_calendars
    @other_calendars = current_user.other_calendars
    @manage_calendars = current_user.manage_calendars
  end

  def create
    @calendar.user_id = current_user.id
    if @calendar.save
      ShareCalendarService.new(@calendar).share_sub_calendar
      flash[:success] = t "calendar.success_create"
      redirect_to root_path
    else
      flash[:alert] = t "calendar.danger_create"
      render :new
    end
  end

  def new
    @calendar.color = @colors.sample
    if params[:user_id].present?
      respond_to do |format|
        format.html do
          render partial: "calendars/user_share",
            locals: {
              id: nil,
              user_id: params[:user_id],
              email: params[:email],
              permission: params[:permission],
              permissions: Permission.all,
              color_id: @calendar.color_id,
              _destroy: false
            }
        end
      end
    end
  end

  def edit
    @user_selected = User.find_by email: params[:email] if params[:email]
  end

  def update
    @calendar.status = "no_public" unless calendar_params[:status]
    if @calendar.update_attributes calendar_params
      ShareCalendarService.new(@calendar).share_sub_calendar
      flash[:success] = t "calendar.success_update"
      redirect_to root_path
    else
      render :edit
    end
  end

  def destroy
    if @calendar.destroy
      flash[:success] = t "calendars.deleted"
    else
      flash[:alert] = t "calendars.not_deleted"
    end
    redirect_to root_path
  end

  private
  def calendar_params
    params.require(:calendar).permit Calendar::ATTRIBUTES_PARAMS
  end

  def load_colors
    @colors ||= Color.all
  end

  def load_users
    @users ||= User.all
  end

  def load_permissions
    @permissions ||= Permission.all
  end

  def load_user_calendar
    @user_calendar = @calendar.user_calendars.find_by user_id: current_user.id
  end

  def load_place
    @places = current_user.places
  end
end
