require "csv"

module Reports
  class WorkbookExportService
    REPORTING_OBLIGATIONS = [
      {
        item: "Security perfection",
        evidence: "Registry confirmations",
        responsible: "OPDF",
        timeline: "10th",
        timing_rule: "Monthly",
        clause_reference: "Schedule 2B"
      },
      {
        item: "Debt service payments",
        evidence: "Bank confirmations and payment evidence",
        responsible: "OPDF",
        timeline: "12th",
        timing_rule: "Monthly",
        clause_reference: "Clause 7.2, 7.3, 7.8"
      },
      {
        item: "Reporting obligations",
        evidence: "Monthly report pack",
        responsible: "Consmas",
        timeline: "Monthly",
        timing_rule: "Monthly",
        clause_reference: "Schedule 2B item 3"
      },
      {
        item: "Fleet deployment",
        evidence: "Fleet deployment report",
        responsible: "Consmas",
        timeline: "Monthly",
        timing_rule: "Within 60 days and monthly updates",
        clause_reference: "Schedule 2B item 5"
      },
      {
        item: "Maintenance compliance",
        evidence: "Maintenance logs and service reports",
        responsible: "Consmas",
        timeline: "Monthly",
        timing_rule: "Ongoing",
        clause_reference: "Schedule 2B item 1"
      }
    ].freeze

    REGIME_HEADER = [
      "Monitoring Item", nil, "Evidence Required", "Responsible", "Timeline",
      "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
      "Timing Rule in Document", "Clause / Schedule Reference"
    ].freeze

    MASTER_TRIP_HEADER = [
      "Reporting Month", "Trip ID", "Waybill No.", "Truck ID", "Driver Name", "Cargo Type",
      "Origin", "Destination", "Expected Revenue", "Trip Start Date", "Trip Start Time",
      "Pre-Trip Inspection", "Trip End Date", "Trip End Time", "Post-Trip Inspection", "Trip Duration",
      "Fuel Purchased (Litres)", "Fuel Cost", "Fuel Used During Trip (Litres)",
      "Fuel Purchase Payment Type (Cash or Card)", "Arrival Status (Good / Minor Damage / Major Damage)",
      "Delivery Completed (Y/N)", "Delay (Y/N)", "Reason for Delay", "Incident Occurred (Y/N)", "Remarks"
    ].freeze

    FLEET_STATUS_HEADER = [
      "Reporting Month", "Truck ID", "Registration Number", "Operational Status",
      "Total Trips Completed (Month)", "Downtime (Days)", "Maintenance Conducted (Y/N)", "Maintenance Type",
      "Date of Last Service", "Next Service Due", "Issues Identified", "Remarks"
    ].freeze

    DRIVER_PERFORMANCE_HEADER = [
      "Reporting Month", "Driver", "Trips", "Distance", "Incidents", "Score", "Tier", "Trend"
    ].freeze

    INSURANCE_COMPLIANCE_HEADER = [
      "Truck ID", "Policy No", "Insurer", "Issue Date", "Expiry Date", "Road Worthiness", "Registration", "Compliance Status"
    ].freeze

    INCIDENT_DAMAGE_HEADER = [
      "Incident No", "Date", "Trip", "Vehicle", "Type", "Severity", "Status", "Estimated Cost", "Actual Cost", "Claim Status"
    ].freeze

    FABRIMETAL_PAYMENT_HEADER = [
      "Month", "Invoice No", "Amount Due", "Amount Paid", "Paid Date", "Outstanding", "Variance", "Notes"
    ].freeze

    SERVICE_KPI_HEADER = [
      "KPI", "Target", "Actual", "Variance", "RAG"
    ].freeze

    MANAGEMENT_SUMMARY_HEADER = [
      "Reporting Month", "Total Trips", "Active Trucks", "Trucks Under Maintenance",
      "Total Incidents", "Major Operational Issues", "Corrective Actions", "Outlook for Next Month"
    ].freeze

    def initialize(month:, prepared_by:)
      @month = month.beginning_of_month
      @prepared_by = prepared_by
    end

    def monitoring_workbook_xlsx
      package = Axlsx::Package.new
      wb = package.workbook

      add_master_trip_sheet(wb)
      add_fleet_status_sheet(wb)
      add_driver_performance_sheet(wb)
      add_insurance_compliance_sheet(wb)
      add_incident_damage_sheet(wb)
      add_fabrimetal_payment_sheet(wb)
      add_service_kpi_sheet(wb)
      add_management_summary_sheet(wb)

      package.to_stream.read
    end

    def monitoring_workbook_payload
      checklist = REPORTING_OBLIGATIONS.map do |item|
        {
          monitoring_item: item[:item],
          evidence_required: item[:evidence],
          responsible: item[:responsible],
          timeline: item[:timeline],
          status: checklist_status_for(item),
          timing_rule: item[:timing_rule],
          clause_reference: item[:clause_reference]
        }
      end

      missing_count = checklist.count { |row| row[:status] != "Submitted" }
      readiness = checklist.empty? ? 100.0 : (((checklist.size - missing_count).to_d / checklist.size) * 100).round(1)

      {
        generated_at: Time.current.iso8601,
        reporting_month: @month.strftime("%Y-%m"),
        prepared_by: @prepared_by,
        submission_readiness_pct: readiness,
        missing_evidence_count: missing_count,
        critical_exceptions: scoped_incidents.where(severity: "critical").count,
        validation_warnings: build_validation_warnings(checklist, missing_count),
        checklist: checklist,
        tab_headers: tab_headers,
        tabs: {
          master_trip_operations: master_trip_rows,
          fleet_status: fleet_status_rows,
          driver_performance: driver_performance_rows,
          insurance_compliance: insurance_compliance_rows,
          incident_damage_register: incident_damage_rows,
          fabrimetal_payment_monitoring: fabrimetal_payment_rows,
          service_kpis_monitor: service_kpi_rows,
          management_summary: management_summary_rows
        }
      }
    end

    def reporting_regime_payload
      {
        generated_at: Time.current.iso8601,
        reporting_year: @month.year,
        prepared_by: @prepared_by,
        rows: REPORTING_OBLIGATIONS.map { |item| reporting_row(item) }
      }
    end

    def budget_workbook_payload
      {
        generated_at: Time.current.iso8601,
        reporting_month: @month.strftime("%Y-%m"),
        prepared_by: @prepared_by,
        tab_headers: {
          revenue_breakdown: ["Budget Item", "Number of Trips", "Rate Per Trip", "Amount (GHS)"],
          monthly_budget: ["Budget Item", "Amount (GHS)", "Remarks"]
        },
        revenue_breakdown_rows: revenue_breakdown_rows,
        monthly_budget_rows: monthly_budget_rows
      }
    end

    def reporting_regime_xlsx
      package = Axlsx::Package.new
      wb = package.workbook

      wb.add_worksheet(name: "Reporting") do |sheet|
        sheet.add_row(["Monthly Monitoring Checklist — Consmas Vehicle & Asset Facility"])
        sheet.add_row([])
        sheet.add_row([nil, nil, nil, nil, nil, @month.year.to_s])
        sheet.add_row(REGIME_HEADER)
        REPORTING_OBLIGATIONS.each do |item|
          sheet.add_row(reporting_row(item))
        end
      end

      package.to_stream.read
    end

    def budget_workbook_xlsx
      package = Axlsx::Package.new
      wb = package.workbook

      add_revenue_breakdown_sheet(wb)
      add_monthly_budget_sheet(wb)

      package.to_stream.read
    end

    def monitoring_workbook_csv(sheet_key: "master_trip_operations")
      rows = csv_rows_for(sheet_key)
      CSV.generate do |csv|
        rows.each { |row| csv << row }
      end
    end

    private

    def month_range
      @month.beginning_of_month..@month.end_of_month.end_of_day
    end

    def scoped_trips
      Trip.includes(:driver, :vehicle, :pre_trip_inspection, :fuel_logs, :incidents)
          .where("(trips.trip_date BETWEEN ? AND ?) OR (trips.trip_date IS NULL AND trips.created_at BETWEEN ? AND ?)",
                 @month.to_date, @month.end_of_month.to_date, month_range.begin, month_range.end)
    end

    def scoped_expenses
      ExpenseEntry.active
                  .left_joins(:trip)
                  .where(
                    "(expense_entries.expense_date BETWEEN ? AND ?) OR (trips.trip_date BETWEEN ? AND ?)",
                    month_range.begin, month_range.end, @month.to_date, @month.end_of_month.to_date
                  )
                  .distinct
    end

    def scoped_incidents
      Incident.where(incident_date: month_range)
    end

    def reporting_month_label
      @month.strftime("%b %Y")
    end

    def generated_meta
      ["Generated At: #{Time.current.iso8601}", "Reporting Month: #{reporting_month_label}", "Prepared By: #{@prepared_by}"]
    end

    def master_trip_rows
      scoped_trips.order(:trip_date, :id).map do |trip|
        start_timestamp = trip_start_timestamp(trip)
        end_timestamp = trip_end_timestamp(trip)
        fuel_litres = trip_fuel_purchased_litres(trip)
        fuel_cost = trip_fuel_cost(trip, fuel_litres)
        delay = trip_delayed?(trip, end_timestamp)
        incident_occurred = trip.incidents.any? || trip.notes_incidents.present?

        [
          reporting_month_label,
          trip.id,
          trip.waybill_number || trip.reference_code,
          trip.vehicle&.license_plate || trip.truck_reg_no,
          trip.driver&.name,
          trip.material_description,
          trip.pickup_location,
          trip.destination.presence || trip.dropoff_location,
          destination_revenue_rate(trip.destination.presence || trip.dropoff_location),
          start_timestamp&.to_date,
          start_timestamp&.strftime("%H:%M"),
          trip.pre_trip_inspection.present? ? "Yes" : "No",
          end_timestamp&.to_date,
          end_timestamp&.strftime("%H:%M"),
          post_trip_inspection_status(trip),
          format_trip_duration(start_timestamp, end_timestamp),
          fuel_litres,
          fuel_cost,
          trip_fuel_used_litres(trip, fuel_litres),
          fuel_payment_type_label(trip),
          arrival_status_label(trip),
          trip.status_completed? ? "Y" : "N",
          delay ? "Y" : "N",
          delay ? trip.notes_incidents.presence || trip.dropoff_notes.presence || "Not specified" : nil,
          incident_occurred ? "Y" : "N",
          trip.notes_incidents.presence || trip.dropoff_notes.presence || trip.special_instructions
        ]
      end
    end

    def add_master_trip_sheet(wb)
      wb.add_worksheet(name: "Master Trip Operations Table") do |sheet|
        sheet.add_row(master_trip_header)
        master_trip_rows.each { |row| sheet.add_row(row) }
        sheet.add_row([])
        sheet.add_row(generated_meta)
      end
    end

    def master_trip_header
      MASTER_TRIP_HEADER
    end

    def add_fleet_status_sheet(wb)
      wb.add_worksheet(name: "Fleet Status (Monthly)") do |sheet|
        sheet.add_row(FLEET_STATUS_HEADER)

        fleet_status_rows.each { |row| sheet.add_row(row) }
      end
    end

    def add_driver_performance_sheet(wb)
      wb.add_worksheet(name: "Driver Performance (Monthly)") do |sheet|
        sheet.add_row(DRIVER_PERFORMANCE_HEADER)

        driver_performance_rows.each { |row| sheet.add_row(row) }
      end
    end

    def add_insurance_compliance_sheet(wb)
      wb.add_worksheet(name: "Insurance & Compliance Tracker") do |sheet|
        sheet.add_row(INSURANCE_COMPLIANCE_HEADER)

        insurance_compliance_rows.each { |row| sheet.add_row(row) }
      end
    end

    def add_incident_damage_sheet(wb)
      wb.add_worksheet(name: "Incident & Damage Register") do |sheet|
        sheet.add_row(INCIDENT_DAMAGE_HEADER)

        incident_damage_rows.each { |row| sheet.add_row(row) }
      end
    end

    def add_fabrimetal_payment_sheet(wb)
      wb.add_worksheet(name: "Fabrimetal Payment Monitoring") do |sheet|
        sheet.add_row(FABRIMETAL_PAYMENT_HEADER)

        fabrimetal_payment_rows.each { |row| sheet.add_row(row) }
      end
    end

    def add_service_kpi_sheet(wb)
      wb.add_worksheet(name: "Service KPIs Monitor") do |sheet|
        sheet.add_row(SERVICE_KPI_HEADER)

        service_kpi_rows.each { |row| sheet.add_row(row) }
      end
    end

    def add_management_summary_sheet(wb)
      wb.add_worksheet(name: "Management Summary") do |sheet|
        sheet.add_row(MANAGEMENT_SUMMARY_HEADER)
        management_summary_rows.each { |row| sheet.add_row(row) }
      end
    end

    def add_revenue_breakdown_sheet(wb)
      wb.add_worksheet(name: "Revenue Breakdown") do |sheet|
        sheet.add_row([nil, "Consmas Supply Chain Solutions Ltd"])
        sheet.add_row([nil, "Revenue Breakdow - (#{@month.strftime('%b')}) #{@month.year}"])
        sheet.add_row([])
        sheet.add_row([nil, "Budget Item", "Number of Trips", "Rate Per Trip", "Amount (GHS)"])

        revenue_breakdown_rows.each { |row| sheet.add_row(row) }
      end
    end

    def add_monthly_budget_sheet(wb)
      wb.add_worksheet(name: "Monthly Budget") do |sheet|
        sheet.add_row([nil, "Consmas Supply Chain Solutions Ltd"])
        sheet.add_row([nil, "Fleet Operations Budget - (#{@month.strftime('%b')}) #{@month.year}"])
        sheet.add_row([])
        sheet.add_row([nil, "Budget Item", "Amount (GHS)", "Remarks"])

        budget_rows = [
          ["Regulatory and statutory expenses (insurance, road worthiness certification, licenses)", :insurance],
          ["Fuel", :fuel],
          ["Road expenses", :road_expenses],
          ["Maintenance fees and overheads", :repairs_maintenance],
          ["Tax obligations relating to the Assets", :taxes_levies],
          ["Fleet staff costs", :fleet_staff_costs],
          ["Bank charges", :bank_charges],
          ["Other overheads", :other_overheads]
        ]

        monthly_budget_rows.each { |row| sheet.add_row(row) }
      end
    end

    def reporting_row(item)
      statuses = Array.new(12) { "Not Submitted" }
      [
        item[:item],
        nil,
        item[:evidence],
        item[:responsible],
        item[:timeline],
        *statuses,
        item[:timing_rule],
        item[:clause_reference]
      ]
    end

    def csv_rows_for(sheet_key)
      case sheet_key
      when "master_trip_operations"
        [master_trip_header] + master_trip_rows
      when "fleet_status"
        [FLEET_STATUS_HEADER] + fleet_status_rows
      when "driver_performance"
        [DRIVER_PERFORMANCE_HEADER] + driver_performance_rows
      when "insurance_compliance"
        [INSURANCE_COMPLIANCE_HEADER] + insurance_compliance_rows
      when "incident_damage_register"
        [INCIDENT_DAMAGE_HEADER] + incident_damage_rows
      when "fabrimetal_payment_monitoring"
        [FABRIMETAL_PAYMENT_HEADER] + fabrimetal_payment_rows
      when "service_kpis_monitor"
        [SERVICE_KPI_HEADER] + service_kpi_rows
      when "management_summary"
        [MANAGEMENT_SUMMARY_HEADER] + management_summary_rows
      else
        [master_trip_header] + master_trip_rows
      end
    end

    def tab_headers
      {
        master_trip_operations: MASTER_TRIP_HEADER,
        fleet_status: FLEET_STATUS_HEADER,
        driver_performance: DRIVER_PERFORMANCE_HEADER,
        insurance_compliance: INSURANCE_COMPLIANCE_HEADER,
        incident_damage_register: INCIDENT_DAMAGE_HEADER,
        fabrimetal_payment_monitoring: FABRIMETAL_PAYMENT_HEADER,
        service_kpis_monitor: SERVICE_KPI_HEADER,
        management_summary: MANAGEMENT_SUMMARY_HEADER
      }
    end

    def fleet_status_rows
      Vehicle.order(:id).map do |vehicle|
        trips = scoped_trips.where(vehicle_id: vehicle.id)
        work_orders = WorkOrder.where(vehicle_id: vehicle.id).where("created_at BETWEEN ? AND ?", month_range.begin, month_range.end)
        completed_work_orders = work_orders.where(status: "completed")
        open_work_orders = work_orders.where.not(status: %w[completed cancelled])
        downtime_days = completed_work_orders.sum(:downtime_hours).to_d / 24

        op_status =
          if open_work_orders.exists?
            "Under Maintenance"
          elsif vehicle.active?
            "Operational"
          else
            "Grounded"
          end

        [
          reporting_month_label,
          vehicle.id,
          vehicle.license_plate,
          op_status,
          trips.where(status: :completed).count,
          downtime_days.round(2),
          completed_work_orders.exists? ? "Y" : "N",
          completed_work_orders.group(:work_order_type).order(Arel.sql("COUNT(*) DESC")).count.keys.first,
          completed_work_orders.maximum(:completed_at)&.to_date,
          vehicle.maintenance_schedules.active.minimum(:next_due_at)&.to_date,
          open_work_orders.limit(2).pluck(:title).join(" | "),
          nil
        ]
      end
    end

    def driver_performance_rows
      User.where(role: :driver).order(:id).map do |driver|
        trips = scoped_trips.where(driver_id: driver.id)
        incidents = scoped_incidents.where(driver_id: driver.id)
        profile = DriverProfile.find_by(user_id: driver.id)
        score = profile&.driver_scores&.where(period_type: "monthly")
                       &.where(scoring_period: @month.to_date..@month.end_of_month.to_date)
                       &.order(scoring_period: :desc)&.first || profile&.driver_scores&.where(period_type: "monthly")&.order(scoring_period: :desc)&.first

        [
          reporting_month_label,
          driver.name,
          trips.where(status: :completed).count,
          trips.sum(:distance_km).to_d.round(2),
          incidents.count,
          score&.overall_score&.to_d,
          profile&.score_tier&.to_s&.titleize,
          score&.trend&.to_s&.titleize
        ]
      end
    end

    def insurance_compliance_rows
      Vehicle.order(:id).map do |vehicle|
        roadworthiness = vehicle.vehicle_documents.where(document_type: "roadworthiness").order(expires_at: :desc).first
        registration = vehicle.vehicle_documents.where(document_type: "registration").order(expires_at: :desc).first
        compliance_status = insurance_compliance_status(vehicle, roadworthiness, registration)

        [
          vehicle.id,
          vehicle.insurance_policy_number,
          vehicle.insurance_provider,
          vehicle.insurance_issued_at,
          vehicle.insurance_expires_at,
          roadworthiness&.expires_at.present? && roadworthiness.expires_at >= Date.current ? "Valid" : "Expired/Unknown",
          registration&.expires_at.present? && registration.expires_at >= Date.current ? "Valid" : "Expired/Unknown",
          compliance_status
        ]
      end
    end

    def incident_damage_rows
      scoped_incidents.order(:incident_date, :id).map do |incident|
        claim = InsuranceClaim.find_by(incident_id: incident.id)
        [
          incident.incident_number,
          incident.incident_date&.to_date,
          incident.trip_id,
          incident.vehicle&.license_plate || incident.vehicle_id,
          incident.incident_type,
          incident.severity,
          incident.status,
          incident.estimated_damage_cost.to_d,
          incident.actual_damage_cost.to_d,
          claim&.status || "N/A"
        ]
      end
    end

    def fabrimetal_payment_rows
      Invoice.joins(:client)
             .where("clients.name ILIKE ?", "%fabrimetal%")
             .where("issued_date BETWEEN ? AND ?", @month.to_date, @month.end_of_month.to_date)
             .map do |invoice|
        payment_received_date = invoice.status == "paid" ? invoice.updated_at.to_date : nil
        variance = invoice.amount_paid.to_d - invoice.total_amount.to_d
        [
          reporting_month_label,
          invoice.invoice_number,
          invoice.total_amount.to_d,
          invoice.amount_paid.to_d,
          payment_received_date,
          invoice.balance_due.to_d,
          variance,
          invoice.notes
        ]
      end
    end

    def service_kpi_rows
      trips = scoped_trips
      incidents = scoped_incidents
      on_time_breaches = trips.where(status: :completed).where("completed_at IS NOT NULL AND scheduled_dropoff_at IS NOT NULL AND completed_at > scheduled_dropoff_at").order(:completed_at)
      failed_deliveries = trips.where(status: :cancelled).order(:updated_at)
      complaint_breaches = incidents.where("incident_type ILIKE ?", "%complaint%").order(:incident_date)
      response_breaches = incidents.where(
        "(metadata->>'response_time_hours') ~ '^[0-9]+(\\.[0-9]+)?$' AND CAST(metadata->>'response_time_hours' AS DECIMAL) > 2"
      )
      vehicle_condition_breaches = trips.where(vehicle_condition_post_trip: Trip.vehicle_condition_post_trips[:damaged]).order(:updated_at)

      [
        kpi_row("On-time Delivery Breaches", 0, on_time_breaches.count),
        kpi_row("Customer Complaint Breaches", 0, complaint_breaches.count),
        kpi_row("Failed Deliveries", 0, failed_deliveries.count),
        kpi_row("Breakdown Response >2hrs", 0, response_breaches.count),
        kpi_row("Vehicle Condition Breaches", 0, vehicle_condition_breaches.count)
      ]
    end

    def management_summary_rows
      trips = scoped_trips
      incidents = scoped_incidents
      active_trucks = trips.select(:vehicle_id).distinct.count
      under_maintenance = WorkOrder.where(status: %w[open in_progress on_hold]).where("created_at <= ?", month_range.end).distinct.count(:vehicle_id)

      [[
        reporting_month_label,
        trips.count,
        active_trucks,
        under_maintenance,
        incidents.count,
        incidents.where(severity: %w[high critical]).limit(3).pluck(:title).join(" | "),
        incidents.where.not(corrective_actions: [nil, ""]).limit(3).pluck(:corrective_actions).join(" | "),
        nil
      ]]
    end

    def trip_start_timestamp(trip)
      trip.scheduled_pickup_at || trip.trip_date&.in_time_zone
    end

    def trip_end_timestamp(trip)
      trip.completed_at || trip.scheduled_dropoff_at
    end

    def post_trip_inspection_status(trip)
      trip.post_trip_inspector_name.present? || trip.end_odometer_captured_at.present? ? "Yes" : "No"
    end

    def format_trip_duration(start_timestamp, end_timestamp)
      return nil if start_timestamp.blank? || end_timestamp.blank?
      return nil if end_timestamp < start_timestamp

      total_minutes = ((end_timestamp - start_timestamp) / 60).to_i
      hours = total_minutes / 60
      minutes = total_minutes % 60
      "#{hours}h #{minutes}m"
    end

    def trip_fuel_purchased_litres(trip)
      liters = trip.fuel_litres_filled.to_d
      liters = trip.fuel_logs.sum { |log| log.liters.to_d } if liters.zero?
      liters
    end

    def trip_fuel_cost(trip, fuel_litres)
      from_logs = trip.fuel_logs.sum { |log| log.total_cost.to_d }
      return from_logs if from_logs.positive?

      return 0.to_d if fuel_litres.to_d.zero?

      fuel_litres.to_d * effective_fuel_price_for(trip_start_timestamp(trip))
    end

    def trip_fuel_used_litres(trip, fuel_litres)
      allocated = trip.fuel_allocated_litres.to_d
      return allocated if allocated.positive?

      fuel_litres.to_d
    end

    def fuel_payment_type_label(trip)
      return "Cash" if trip.fuel_payment_mode_cash?

      "Card"
    end

    def arrival_status_label(trip)
      case trip.vehicle_condition_post_trip
      when "good" then "Good"
      when "requires_service" then "Minor Damage"
      when "damaged" then "Major Damage"
      else "Good"
      end
    end

    def trip_delayed?(trip, end_timestamp)
      return false if end_timestamp.blank? || trip.scheduled_dropoff_at.blank?

      end_timestamp > trip.scheduled_dropoff_at
    end

    def effective_fuel_price_for(timestamp)
      price_date = (timestamp || @month).to_date
      @effective_fuel_price_cache ||= {}
      return @effective_fuel_price_cache[price_date] if @effective_fuel_price_cache.key?(price_date)

      price = FuelPrice.where("effective_at <= ?", price_date.end_of_day).order(effective_at: :desc).limit(1).pick(:price_per_liter).to_d
      @effective_fuel_price_cache[price_date] = price
    end

    def insurance_compliance_status(vehicle, roadworthiness, registration)
      insurance_valid = vehicle.insurance_expires_at.present? && vehicle.insurance_expires_at >= Date.current
      road_valid = roadworthiness&.expires_at.present? && roadworthiness.expires_at >= Date.current
      registration_valid = registration&.expires_at.present? && registration.expires_at >= Date.current
      return "Compliant" if insurance_valid && road_valid && registration_valid

      "Attention Required"
    end

    def kpi_row(label, target, actual)
      variance = actual.to_i - target.to_i
      [label, target, actual, variance, rag_status_for_kpi(variance)]
    end

    def rag_status_for_kpi(variance)
      return "Green" if variance <= 0
      return "Amber" if variance <= 2

      "Red"
    end

    def revenue_breakdown_rows
      rows = []
      grouped = scoped_trips.group(:destination).pluck(:destination)
      totals = { trips: 0, amount: 0.to_d }
      grouped.each do |destination|
        trips = scoped_trips.where(destination: destination)
        count = trips.count
        rate = destination_revenue_rate(destination)
        amount = (rate * count).to_d
        totals[:trips] += count
        totals[:amount] += amount
        rows << [nil, destination.presence || "Unspecified", count, rate, amount]
      end
      rows << [nil, "Total:", totals[:trips], nil, totals[:amount]]
      rows
    end

    def destination_revenue_rate(destination_name)
      dest_str = destination_name.to_s.strip
      return 0.to_d if dest_str.blank?

      @destination_rates_cache ||= Destination.where(active: true).pluck(:name, :base_trip_cost).each_with_object({}) do |(name, cost), h|
        h[name.to_s.downcase] = cost.to_d
      end

      rate = @destination_rates_cache[dest_str.downcase]
      return rate if rate&.positive?

      @destination_rates_cache.each do |key, value|
        return value if dest_str.downcase.include?(key) || key.include?(dest_str.downcase)
      end

      0.to_d
    end

    def monthly_budget_rows
      budget_rows = [
        ["Regulatory and statutory expenses (insurance, road worthiness certification, licenses)", :insurance],
        ["Fuel", :fuel],
        ["Road expenses", :road_expenses],
        ["Maintenance fees and overheads", :repairs_maintenance],
        ["Tax obligations relating to the Assets", :taxes_levies],
        ["Fleet staff costs", :fleet_staff_costs],
        ["Bank charges", :bank_charges],
        ["Other overheads", :other_overheads]
      ]
      budget_rows.map do |label, category|
        amount = scoped_expenses.where(category: category).sum(:amount).to_d
        [nil, label, amount, nil]
      end
    end

    def checklist_status_for(item)
      case item[:item]
      when "Reporting obligations"
        scoped_trips.exists? ? "Submitted" : "Not Submitted"
      when "Maintenance compliance"
        WorkOrder.where(status: "completed").where("completed_at BETWEEN ? AND ?", month_range.begin, month_range.end).exists? ? "Submitted" : "Not Submitted"
      when "Fleet deployment"
        scoped_trips.exists? ? "Submitted" : "Not Submitted"
      else
        "Not Submitted"
      end
    end

    def build_validation_warnings(checklist, missing_count)
      warnings = []
      warnings << "#{missing_count} checklist domains are not submitted." if missing_count.positive?
      missing_driver_docs = DriverDocument.where(status: "active").where("expires_at <= ?", 30.days.from_now.to_date).count
      warnings << "Driver compliance evidence is missing or incomplete." if missing_driver_docs.positive?
      warnings
    end
  end
end
