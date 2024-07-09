package spacelift

# Warn if changes that will cause the monthly cost to go above a certain threshold
warn[sprintf("monthly cost greater than $%d ($%.2f)", [threshold, monthly_cost])] {
  threshold := 100
  monthly_cost := to_number(input.third_party_metadata.infracost.projects[0].breakdown.totalMonthlyCost)
  monthly_cost > threshold
}

# Warn if the monthly costs increase more than a certain percentage
warn[sprintf("monthly cost increase greater than %d%% (%.2f%%)", [threshold, percentage_increase])] {
  threshold := 5
  previous_cost := to_number(input.third_party_metadata.infracost.projects[0].pastBreakdown.totalMonthlyCost)
  previous_cost > 0

  monthly_cost := to_number(input.third_party_metadata.infracost.projects[0].breakdown.totalMonthlyCost)
  percentage_increase := ((monthly_cost - previous_cost) / previous_cost) * 100

  percentage_increase > threshold
}