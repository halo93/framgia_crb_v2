class Api::SessionsController < Api::BaseController
  skip_before_action :authenticate_with_token!
  respond_to :json

  def create
    user_password = request[:password]
    user_email = request[:email]
    user = user_email.present? && User.find_by(email: user_email)
    if user.present? && user.valid_password?(user_password)
      user.generate_authentication_token!
      user.save
      render json: {
        message: I18n.t("api.login_success"),
        user: user.as_json(include: [:user_calendars, :shared_calendars])
      }, status: :ok
    else
      render json: {errors: I18n.t("api.invalid_email_or_password")}, status: 422
    end
  end
end
