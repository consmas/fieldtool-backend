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
      Trip.includes(:driver, :vehicle, :pre_trip_inspection)
          .where("(trip_date BETWEEN ? AND ?) OR (trip_date IS NULL AND created_at BETWEEN ? AND ?)",
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
        [
          reporting_month_label,
          trip.id,
          trip.waybill_number || trip.reference_code,
          trip.vehicle&.license_plate || trip.truck_reg_no,
          trip.driver&.name,
          trip.material_description,
          trip.pickup_location,
          trip.destination.presence || trip.dropoff_location,
          trip.road_expense_disbursed.to_d,
          trip.trip_date,
          trip.scheduled_pickup_at&.strftime("%H:%M"),
          trip.pre_trip_inspection.present? ? "Yes" : "No",
          trip.completed_at&.to_date,
          trip.completed_at&.strftime("%H:%M"),
          trip.vehicle_condition_post_trip
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
      [
        "Reporting Month", "Trip ID", "Waybill No.", "Truck ID", "Driver Name", "Cargo Type",
        "Origin", "Destination", "Expected Revenue ", "Trip Start Date", "Trip Start Time",
        "Pre-Trip Inspection", "Trip End Date", "Trip End Time", "Post-Trip inspection"
      ]
    end

    def add_fleet_status_sheet(wb)
      wb.add_worksheet(name: "Fleet Status (Monthly)") do |sheet|
        sheet.add_row([
          "Reporting Month", "Truck ID", "Registration Number", "Operational Status (Operational / Under Maintenance / Grounded)",
          "Total Trips Completed (Month)", "Downtime (Days)", "Maintenance Conducted (Y/N)", "Maintenance Type",
          "Date of Last Service", "Next Service Due", "Issues Identified", "Remarks"
        ])

        Vehicle.order(:id).find_each do |vehicle|
          trips = scoped_trips.where(vehicle_id: vehicle.id)
          work_orders = WorkOrder.where(vehicle_id: vehicle.id)
                                 .where("created_at BETWEEN ? AND ?", month_range.begin, month_range.end)
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

          sheet.add_row([
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
          ])
        end
      end
    end

    def add_driver_performance_sheet(wb)
      wb.add_worksheet(name: "Driver Performance (Monthly)") do |sheet|
        sheet.add_row([
          "Reporting Month", "Driver Name", "Assigned Truck", "Trips Completed", "Incidents Recorded",
          "Safety Breaches", "Training Conducted (Y/N)", "Training Type", "Remarks"
        ])

        User.where(role: :driver).order(:id).find_each do |driver|
          trips = scoped_trips.where(driver_id: driver.id)
          incidents = scoped_incidents.where(driver_id: driver.id)
          sheet.add_row([
            reporting_month_label,
            driver.name,
            trips.joins(:vehicle).group("vehicles.license_plate").order(Arel.sql("COUNT(*) DESC")).count.keys.first,
            trips.where(status: :completed).count,
            incidents.count,
            incidents.where(severity: %w[high critical]).count,
            "N",
            nil,
            nil
          ])
        end
      end
    end

    def add_insurance_compliance_sheet(wb)
      wb.add_worksheet(name: "Insurance & Compliance Tracker") do |sheet|
        sheet.add_row([
          "Reporting Month", "Truck ID", "Insurance Provider", "Policy Number", "Coverage Type", "Policy Start Date",
          "Policy Expiry Date", "Renewal Status", "Roadworthiness Status", "Driver Licence Validity", "Remarks"
        ])

        Vehicle.order(:id).find_each do |vehicle|
          roadworthiness = vehicle.vehicle_documents.where(document_type: "roadworthiness").order(expires_at: :desc).first
          registration = vehicle.vehicle_documents.where(document_type: "registration").order(expires_at: :desc).first
          driver_license_validity = DriverProfile.joins(:user)
                                                .where(user_id: scoped_trips.where(vehicle_id: vehicle.id).select(:driver_id))
                                                .maximum(:license_expires_at)

          renewal_status = if vehicle.insurance_expires_at.blank?
                             "Unknown"
                           elsif vehicle.insurance_expires_at < Date.current
                             "Expired"
                           elsif vehicle.insurance_expires_at <= 30.days.from_now.to_date
                             "Due Soon"
                           else
                             "Active"
                           end

          sheet.add_row([
            reporting_month_label,
            vehicle.id,
            vehicle.insurance_provider,
            vehicle.insurance_policy_number,
            vehicle.kind,
            vehicle.insurance_issued_at,
            vehicle.insurance_expires_at,
            renewal_status,
            roadworthiness&.expires_at.present? && roadworthiness.expires_at >= Date.current ? "Valid" : "Expired/Unknown",
            driver_license_validity,
            registration&.document_number
          ])
        end
      end
    end

    def add_incident_damage_sheet(wb)
      wb.add_worksheet(name: "Incident & Damage Register") do |sheet|
        sheet.add_row([
          "Reporting Month", "Date", "Truck ID", "Trip ID", "Driver Name", "Incident Type", "Description",
          "Damage Level", "Insurance Notified (Y/N)", "Claim Filed (Y/N)", "Claim Status", "Corrective Action Taken", "Remarks"
        ])

        scoped_incidents.order(:incident_date, :id).find_each do |incident|
          claim = InsuranceClaim.find_by(incident_id: incident.id)
          sheet.add_row([
            reporting_month_label,
            incident.incident_date&.to_date,
            incident.vehicle&.license_plate || incident.vehicle_id,
            incident.trip_id,
            incident.driver&.name,
            incident.incident_type,
            incident.description,
            incident.severity,
            claim.present? ? "Y" : "N",
            claim&.filed_at.present? ? "Y" : "N",
            claim&.status,
            incident.corrective_actions,
            incident.closure_notes
          ])
        end
      end
    end

    def add_fabrimetal_payment_sheet(wb)
      wb.add_worksheet(name: "Fabrimetal Payment Monitoring") do |sheet|
        sheet.add_row([
          "Month", "Invoice Sent Date", "Amount Invoiced", "Fabrimetal Received Invoice Date",
          "Payment Due Date (5 working days)", "Payment Received Date", "Amount Paid", "Fully Paid (Y/N)",
          "30-Day Interest Trigger Date", "Late? (Y/N)", "Notes"
        ])

        invoices = Invoice.joins(:client)
                          .where("clients.name ILIKE ?", "%fabrimetal%")
                          .where("issued_date BETWEEN ? AND ?", @month.to_date, @month.end_of_month.to_date)
        invoices.find_each do |invoice|
          payment_received_date = invoice.status == "paid" ? invoice.updated_at.to_date : nil
          due_date = invoice.due_date || (invoice.issued_date && (invoice.issued_date + 7.days))
          sheet.add_row([
            reporting_month_label,
            invoice.issued_date,
            invoice.total_amount.to_d,
            invoice.issued_date,
            due_date,
            payment_received_date,
            invoice.amount_paid.to_d,
            invoice.balance_due.to_d.zero? ? "Y" : "N",
            due_date&.+(30.days),
            due_date.present? && payment_received_date.present? && payment_received_date > due_date ? "Y" : "N",
            invoice.notes
          ])
        end
      end
    end

    def add_service_kpi_sheet(wb)
      wb.add_worksheet(name: "Service KPIs Monitor") do |sheet|
        sheet.add_row([
          "Reporting Month", "On-Time Delivery Breaches (No.)", "Dates", "Penalty Applied",
          "Customer Complaint Breaches (No.)", "Dates", "Penalty Applied",
          "Failed Deliveries (No.)", "Dates", "Penalty Applied",
          "Breakdown Response >2hrs (No.)", "Dates", "Penalty Applied",
          "Vehicle Condition Breaches (No.)", "Dates", "Penalty Applied"
        ])

        trips = scoped_trips
        incidents = scoped_incidents
        on_time_breaches = trips.where(status: :completed).where("completed_at IS NOT NULL AND scheduled_dropoff_at IS NOT NULL AND completed_at > scheduled_dropoff_at").order(:completed_at)
        failed_deliveries = trips.where(status: :cancelled).order(:updated_at)
        complaint_breaches = incidents.where("incident_type ILIKE ?", "%complaint%").order(:incident_date)
        response_breaches = incidents.where("metadata->>'response_time_hours' IS NOT NULL AND CAST(metadata->>'response_time_hours' AS DECIMAL) > 2")
        vehicle_condition_breaches = trips.where(vehicle_condition_post_trip: Trip.vehicle_condition_post_trips[:damaged]).order(:updated_at)

        sheet.add_row([
          reporting_month_label,
          on_time_breaches.count,
          on_time_breaches.limit(5).map { |t| t.completed_at&.to_date }.compact.join(", "),
          nil,
          complaint_breaches.count,
          complaint_breaches.limit(5).map { |i| i.incident_date&.to_date }.compact.join(", "),
          nil,
          failed_deliveries.count,
          failed_deliveries.limit(5).map { |t| t.updated_at&.to_date }.compact.join(", "),
          nil,
          response_breaches.count,
          response_breaches.limit(5).map { |i| i.incident_date&.to_date }.compact.join(", "),
          nil,
          vehicle_condition_breaches.count,
          vehicle_condition_breaches.limit(5).map { |t| t.updated_at&.to_date }.compact.join(", "),
          nil
        ])
      end
    end

    def add_management_summary_sheet(wb)
      wb.add_worksheet(name: "Management Summary") do |sheet|
        trips = scoped_trips
        incidents = scoped_incidents
        active_trucks = trips.select(:vehicle_id).distinct.count
        under_maintenance = WorkOrder.where(status: %w[open in_progress on_hold])
                                     .where("created_at <= ?", month_range.end)
                                     .distinct.count(:vehicle_id)

        sheet.add_row([
          "Reporting Month", "Total Trips", "Active Trucks", "Trucks Under Maintenance",
          "Total Incidents", "Major Operational Issues", "Corrective Actions", "Outlook for Next Month"
        ])
        sheet.add_row([
          reporting_month_label,
          trips.count,
          active_trucks,
          under_maintenance,
          incidents.count,
          incidents.where(severity: %w[high critical]).limit(3).pluck(:title).join(" | "),
          incidents.where.not(corrective_actions: [nil, ""]).limit(3).pluck(:corrective_actions).join(" | "),
          nil
        ])
      end
    end

    def add_revenue_breakdown_sheet(wb)
      wb.add_worksheet(name: "Revenue Breakdown") do |sheet|
        sheet.add_row([nil, "Consmas Supply Chain Solutions Ltd"])
        sheet.add_row([nil, "Revenue Breakdow - (#{@month.strftime('%b')}) #{@month.year}"])
        sheet.add_row([])
        sheet.add_row([nil, "Budget Item", "Number of Trips", "Rate Per Trip", "Amount (GHS)"])

        grouped = scoped_trips.group(:destination).pluck(:destination)
        totals = { trips: 0, amount: 0.to_d }
        grouped.each do |destination|
          trips = scoped_trips.where(destination: destination)
          count = trips.count
          amount = trips.sum(:road_expense_disbursed).to_d
          rate = count.positive? ? (amount / count).round(2) : 0
          totals[:trips] += count
          totals[:amount] += amount
          sheet.add_row([nil, destination.presence || "Unspecified", count, rate, amount])
        end

        sheet.add_row([nil, "Total:", totals[:trips], nil, totals[:amount]])
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

        budget_rows.each do |label, category|
          amount = scoped_expenses.where(category: category).sum(:amount).to_d
          sheet.add_row([nil, label, amount, nil])
        end
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
        [["Reporting Month", "Truck ID", "Registration Number", "Operational Status", "Total Trips Completed (Month)", "Downtime (Days)", "Maintenance Conducted (Y/N)", "Maintenance Type"]]
      else
        [master_trip_header] + master_trip_rows
      end
    end
  end
end
