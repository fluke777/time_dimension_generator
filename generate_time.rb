#

# Where is the beginning of the epoch?

#



require 'rubygems'
require 'active_support/all'
require 'pp'
require 'fastercsv'
require 'pry'
require 'fileutils'
require 'chronic'
require 'benchmark'

FileUtils::mkdir_p 'lookups'
FileUtils::mkdir_p 'table_data'

start_date = Date.new(1948, 2, 1) 
end_date = Date.new(1949, 2, 1)

PARSED_BEGINNNING_OF_YEAR = start_date.advance(:years => -1)

years = []
quarters = []
months = []
euweeks = []
usweeks = []
days = []

# INITIAL VALUES OF COUNTERS

current_date = start_date
week_of_month = 1
euweek_of_quarter = 1
usweek_of_quarter = 1
month_of_year = 1
week_of_year = 1
usweek_of_year = 1
month_of_year = 1
month_of_quarter = 1
quarter_of_year = 1
quarter_of_year_for_week = 1
quarter_of_year_for_usweek = 1

usweek_id = 0

euweek_id = 0

day_id = start_date.to_datetime.utc.to_i / 86400 + 25568

month_id = 0

quarter_id = 0

year_id = start_date.year + 1

year_for_week = nil

year_for_usweek = nil



def find_last_sun(today)

  find_last_day(today, "Sun")

end



def find_last_mon(today)

  find_last_day(today, "Mon")

end





def find_last_day(today, day)
  while today.strftime("%a") != day do
    today = today.advance :days => -1
  end
  today
end

beginning_of_usweek = find_last_sun(current_date)
beginning_of_euweek = find_last_mon(current_date)
beginning_of_month = current_date
beginning_of_quarter = current_date
beginning_of_year = current_date

first = true

def get_days_in_week(week_of_month)
  7
end

def get_days_in_month(date)
  beg_of_month = get_beginning_of_month(date)
  beg_of_next_month = beg_of_month.advance(:months => 1)
  (beg_of_next_month - beg_of_month).to_i
end

def get_days_in_quarter(date)
  beg_of_quarter = get_beginning_of_quarter(date)
  end_of_next_quarter = beg_of_quarter.advance :months => 3
  (end_of_next_quarter - beg_of_quarter).to_i
end

def get_beginning_of_month(date)
  beg_of_month = get_beginning_of_year(date)
  while beg_of_month <= date
    beg_of_month = beg_of_month.advance :months => 1
  end
  beg_of_month.advance :months => -1
end

def get_beginning_of_quarter(date)
  beg_of_year = get_beginning_of_year(date)
  beg_of_month = get_beginning_of_month(date)

  while beg_of_month >= beg_of_year
    return beg_of_month if ((beg_of_month.month - beg_of_year.month) % 3 == 0)
    beg_of_month = beg_of_month.advance(:months => -1)
  end

  fail "Failed to find beginning of quarter"
end

def get_beginning_of_year(date)
  beg_of_year = PARSED_BEGINNNING_OF_YEAR.advance(:years => -1)
  while beg_of_year <= date
    beg_of_year = beg_of_year.advance(:years => 1)
  end
  beg_of_year.advance(:years => -1)
end

def get_days_in_year(beginning_of_year)
  beginning = Date.new(beginning_of_year.year, PARSED_BEGINNNING_OF_YEAR.month, PARSED_BEGINNNING_OF_YEAR.day)
  last_year_beginning = Date.new(beginning_of_year.year + 1, PARSED_BEGINNNING_OF_YEAR.month, PARSED_BEGINNNING_OF_YEAR.day)
  last_year_beginning - beginning
end

# pp [:year_id, :current_date, :day_id, :week_of_month, :month_id, :quarter_id, :quarter_of_year]
# puts "============"

