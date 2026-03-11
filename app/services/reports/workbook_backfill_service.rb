module Reports
  class WorkbookBackfillService
    def initialize(actor:, month: nil)
      @actor = actor
      @month = parse_month(month)
      @summary = {
        month: @month&.strftime("%Y-%m"),
        trips_updated: 0,
        road_expenses_synced: 0,
        fuel_logs_created: 0,
        driver_profiles_created: 0,
        driver_scores_created: 0,
        errors: []
      }
    end

    def call
      ActiveRecord::Base.transaction do
        sync_trips
        sync_driver_profiles
        sync_driver_scores
      end
      @summary
    rescue StandardError => e
      @summary[:errors] << e.message
      @summary
    end

    private

    def parse_month(value)
      return nil if value.blank?

      Date.strptime(value.to_s, "%Y-%m").beginning_of_month
    rescue ArgumentError
      nil
    end

    def trips_scope
      scope = Trip.all
      return scope if @month.blank?

      from = @month.beginning_of_month
      to = @month.end_of_month
      scope.where(
        "(trips.trip_date BETWEEN ? AND ?) OR (trips.trip_date IS NULL AND trips.created_at BETWEEN ? AND ?)",
        from, to, from.beginning_of_day, to.end_of_day
      )
    end

    def sync_trips
      trips_scope.find_each do |trip|
        changed = false

        if trip.trip_date.blank?
          trip.trip_date = (trip.completed_at || trip.created_at)&.to_date
          changed = true
        end

        if trip.status_completed? && trip.completed_at.blank? && trip.trip_date.present?
          trip.completed_at = trip.trip_date.end_of_day
          changed = true
        end

        if changed
          trip.save!
          @summary[:trips_updated] += 1
        end

        sync_road_expense(trip)
        sync_fuel_log(trip)
      rescue StandardError => e
        @summary[:errors] << "trip ##{trip.id}: #{e.message}"
      end
    end

    def sync_road_expense(trip)
      amount = trip.road_expense_disbursed.to_d
      return unless amount.positive?

      expense = ExpenseEntry.active.where(trip_id: trip.id, category: ExpenseEntry.categories[:road_expenses]).order(created_at: :desc).first
      expense ||= ExpenseEntry.new(trip_id: trip.id, category: :road_expenses)

      expense.assign_attributes(
        vehicle_id: trip.vehicle_id,
        driver_id: trip.driver_id,
        amount: amount,
        currency: "GHS",
        description: "Road expense synced from trip",
        reference: trip.road_expense_reference.presence || trip.reference_code.presence || trip.waybill_number,
        payment_method: trip.road_expense_payment_method,
        expense_date: (trip.trip_date || Date.current).in_time_zone,
        is_auto_generated: true,
        auto_rule_key: "trip_road_expense_sync_v1",
        status: (trip.road_expense_payment_status == "paid" ? :paid : :draft),
        paid_by_id: (trip.road_expense_payment_status == "paid" ? @actor.id : nil),
        paid_at: (trip.road_expense_payment_status == "paid" ? Time.current : nil),
        created_by_id: (expense.created_by_id || @actor.id)
      )
      expense.save!
      @summary[:road_expenses_synced] += 1
    end

    def sync_fuel_log(trip)
      liters = trip.fuel_litres_filled.to_d
      liters = trip.fuel_allocated_litres.to_d if liters <= 0
      return unless liters.positive?
      return if FuelLog.exists?(trip_id: trip.id, transaction_type: "actual_fill")

      date = (trip.trip_date || Date.current).in_time_zone
      price = FuelPrice.where("effective_at <= ?", date.end_of_day).order(effective_at: :desc).limit(1).pick(:price_per_liter).to_d

      attrs = {
        trip_id: trip.id,
        vehicle_id: trip.vehicle_id,
        driver_id: trip.driver_id,
        transaction_type: "actual_fill",
        fuel_type: "diesel",
        liters: liters,
        cost_per_liter: price,
        fueled_at: date,
        notes: "Backfilled from trip data"
      }
      attrs[:recorded_by_id] = @actor.id if FuelLog.column_names.include?("recorded_by_id")
      attrs[:funding_source] = "cash" if FuelLog.column_names.include?("funding_source")
      attrs[:omc_name] = "westport" if FuelLog.column_names.include?("omc_name")

      FuelLog.create!(attrs)
      @summary[:fuel_logs_created] += 1
    end

    def sync_driver_profiles
      User.where(role: :driver).find_each do |user|
        profile = DriverProfile.find_or_create_by!(user_id: user.id)
        @summary[:driver_profiles_created] += 1 if profile.previous_changes.key?("id")
      end
    end

    def sync_driver_scores
      period = @month&.strftime("%Y-%m")
      return if period.blank?

      DriverProfile.find_each do |profile|
        next if DriverScore.exists?(driver_profile_id: profile.id, scoring_period: period)

        created = DriverScoringService.calculate_score(profile, period_type: "monthly", period: period)
        @summary[:driver_scores_created] += 1 if created.present?
      rescue StandardError => e
        @summary[:errors] << "driver_profile ##{profile.id}: #{e.message}"
      end
    end
  end
end
