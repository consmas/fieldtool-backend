module Cleanup
  class PurgeExpiredTokensJob < ApplicationJob
    queue_as :low

    def perform
      # For JWT JTI strategy there is no token table; this is reserved for future token/session stores.
      Rails.logger.info("[Cleanup] PurgeExpiredTokensJob executed")
    end
  end
end