puts Benchmark.measure {
while current_date <= end_date do


  next_thursday = current_date.monday.advance :days => 3
  last_thursday = current_date.monday.advance :days => -4

  # we need to get saturday next week
  # so if it is saturday we have to get to next week 
  next_saturday = current_date.advance(:days => 2).monday.advance :days => 5
  last_saturday = current_date.advance(:days => 2).monday.advance :days => -2

  # WEEKS
  usweek_changed = current_date - beginning_of_usweek >= get_days_in_week(usweek_id)
  if usweek_changed
    beginning_of_usweek = current_date 
    usweek_id += 1
  end

  euweek_changed = current_date - beginning_of_euweek >= get_days_in_week(euweek_id)
  if euweek_changed
    beginning_of_euweek = current_date 
    euweek_id += 1
  end

  # MONTH
  month_changed = current_date - beginning_of_month >= get_days_in_month(beginning_of_month)
  if month_changed
    beginning_of_month = current_date
    month_id += 1
  end

  # EU QUARTER
  beginning_of_current_quarter = get_beginning_of_quarter(current_date)
  if get_beginning_of_quarter(next_thursday) != beginning_of_current_quarter && (beginning_of_euweek == current_date) then
    quarter_for_euweek_changed = true
  elsif get_beginning_of_quarter(last_thursday) != beginning_of_current_quarter && (beginning_of_euweek == current_date) then
    quarter_for_euweek_changed = true
  else
    quarter_for_euweek_changed = false
  end

  # US QUARTER
  if get_beginning_of_quarter(next_saturday) != beginning_of_current_quarter && (beginning_of_usweek == current_date) then
    quarter_for_usweek_changed = true
  elsif get_beginning_of_quarter(last_saturday) != beginning_of_current_quarter && (beginning_of_usweek == current_date) then
    quarter_for_usweek_changed = true
  else
    quarter_for_usweek_changed = false
  end

  quarter_changed = current_date - beginning_of_quarter >= get_days_in_quarter(beginning_of_quarter)
  if quarter_changed
    beginning_of_quarter = current_date
    quarter_id += 1
  end

  # YEAR
  # EU
  # The idea here is that the EU weeks belong to the year based on in which year is thursday
  # For example if 1st of january of year X is on tuesday, 31st of december year Y is part of 1st week in X year
  year_for_current_date = get_beginning_of_year(current_date).year
  same_year_in_future = year_for_current_date == get_beginning_of_year(next_thursday).year
  same_year_in_past = year_for_current_date == get_beginning_of_year(last_thursday).year

  # US
  # Us weeks are usually different in that the belonging og the year is 
  us_same_year_in_future = year_for_current_date == get_beginning_of_year(next_saturday).year
  us_same_year_in_past = year_for_current_date == get_beginning_of_year(last_saturday).year

  if !us_same_year_in_future && (beginning_of_usweek == current_date) then
    year_for_usweek_changed = true
  elsif !us_same_year_in_past && (beginning_of_usweek == current_date) then
    year_for_usweek_changed = true
  else
    year_for_usweek_changed = false
  end



  if !same_year_in_future && (beginning_of_euweek == current_date) then
    year_for_week_changed = true
  elsif !same_year_in_past && (beginning_of_euweek == current_date) then
    year_for_week_changed = true
  else

  year_for_week_changed = false
  end

  year_changed = current_date - beginning_of_year >= get_days_in_year(beginning_of_year)
  if year_changed
    beginning_of_year = current_date
    year_id += 1
  end

  ##########
  # RELATIVE
  day_of_week     = current_date - beginning_of_usweek + 1
  day_of_euweek   = current_date - beginning_of_euweek + 1
  day_of_month    = current_date - beginning_of_month + 1
  day_of_quarter  = current_date - beginning_of_quarter + 1
  day_of_year     = current_date - beginning_of_year + 1

  # EU WEEK IN YEAR
  if year_for_week_changed
    week_of_year = 1
    year_for_week =  year_for_week.nil? ? year_id : year_for_week += 1
  elsif euweek_changed
    week_of_year += 1
  end

  # US WEEK IN YEAR
  if year_for_usweek_changed
    usweek_of_year = 1
    year_for_usweek = year_for_usweek.nil? ? year_id : year_for_usweek += 1
  elsif usweek_changed
    usweek_of_year += 1
  end

  # EU WEEK IN QUARTER
  if quarter_for_euweek_changed
    euweek_of_quarter = 1
  elsif euweek_changed
    euweek_of_quarter += 1
  end

  # US WEEK IN QUARTER
  if quarter_for_usweek_changed
    usweek_of_quarter = 1
  elsif usweek_changed
    usweek_of_quarter += 1
  end

  # EU WEEK IN MONTH

  if month_changed

    week_of_month = 1

  elsif euweek_changed

    week_of_month += 1

  end



  # MONTH OF QUARTER

  if month_changed && quarter_changed

    month_of_quarter = 1

  elsif month_changed

    month_of_quarter += 1

  end



  # MONTH OF YEAR

  if month_changed && year_changed

    month_of_year = 1

  elsif month_changed

    month_of_year += 1

  end

  

  

  # QUARTER OF YEAR

  if quarter_changed && year_changed

    quarter_of_year = 1

  elsif quarter_changed

    quarter_of_year += 1

  end

  

  # EU QUARTER OF YEAR FOR WEEK

  if quarter_for_euweek_changed && year_for_week_changed

    quarter_of_year_for_week = 1

  elsif quarter_for_euweek_changed

    quarter_of_year_for_week += 1

  end



  # US QUARTER OF YEAR FOR WEEK

  if quarter_for_usweek_changed && year_for_usweek_changed

    quarter_of_year_for_usweek = 1

  elsif quarter_for_usweek_changed

    quarter_of_year_for_usweek += 1

  end

  



  day = {

    :current_date               => current_date,

    :day_id                     => day_id,
    :euweek_id                  => euweek_id + 1,
    :usweek_id                  => usweek_id + 1,
    :month_id                   => month_id + 1,
    :quarter_id                 => quarter_id + 1,
    :year_id                    => year_id,

    :day_of_week                => day_of_week.to_i,
    :day_of_euweek              => day_of_euweek.to_i,
    :day_of_month               => day_of_month.to_i,
    :day_of_quarter             => day_of_quarter.to_i,
    :day_of_year                => day_of_year.to_i,

    :week_of_year               => week_of_year.to_i,
    :usweek_of_year             => usweek_of_year.to_i,
    :euweek_of_quarter          => euweek_of_quarter.to_i,
    :usweek_of_quarter          => usweek_of_quarter.to_i,
    :week_of_month              => week_of_month.to_i,

    :month_of_quarter           => month_of_quarter,
    :month_of_year              => month_of_year,

    :quarter_of_year            => quarter_of_year,
    :quarter_of_year_for_week   => quarter_of_year_for_week,
    :quarter_of_year_for_usweek => quarter_of_year_for_usweek,
    :year_for_week              => year_for_week,
    :year_for_usweek            => year_for_usweek

  }

  

  # OUTPUT

  # make events so it can be driven from outside

  

  # YEARS

  years     << day if year_changed || first

  quarters  << day if quarter_changed || first

  months    << day if month_changed || first

  euweeks   << day if euweek_changed || first

  usweeks   << day if usweek_changed || first

  days      << day



  # Next Iteration

  first = false

  current_date = current_date.next

  day_id += 1

end
}






