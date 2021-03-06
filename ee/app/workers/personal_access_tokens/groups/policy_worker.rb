# frozen_string_literal: true

module PersonalAccessTokens
  module Groups
    class PolicyWorker
      include ApplicationWorker

      idempotent!

      queue_namespace :personal_access_tokens
      feature_category :authentication_and_authorization

      def perform(group_id)
        group = ::Group.find_by_id(group_id)

        return unless group

        expiration_date = group.max_personal_access_token_lifetime_from_now

        return unless expiration_date

        ::User.managed_by(group).with_invalid_expires_at_tokens(expiration_date).find_each do |user|
          PersonalAccessTokens::RevokeInvalidTokens.new(user, expiration_date).execute
        end
      end
    end
  end
end
