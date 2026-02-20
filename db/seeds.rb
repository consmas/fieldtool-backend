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

compliance_requirements = [
  {
    name: "Road Worthiness Certificate",
    code: "VD-001",
    category: "vehicle_documentation",
    applies_to: "vehicle",
    enforcement_level: "mandatory",
    check_type: "document_expiry",
    check_frequency: "per_trip",
    auto_check_config: { type: "document_expiry", document_model: "VehicleDocument", document_type: "road_worthiness", warn_days_before: 30, block_trip_if_expired: true },
    regulation_reference: "Road Traffic Act 2004, Section 9",
    jurisdiction: "Ghana",
    penalty_description: "Vehicle impounded, GHS 500-2000 fine",
    priority: 1
  },
  {
    name: "Vehicle Insurance",
    code: "VD-002",
    category: "vehicle_documentation",
    applies_to: "vehicle",
    enforcement_level: "mandatory",
    check_type: "document_expiry",
    check_frequency: "per_trip",
    auto_check_config: { type: "document_expiry", document_model: "VehicleDocument", document_type: "insurance", warn_days_before: 30, block_trip_if_expired: true },
    jurisdiction: "Ghana",
    priority: 2
  },
  {
    name: "Vehicle Registration",
    code: "VD-003",
    category: "vehicle_documentation",
    applies_to: "vehicle",
    enforcement_level: "mandatory",
    check_type: "document_expiry",
    check_frequency: "per_trip",
    auto_check_config: { type: "document_expiry", document_model: "VehicleDocument", document_type: "registration", warn_days_before: 60, block_trip_if_expired: true },
    jurisdiction: "Ghana",
    priority: 3
  },
  {
    name: "Valid Driving License",
    code: "DC-001",
    category: "driver_certification",
    applies_to: "driver",
    enforcement_level: "mandatory",
    check_type: "document_expiry",
    check_frequency: "per_trip",
    auto_check_config: { type: "document_expiry", document_model: "DriverDocument", document_type: "driving_license", warn_days_before: 60, block_trip_if_expired: true },
    jurisdiction: "Ghana",
    priority: 10
  },
  {
    name: "Medical Fitness Certificate",
    code: "DC-002",
    category: "driver_certification",
    applies_to: "driver",
    enforcement_level: "mandatory",
    check_type: "document_expiry",
    check_frequency: "annually",
    auto_check_config: { type: "document_expiry", document_model: "DriverDocument", document_type: "medical_fitness_certificate", warn_days_before: 30, block_trip_if_expired: true },
    jurisdiction: "Ghana",
    priority: 11
  },
  {
    name: "Axle Weight Limit",
    code: "LC-001",
    category: "load_compliance",
    applies_to: "trip",
    enforcement_level: "mandatory",
    check_type: "threshold",
    check_frequency: "per_trip",
    auto_check_config: { type: "threshold", field: "weight_kg", max_value: 30_000, unit: "kg", block_trip_if_exceeded: true },
    jurisdiction: "Ghana",
    priority: 20
  },
  {
    name: "Pre-Trip Inspection Completed",
    code: "OP-001",
    category: "operational",
    applies_to: "trip",
    enforcement_level: "mandatory",
    check_type: "per_trip_check",
    check_frequency: "per_trip",
    auto_check: true,
    auto_check_config: { type: "inspection_completed", block_trip_if_missing: true },
    priority: 30
  }
]

compliance_requirements.each do |attrs|
  requirement = ComplianceRequirement.find_or_initialize_by(code: attrs[:code])
  requirement.assign_attributes(attrs)
  requirement.save!
end