# OUTPUT 

FasterCSV.open("table_data/chef_lu_year.csv", "w") do |csv|

  csv << [:year_id, :descr_default]

  years.each do |year|

    line = []

    line << year[:year_id]

    line << "FY#{year[:year_id]}"

    csv << line

  end

end



FasterCSV.open("table_data/chef_lu_quarter.csv", "w") do |csv|

  csv << [:quarter_id, :year_id, :quarter_of_year, :descr_default]

  quarters.each do |quarter|

    line = []

    line << quarter[:quarter_id]

    line << quarter[:year_id]

    line << "#{quarter[:quarter_of_year]}"

    line << "FQ#{quarter[:quarter_of_year]}/#{quarter[:year_id]}"

    csv << line

  end

end





bulgarian_constant = get_beginning_of_year(Date.today).month - get_beginning_of_year(Date.today).beginning_of_year.month - 1



FasterCSV.open("table_data/chef_lu_month.csv", "w") do |csv|

  csv << [:month_id, :year_id, :month_of_year, :quarter_id, :quarter_of_year, :month_of_quarter, :descr_default, :desc_num, :desc_us_long]

  months.each do |month|

    line = []

    line << month[:month_id]

    line << month[:year_id]

    line << month[:month_of_year]

    line << month[:quarter_id]

    line << month[:quarter_of_year]

    line << month[:month_of_quarter]

    line << "#{Date::ABBR_MONTHNAMES[(month[:month_of_year] + bulgarian_constant) % 12 + 1]} #{month[:year_id]}"

    line << "#{month[:month_of_year]}/#{month[:year_id]}"

    line << "#{Date::MONTHNAMES[(month[:month_of_year] + bulgarian_constant) % 12 + 1] } #{month[:year_id]}"

    csv << line

  end

