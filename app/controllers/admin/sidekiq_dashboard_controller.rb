require "sidekiq/api"

class Admin::SidekiqDashboardController < ActionController::Base
  before_action :http_basic_auth

  def show
    @stats = Sidekiq::Stats.new
    @queues = Sidekiq::Queue.all.map { |q| [q.name, q.size] }.to_h
    @processes = Sidekiq::ProcessSet.new
  end

  private

  def http_basic_auth
    username = ENV["SIDEKIQ_ADMIN_USER"].presence
    password = ENV["SIDEKIQ_ADMIN_PASSWORD"].presence
    return if username.blank? || password.blank?

    authenticate_or_request_with_http_basic("Sidekiq Dashboard") do |user, pass|
      ActiveSupport::SecurityUtils.secure_compare(user, username) &
        ActiveSupport::SecurityUtils.secure_compare(pass, password)
    end
  end
end
