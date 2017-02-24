module ApplicationHelper
  def title page_title
    content_for :title, page_title.to_s
  end

  def flash_class level
    case level
    when :notice then "alert-info"
    when :error then "alert-error"
    when :alert then "alert-warning"
    when :success then "alert-success"
    end
  end

  def datetime_format object, format
    l(object.in_time_zone(current_user.setting_timezone),
      format: t("events.time.formats.#{format}")) if object.present?
  end

  def get_avatar user
    avatar_url = user.avatar.nil? ? image_path("user.png") : user.avatar
    image_tag(avatar_url, alt: user.name, class: "img-circle")
  end

  def is_edit_form? param
    param == "edit"
  end

  def resource_name
    :user
  end

  def resource
    instance_variable_get(:"@#{resource_name}")
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end

  def resource_class
    User
  end
end