end



FasterCSV.open("table_data/chef_lu_euweek.csv", "w") do |csv|

  csv << [:week_id, :descr_week_quarter, :descr_from_to, :descr_default, :descr_week_year, :descr_number ]

  euweeks.each do |week|

    line = []

    line << week[:euweek_id]

    line << "W#{week[:euweek_of_quarter]}/Q#{week[:quarter_of_year_for_week]}/#{week[:year_for_week]}"

    line << "#{week[:current_date].strftime('%b %d,%Y')} - #{week[:current_date].advance(:days => 6).strftime('%b %d,%Y')}"

    line << "#{week[:current_date].strftime('Wk. of %a %m/%d/%Y')}"

    line << "W#{week[:week_of_year]}/#{week[:year_for_week]}"

    line << "W#{week[:euweek_of_quarter]}/Q#{week[:quarter_of_year_for_week]}/#{week[:year_for_week]}"

    csv << line

  end

end



FasterCSV.open("table_data/chef_lu_week.csv", "w") do |csv|

  csv << [:week_id, :descr_week_quarter, :descr_from_to, :descr_default, :descr_week_year, :descr_number ]

  usweeks.each do |week|

    line = []

    line << week[:usweek_id]

    line << "W#{week[:usweek_of_quarter]}/Q#{week[:quarter_of_year_for_usweek]}/#{week[:year_for_usweek]}"

    line << "#{week[:current_date].strftime('%b %d,%Y')} - #{week[:current_date].advance(:days => 6).strftime('%b %d,%Y')}"

    line << "#{week[:current_date].strftime('Wk. of %a %m/%d/%Y')}"

    line << "W#{week[:usweek_of_year]}/#{week[:year_for_usweek]}"

    line << "W#{week[:usweek_of_quarter]}/Q#{week[:quarter_of_year_for_usweek]}/#{week[:year_for_usweek]}"

    csv << line

  end

end





FasterCSV.open("table_data/chef_lu_day.csv", "w") do |csv|

  csv << [:id, :id_day_in_euweek, :id_day_in_year, :id_quarter_in_year, :id_month_in_quarter, :id_month_in_year, :id_week, :id_euweek, :id_week_in_year, :id_day_in_week, :id_week_in_quarter, :id_euweek_in_quarter, :id_day_in_quarter, :id_month, :id_day_in_month, :id_year, :id_euweek_in_year, :id_quarter, :desc_eu, :descr_default, :desc_us, :desc_iso, :desc_us_long, :desc_us2]



  days.each do |day|

    line = []

    line << day[:day_id]
    line << day[:day_of_euweek]
    line << day[:day_of_year]
    line << day[:quarter_of_year]
    line << day[:month_of_quarter]
    line << day[:month_of_year]
    line << day[:usweek_id]
    line << day[:euweek_id]
    line << day[:usweek_of_year]
    line << day[:day_of_week]
    line << day[:usweek_of_quarter]
    line << day[:euweek_of_quarter]
    line << day[:day_of_quarter]
    line << day[:month_id]
    line << day[:day_of_month]
    line << day[:year_id]
    line << day[:week_of_year]
    line << day[:quarter_id]
    # =====
    line << day[:current_date].strftime("%d/%m/%Y")
    line << day[:current_date].strftime("%Y-%m-%d")
    line << day[:current_date].strftime("%m/%d/%Y")
    line << day[:current_date].strftime("%d-%m-%Y")
    line << day[:current_date].strftime("%a, %b %d, %Y")
    line << day[:current_date].strftime("%_d/%_m/%y").gsub(" ", "")
    csv << line

  end

end



#########

# LOOKUPS

#########

def aggregate_on(what, on_what)

  result = on_what.inject([]) do |memo, item|

    memo << item unless memo.find {|d| d[what] == item[what]}

    memo

  end

end



def save_as_csv(what, header, filename, &block)

  FasterCSV.open(filename, "w") do |csv|

    csv << header

    # null_line = Array.new(header.size)

    # null_line[0] = 0

    # csv << null_line

    what.each do |day|

      yield day, csv

    end

  end

end





# WEEKS OF QUARTER

