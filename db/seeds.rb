# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

default_escalation_rules = [
  {
    name: "Trip No Location Update",
    trigger_event: "trip.no_location_update",
    condition_type: "unread_after",
    condition_minutes: 120,
    escalate_to_role: "admin",
    escalation_channels: %w[push sms],
    escalation_priority: "critical",
    escalation_message: "ESCALATION: No location update for trip %{trip_number} for over %{time_unactioned}",
    max_escalations: 3
  },
  {
    name: "Expense Approval Pending",
    trigger_event: "expense.approval_needed",
    condition_type: "unactioned_after",
    condition_minutes: 2880,
    escalate_to_role: "admin",
    escalation_channels: %w[push email],
    escalation_priority: "high",
    escalation_message: "Expense awaiting approval for over %{time_unactioned}",
    max_escalations: 2
  },
  {
    name: "Critical Maintenance Overdue",
    trigger_event: "maintenance.overdue",
    condition_type: "unactioned_after",
    condition_minutes: 1440,
    escalate_to_role: "admin",
    escalation_channels: %w[push sms email],
    escalation_priority: "critical",
    escalation_message: "ESCALATION: Overdue maintenance for vehicle %{vehicle_reg} still unaddressed after %{time_unactioned}",
    max_escalations: 3
  },
  {
    name: "Expired Document Unresolved",
    trigger_event: "compliance.document_expired",
    condition_type: "unactioned_after",
    condition_minutes: 4320,
    escalate_to_role: "admin",
    escalation_channels: %w[sms email],
    escalation_priority: "critical",
    escalation_message: "URGENT: Expired %{document_type} unresolved for %{time_unactioned}",
    max_escalations: 2
  }
]

default_escalation_rules.each do |attrs|
  rule = EscalationRule.find_or_initialize_by(name: attrs[:name])
  rule.assign_attributes(attrs)
  rule.save!
end

ScoringConfig.default!
User.where(role: :driver).find_each do |user|
  DriverProfile.find_or_create_by!(user_id: user.id)
end
