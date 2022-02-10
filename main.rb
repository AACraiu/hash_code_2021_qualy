require 'pry'

# - from
# - to
# - distance
# - name
$streets = []

$street_map = {}

# - array of [ street_index ]
$cars_path = []

$simulation_length = nil
$intersection_count = nil
$street_count = nil
$car_count = nil
$bonus_points = nil

def read_input
  f = File.open('input_data/d.txt', 'r')
  $simulation_length, $intersection_count, $street_count, $car_count, $bonus_points = f.readline.split.map(&:to_i)
  $streets = $street_count.times.map do
    from, to, name, distance = f.readline.split
    from = from.to_i
    to = to.to_i
    distance = distance.to_i
    {
      from:,
      to:,
      distance:,
      name:
    }
  end

  $street_map = $streets.map.with_index.to_h { |street, index| [ street[:name], index ] }
  $cars_path = $car_count.times.map do
    street_names = f.readline.split[1..]
    street_names.map { |name| $street_map[name] }
  end
end

read_input

# puts $streets
# puts "Car paths"
# puts $cars_path.map(&:to_s)

# Returns array of [ { index, duration } ]
def generate_schedule
  street_freq = $cars_path.flatten.tally
  ratio = 30

  schedule = $streets.group_by{ |street| street[:to] }.transform_values do |streets|
    streets.map do |inc_street|
      index = $street_map[inc_street[:name]]
      {
        index:,
        # duration: Math.sqrt(street_freq[index].to_i).to_i
        duration: (street_freq[index].to_i + ratio - 1) / ratio,
        # duration: (street_freq[index].to_i ** 0.3).to_i
        # duration: 1,
      }
    end
  end

  schedule.transform_values! do |streets|
    streets.select { |inc_street| inc_street[:duration] > 0 }
  end

  # schedule.each do |key, val|
  #   schedule.delete(key) if val.size == 0
  # end

  puts schedule.values.map(&:size).select(&:positive?).count

  schedule
end

# def print_ingredients(result)
#   File.open('output.txt', 'w') do |out|
#     out.write(result.size, ' ')
#     out.write(result.join(' '), "\n")
#   end
# end

def can_pass?(car_data, street_index, intersections)
  street = $streets[street_index]
  intersection = intersections[street[:to]]

  car_data[:distance] > street[:distance] &&
  intersection[:streets][intersection[:green_index]][:index] == street_index
end

# schedule - array of [ { index, duration } ]
def simulate(schedule)
  # - path_index
  # - distance
  # - dead
  cars_data = $car_count.times.map do |index|
    path_index = 0
    street_index = $cars_path[index][0]
    distance = $streets[street_index][:distance] + $car_count - index
    {
      path_index:,
      distance:,
      dead: false
    }
  end

  # - streets
  #   - index
  #   - duration
  # - green_index: index in streets
  # - green_duration
  intersections = $intersection_count.times.map do |index|
    streets = schedule[index]
    green_index = 0
    green_duration = 0
    {
      streets:,
      green_index:,
      green_duration:
    }
  end

  # puts cars_data.map(&:to_s)
  # puts intersections.map(&:to_s)

  total_score = 0

  (1..$simulation_length).each do |current_second|
    puts "Second #{current_second} ===============================" if current_second % 1000 == 0
    # update cars
    # hash of street_index => car_index
    street_result = {}
    cars_data.each_with_index do |car_data, car_index|
      next if car_data[:dead]

      car_data[:distance] += 1
      street_index = $cars_path[car_index][car_data[:path_index]]

      # puts "Card index #{car_index} ---"
      # binding.pry if current_second == 1
      # check if at the end of last street
      if cars_data[car_index][:distance] >= $streets[street_index][:distance] &&
         street_index == $cars_path[car_index].last
        # puts "Car #{car_index} dead"
        total_score += $simulation_length - current_second + $bonus_points
        car_data[:dead] = true
      elsif can_pass?(car_data, street_index, intersections)
        best_car = street_result[street_index]
        if best_car.nil? || car_data[:distance] > cars_data[best_car][:distance]
          street_result[street_index] = car_index
        end
      end
    end
    # puts street_result
    street_result.values.each do |car_index|
      cars_data[car_index][:path_index] += 1
      cars_data[car_index][:distance] = 1
      street_index = $cars_path[car_index][cars_data[car_index][:path_index]]

      if cars_data[car_index][:distance] >= $streets[street_index][:distance] &&
         street_index == $cars_path[car_index].last
        # puts "Car #{car_index} dead"
        total_score += $simulation_length - current_second + $bonus_points
        cars_data[car_index][:dead] = true
      end
    end
    # puts cars_data.map(&:to_s)

    # update lights
    intersections.each do |intersection|
      next if intersection[:streets].empty?
      intersection[:green_duration] += 1
      if intersection[:green_duration] >= intersection[:streets][intersection[:green_index]][:duration]
        intersection[:green_duration] = 0
        intersection[:green_index] = (intersection[:green_index] + 1) % intersection[:streets].size
      end
    end
  end

  dead_count = cars_data.select{ |x| x[:dead] }.count
  puts "Dead count: #{dead_count}"

  total_score
end

schedule = generate_schedule
puts "Schedule size: #{schedule.to_s.size}"

score = simulate(schedule)

puts "Score: #{score}"
puts "Schedule size: #{schedule.size}"
