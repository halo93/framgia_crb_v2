class User < ActiveRecord::Base
  devise :database_authenticatable, :rememberable, :trackable, :validatable,
    :registerable, :omniauthable

  has_many :user_calendars, dependent: :destroy
  has_many :calendars, dependent: :destroy
  has_many :user_organizations, dependent: :destroy
  has_many :organizations, through: :user_organizations
  has_many :shared_calendars, through: :user_calendars, source: :calendar
  has_many :attendees, dependent: :destroy
  has_many :events
  has_many :invited_events, through: :attendees, source: :event
  has_many :places
  has_one :setting, dependent: :destroy
  has_many :user_teams, dependent: :destroy
  has_many :teams, through: :user_teams
  has_one :permission, through: :user_organizations

  delegate :timezone, :timezone_name,
    to: :setting, prefix: true, allow_nil: true

  validates :name, presence: true, length: {maximum: 50}
  validates :email, length: {maximum: 255}

  after_create :create_calendar
  before_create :generate_authentication_token!

  scope :search, ->(q){where "email LIKE '%#{q}%'"}
  scope :order_by_email, ->{order email: :asc}
  scope :with_ids, ->(ids){where id: ids}
  scope :can_invite_to_organization, ->(organization_id) do
    where NOT_YET_INVITE, organization_id
  end

  accepts_nested_attributes_for :setting

  ATTR_PARAMS = [:name, :email, :chatwork_id, :password, :password_confirmation,
    setting_attributes: [:id, :timezone_name, :country]]
  NOT_YET_INVITE = "id NOT IN (SELECT DISTINCT user_organizations.user_id
    FROM user_organizations WHERE user_organizations.organization_id = ?)"

  def my_calendars
    Calendar.of_user self
  end

  def other_calendars
    Calendar.shared_with_user self
  end

  def manage_calendars
    Calendar.managed_by_user self
  end

  Settings.permissions.each_with_index do |action, permission|
    define_method("permission_#{action}?") do |calendar|
      user_calendars.find_by calendar: calendar, permission_id: permission + 1
    end
  end

  def has_permission? calendar
    user_calendars.find_by calendar: calendar
  end

  def default_calendar
    calendars.find_by is_default: true
  end

  def is_user? user
    self == user
  end

  class << self
    def existed_email? email
      User.pluck(:email).include? email
    end

    def from_omniauth auth
      user = where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
        user.provider = auth.provider
        user.uid = auth.uid
        user.email = auth.info.email
        user.password = Devise.friendly_token[0, 20]
      end
      if user.setting.nil?
        user.create_setting timezone_name: ActiveSupport::TimeZone.all.sample.name
      end
      user
    end
  end

  def generate_authentication_token!
    self.auth_token = Devise.friendly_token while
      self.class.exists? auth_token: auth_token
  end

  def full_timezone_name
    ["GMT%+02d" % setting_timezone, tzinfo_name].join(" ")
  end

  def tzinfo_name
    timezone.tzinfo.name
  end

  def timezone
    @timezone ||= ActiveSupport::TimeZone[setting_timezone_name]
  end

  private
  def create_calendar
    calendars.create(name: name, is_default: true)
  end
end
