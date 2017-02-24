module GoogleApi
  def self.included klass
    klass.extend ModuleMethods
  end

  module ModuleMethods
    def initialize_googleapi_client
      keypath = Rails.root.join("config", "client.p12").to_s
      key = Google::APIClient::PKCS12.load_key(keypath, "notasecret")

      @client = Google::APIClient.new({application_name: I18n.t("events.framgia_crb_system"),
                                       application_version: "1.0"})
      @client.authorization = Signet::OAuth2::Client.new(
        token_credential_uri: "https://accounts.google.com/o/oauth2/token",
        audience: "https://accounts.google.com/o/oauth2/token",
        scope: "https://www.googleapis.com/auth/calendar",
        issuer: "framgia-crb-system@framgia-crb-system.iam.gserviceaccount.com",
        signing_key: key)
      @client.authorization.fetch_access_token!
      @client
    end

    def g_event_data event
      attendees = event.attendees.map{|attendee| {email: attendee.attendee_email}}
      attendees = attendees << {email: event.calendar.owner.email}

      {
        summary: event.name_place + ": " + event.title,
        location: event.name_place,
        description: event.description,
        start: {dateTime: event.start_date.strftime(I18n.t("events.time.formats.datetime_ft_t_z"))},
        end: {dateTime: event.finish_date.strftime(I18n.t("events.time.formats.datetime_ft_t_z"))},
        attendees: attendees
      }
    end
  end
end
