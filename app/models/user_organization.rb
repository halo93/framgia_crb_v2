class UserOrganization < ActiveRecord::Base
  belongs_to :user
  belongs_to :organization

  after_create :send_invitation_email

  delegate :name, :owner_id, to: :organization, prefix: true

  enum status: [:waiting, :accept]

  ATTRIBUTE_PARAMS = [:organization_id]

  def send_invitation_email
    argv = {
      user_id: user_id,
      organization_id:  organization_id,
      action_type: :invite_organization
    }

    EmailWorker.perform_async argv unless organization_owner_id == user_id
  end
end
