class NotificationTypeRegistry
  TYPES = {
    "trip.assigned" => {
      category: "trip", priority: "high",
      title_template: "New Trip Assigned",
      body_template: "You have been assigned trip %{trip_number} from %{origin} to %{destination}",
      default_channels: { in_app: true, push: true, sms: false, email: false },
      roles: ["driver"]
    },
    "trip.started" => {
      category: "trip", priority: "normal",
      title_template: "Trip Started",
      body_template: "Trip %{trip_number} is now en route",
      default_channels: { in_app: true, push: false, sms: false, email: false },
      roles: ["dispatcher", "admin"]
    },
    "trip.completed" => {
      category: "trip", priority: "normal",
      title_template: "Trip Completed",
      body_template: "Trip %{trip_number} has been completed. Distance: %{distance_km} km",
      default_channels: { in_app: true, push: true, sms: false, email: false },
      roles: ["dispatcher", "admin"]
    },
    "expense.approval_needed" => {
      category: "expense", priority: "high",
      title_template: "Expense Awaiting Approval",
      body_template: "%{amount} expense for %{category} requires your approval",
      default_channels: { in_app: true, push: true, sms: false, email: true },
      roles: ["admin", "finance"]
    },
    "expense.approved" => {
      category: "expense", priority: "normal",
      title_template: "Expense Approved",
      body_template: "Your %{amount} expense for %{category} has been approved",
      default_channels: { in_app: true, push: true, sms: false, email: false },
      roles: ["driver"]
    },
    "expense.rejected" => {
      category: "expense", priority: "high",
      title_template: "Expense Rejected",
      body_template: "Your %{amount} expense for %{category} has been rejected. Reason: %{reason}",
      default_channels: { in_app: true, push: true, sms: false, email: true },
      roles: ["driver"]
    },
    "maintenance.due_soon" => {
      category: "maintenance", priority: "high",
      title_template: "Maintenance Due Soon",
      body_template: "%{maintenance_name} for vehicle %{vehicle_reg} is due in %{km_remaining} km or %{days_remaining} days",
      default_channels: { in_app: true, push: true, sms: false, email: true },
      roles: ["admin", "supervisor"]
    },
    "maintenance.overdue" => {
      category: "maintenance", priority: "critical",
      title_template: "Maintenance Overdue",
      body_template: "%{maintenance_name} for vehicle %{vehicle_reg} is OVERDUE",
      default_channels: { in_app: true, push: true, sms: true, email: true },
      roles: ["admin", "supervisor"]
    },
    "maintenance.work_order_created" => {
      category: "maintenance", priority: "normal",
      title_template: "New Work Order",
      body_template: "Work order %{wo_number} created for vehicle %{vehicle_reg}: %{title}",
      default_channels: { in_app: true, push: false, sms: false, email: false },
      roles: ["admin", "supervisor"]
    },
    "maintenance.work_order_completed" => {
      category: "maintenance", priority: "normal",
      title_template: "Work Order Completed",
      body_template: "Work order %{wo_number} for vehicle %{vehicle_reg} has been completed. Cost: %{cost}",
      default_channels: { in_app: true, push: true, sms: false, email: false },
      roles: ["admin", "finance"]
    },
    "compliance.document_expiring" => {
      category: "compliance", priority: "high",
      title_template: "Document Expiring Soon",
      body_template: "%{document_type} for vehicle %{vehicle_reg} expires in %{days_remaining} days",
      default_channels: { in_app: true, push: true, sms: false, email: true },
      roles: ["admin", "supervisor"]
    },
    "compliance.document_expired" => {
      category: "compliance", priority: "critical",
      title_template: "Document Expired",
      body_template: "%{document_type} for vehicle %{vehicle_reg} has EXPIRED",
      default_channels: { in_app: true, push: true, sms: true, email: true },
      roles: ["admin", "supervisor"]
    },
    "fuel.anomaly_detected" => {
      category: "alert", priority: "high",
      title_template: "Fuel Anomaly Detected",
      body_template: "Trip %{trip_number}: expected %{expected_liters}L, actual %{actual_liters}L",
      default_channels: { in_app: true, push: true, sms: false, email: true },
      roles: ["admin", "finance"]
    },
    "driver.score_published" => {
      category: "system", priority: "normal",
      title_template: "Driver Score Updated",
      body_template: "Your score is %{overall_score} (%{tier})",
      default_channels: { in_app: true, push: true, sms: false, email: false },
      roles: ["driver"]
    },
    "driver.tier_changed" => {
      category: "system", priority: "high",
      title_template: "Driver Tier Changed",
      body_template: "Your tier changed from %{old_tier} to %{new_tier}",
      default_channels: { in_app: true, push: true, sms: false, email: false },
      roles: ["driver"]
    },
    "compliance.driver_document_expiring" => {
      category: "compliance", priority: "high",
      title_template: "Driver Document Expiring",
      body_template: "%{document_type} for %{driver_name} expires in %{days_remaining} days",
      default_channels: { in_app: true, push: true, sms: false, email: true },
      roles: ["admin", "supervisor"]
    },
    "compliance.driver_document_expired" => {
      category: "compliance", priority: "critical",
      title_template: "Driver Document Expired",
      body_template: "%{document_type} for %{driver_name} has expired",
      default_channels: { in_app: true, push: true, sms: true, email: true },
      roles: ["admin", "supervisor"]
    },
    "chat.new_message" => {
      category: "chat", priority: "normal",
      title_template: "New Message",
      body_template: "%{sender_name}: %{message_preview}",
      default_channels: { in_app: true, push: true, sms: false, email: false },
      roles: ["all"]
    },
    "system.escalation" => {
      category: "alert", priority: "critical",
      title_template: "Escalation",
      body_template: "%{original_message}",
      default_channels: { in_app: true, push: true, sms: true, email: false },
      roles: ["admin"]
    }
  }.freeze

  def self.fetch(notification_type)
    TYPES[notification_type.to_s]
  end

  def self.keys
    TYPES.keys
  end
end