save_as_csv(aggregate_on(:usweek_of_quarter, usweeks), [:id, :descr_default], "lookups/chef_lu_week_in_quarter.csv") do |day, csv|

  line = []

  line << day[:usweek_of_quarter]

  line << "W#{day[:usweek_of_quarter]}"

  csv << line

end



save_as_csv(aggregate_on(:euweek_of_quarter, euweeks), [:id, :descr_default], "lookups/chef_lu_euweek_in_quarter.csv") do |day, csv|

  line = []

  line << day[:euweek_of_quarter]

  line << "W#{day[:euweek_of_quarter]}"

  csv << line

end





# DAY IN YEAR

save_as_csv(aggregate_on(:day_of_year, days), [:id, :descr_default], "lookups/chef_lu_day_in_year.csv") do |day, csv|

  line = []

  line << day[:day_of_year]

  line << "D#{day[:day_of_year]}"

  csv << line

end





# MONTH IN QUARTER

save_as_csv(aggregate_on(:month_of_quarter, months), [:id, :descr_default], "lookups/chef_lu_month_in_quarter.csv") do |day, csv|

  line = []

  line << day[:month_of_quarter]

  line << "M#{day[:month_of_quarter]}"

  csv << line

end





# MONTH IN YEAR

month_index = PARSED_BEGINNNING_OF_YEAR.month - PARSED_BEGINNNING_OF_YEAR.beginning_of_year.month - 1

save_as_csv(aggregate_on(:month_of_year, months), [:id, :descr_default, :desc_mq, :desc_num, :desc_us_long], "lookups/chef_lu_month_in_year.csv") do |day, csv|

    index = ((day[:month_of_year] + month_index) % 12) + 1

    line = []

    line << day[:month_of_year]

    line << "#{Date::ABBR_MONTHNAMES[index]}"

    line << "M#{day[:months_of_quarter]}/Q#{day[:quarter_of_year]}"

    line << "M#{day[:month_of_year]}"

    line << "#{Date::MONTHNAMES[index]}"

    csv << line

end



# week in year

save_as_csv(aggregate_on(:week_of_year, euweeks), [:id, :descr_default], "lookups/chef_lu_week_in_year.csv") do |day, csv|

  line = []

  line << day[:week_of_year]

  line << "W#{day[:week_of_year]}"

  csv << line

end



save_as_csv(aggregate_on(:week_of_year, euweeks), [:id, :descr_default], "lookups/chef_lu_euweek_in_year.csv") do |day, csv|

  line = []

  line << day[:week_of_year]

  line << "W#{day[:week_of_year]}"

  csv << line

end







# Days Of Week

save_as_csv(aggregate_on(:day_of_week, days), [:id, :descr_default, :desc_num, :desc_us_long], "lookups/chef_lu_day_in_week.csv") do |day, csv|

  line = []

  line << day[:day_of_week]

  line << "#{day[:current_date].strftime('%a')}"

  line << "#{day[:day_of_week]}"

  line << "#{day[:current_date].strftime('%A')}"

  csv << line

end



# Days Of EU Week

save_as_csv(aggregate_on(:day_of_euweek, days), [:id, :descr_default, :desc_num, :desc_us_long], "lookups/chef_lu_day_in_euweek.csv") do |day, csv|

  line = []

  line << day[:day_of_euweek]

  line << "#{day[:current_date].strftime('%a')}"

  line << "#{day[:day_of_euweek]}"

  line << "#{day[:current_date].strftime('%A')}"

  csv << line

end



save_as_csv(aggregate_on(:day_of_month, days), [:id, :descr_default], "lookups/chef_lu_day_in_month.csv") do |day, csv|

  line = []

  line << day[:day_of_month]

  line << "D#{day[:day_of_month]}"

  csv << line

end



save_as_csv(aggregate_on(:quarter_of_year, quarters), [:id, :descr_default], "lookups/chef_lu_quarter_in_year.csv") do |day, csv|

  line = []

  line << day[:quarter_of_year]

  line << "Q#{day[:quarter_of_year]}"

  csv << line

end



save_as_csv(aggregate_on(:day_of_quarter, days), [:id, :descr_default], "lookups/chef_lu_day_in_quarter.csv") do |day, csv|

  line = []

  line << day[:day_of_quarter]

  line << "D#{day[:day_of_quarter]}"

  csv << line

end