require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  phone_number.to_s.delete!('^0-9')
  return phone_number[1..] if phone_number.length == 11 && phone_number[0] == '1'
  return phone_number if phone_number.length == 10

  'This phone number is not vaild'
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def peak_registration_hours(datetimes)
  time_periods = {
    0 => '0-3',
    1 => '4-7',
    2 => '8-11',
    3 => '12-15',
    4 => '16-19',
    5 => '20-23'
  }
  
  registration_hours = datetimes.each_with_object(Hash.new(0)) do |datetime, count_hash|
    count_hash[time_periods[(datetime.hour / 4).floor]] += 1
  end
end

puts 'Event Manager Initialized'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

datetimes = []

template_letter = File.read('form_letter.html.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone_number = clean_phone_number(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])
  datetimes.push Time.strptime(row[:regdate], '%m/%d/%y %H:%M')
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

puts peak_registration_hours(datetimes)
