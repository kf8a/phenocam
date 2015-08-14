require 'solareventcalculator'

calc = SolarEventCalculator.new(Date.today, BigDecimal.new("42.41015"), BigDecimal.new("-85.368576"))

if calc.compute_official_sunrise('America/New_York') < DateTime.now  && DateTime.now < calc.compute_official_sunset('America/New_York') 
puts 0
end
