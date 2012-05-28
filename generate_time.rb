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

FileUtils::mkdir_p 'lookups'
FileUtils::mkdir_p 'table_data'

start_date = Date.new(2011, 7, 1)
end_date = Date.new(2015, 7, 1)

BEGINNNING_OF_YEAR = '1st july'

years = []
quarters = []
months = []
weeks = []
days = []

# INITIAL VALUES OF COUNTERS
current_date = start_date
week_of_month = 1
week_of_quarter = 1
month_of_year = 1
week_of_year = 1
month_of_year = 1
month_of_quarter = 1
quarter_of_year = 1

week_id = 0
day_id = start_date.to_datetime.utc.to_i / 86400 + 25568
month_id = 0
quarter_id = 0
year_id = start_date.year + 1

beginning_of_week = current_date
beginning_of_month = current_date
beginning_of_quarter = current_date
beginning_of_year = current_date

first = true


def get_days_in_week(week_of_month)
  7
end

def get_days_in_month(date)
  Time::days_in_month(date.month, date.year)
end

def get_days_in_quarter(date)
  a = date.beginning_of_quarter
  b = date.end_of_quarter
  b - a + 1
end

def get_days_in_year(beginning_of_year)
  beginning = Date.new(beginning_of_year.year, 7, 1)
  last_year_beginning = Date.new(beginning_of_year.year + 1, 7, 1)
  last_year_beginning - beginning
end

# pp [:year_id, :current_date, :day_id, :week_of_month, :month_id, :quarter_id, :quarter_of_year]
# puts "============"
while current_date <= end_date do

  next_thursday = Chronic.parse('next thursday', :now => current_date).to_date
  last_thursday = Chronic.parse('last thursday', :now => current_date).to_date

  # WEEKS
  week_changed = current_date - beginning_of_week >= get_days_in_week(week_id)
  # binding.pry if week_changed
  if week_changed
    beginning_of_week = current_date 
    week_id += 1
  end

  # MONTH
   
  month_changed = current_date - beginning_of_month >= get_days_in_month(beginning_of_month)
  # binding.pry if month_changed
  if month_changed
    beginning_of_month = current_date
    month_id += 1
  end
  
  
  
  # QUARTER
  if next_thursday.beginning_of_quarter != current_date.beginning_of_quarter && (beginning_of_week == current_date) then
    quarter_for_week_changed = true
    # binding.pry
  elsif last_thursday.beginning_of_quarter != current_date.beginning_of_quarter && (beginning_of_week == current_date) then
    quarter_for_week_changed = true
    # binding.pry
  else
    quarter_for_week_changed = false
  end
  quarter_changed = current_date - beginning_of_quarter >= get_days_in_quarter(beginning_of_quarter)
  # binding.pry if quarter_changed
  if quarter_changed
    beginning_of_quarter = current_date
    quarter_id += 1
  end
  
  # YEAR
  same_year_in_future = Chronic.parse(BEGINNNING_OF_YEAR, :now => current_date.advance(:months => 1)).year == Chronic.parse(BEGINNNING_OF_YEAR, :now => next_thursday.advance(:months => 1)).year
  same_year_in_past = Chronic.parse(BEGINNNING_OF_YEAR, :now => current_date.advance(:months => 1)).year == Chronic.parse(BEGINNNING_OF_YEAR, :now => last_thursday.advance(:months => 1)).year

  if !same_year_in_future && (beginning_of_week == current_date) then
    year_for_week_changed = true
    # binding.pry
  elsif !same_year_in_past && (beginning_of_week == current_date) then
    year_for_week_changed = true
    # binding.pry
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
  
  day_of_week     = current_date - beginning_of_week + 1
  day_of_month    = current_date - beginning_of_month + 1
  day_of_quarter  = current_date - beginning_of_quarter + 1
  day_of_year     = current_date - beginning_of_year + 1
  
  # WEEK IN YEAR
  if year_for_week_changed
    week_of_year = 1
  elsif week_changed
    week_of_year += 1
  end
  
  # WEEK IN QUARTER
  if quarter_for_week_changed
    week_of_quarter = 1
  elsif week_changed
    week_of_quarter += 1
  end
  
  # WEEK IN MONTH
  if month_changed
    week_of_month = 1
  elsif week_changed
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
    # binding.pry
    month_of_year = 1
  elsif month_changed
    # binding.pry
    month_of_year += 1
  end
  
  
  # QUARTER OF YEAR
  if quarter_changed && year_changed
    quarter_of_year = 1
  elsif quarter_changed
    quarter_of_year += 1
  end
  
  day = {
    :current_date           => current_date,
    
    :day_id                 => day_id + 1,
    :week_id                => week_id + 1,
    :month_id               => month_id + 1,
    :quarter_id             => quarter_id + 1,
    :year_id                => year_id,
    
    :day_of_week            => day_of_week.to_i,
    :day_of_month           => day_of_month.to_i,
    :day_of_quarter         => day_of_quarter.to_i,
    :day_of_year            => day_of_year.to_i,
    
    :week_of_year           => week_of_year.to_i,
    :week_of_quarter        => week_of_quarter.to_i,
    :week_of_month          => week_of_month.to_i,
    
    :month_of_quarter       => month_of_quarter,
    :month_of_year          => month_of_year,
    
    :quarter_of_year        => quarter_of_year
  }
  
  # OUTPUT
  # make events so it can be driven from outside
  
  # YEARS
  years     << day if year_changed || first
  quarters  << day if quarter_changed || first
  months    << day if month_changed || first
  weeks     << day if week_changed || first
  days      << day

  # Next Iteration
  first = false
  current_date = current_date.next
  day_id += 1
end



# OUTPUT 
FasterCSV.open("table_data/chef_lu_year.csv", "w") do |csv|
  csv << [:year_id, :descr_default]
  years.each do |year|
    line = []
    line << year[:year_id]
    line << year[:year_id]
    csv << line
  end
end

FasterCSV.open("table_data/chef_lu_quarter.csv", "w") do |csv|
  csv << [:quarter_id, :year_id, :quarter_of_year, :descr_default]
  quarters.each do |quarter|
    line = []
    line << quarter[:quarter_id]
    line << quarter[:year_id]
    line << quarter[:quarter_of_year]
    line << "Q#{quarter[:quarter_of_year]}/#{quarter[:year_id]}"
    csv << line
  end
end

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
    line << "#{Date::ABBR_MONTHNAMES[(month[:month_of_year] + 5) % 12 + 1]} #{month[:year_id]}"
    line << "#{month[:month_of_year]}/#{month[:year_id]}"
    line << "#{Date::MONTHNAMES[(month[:month_of_year] + 5) % 12 + 1] } #{month[:year_id]}"
    csv << line
  end
end

FasterCSV.open("table_data/chef_lu_week.csv", "w") do |csv|
  csv << [:week_id, :descr_week_quarter, :descr_week_year, :descr_default, :descr_from_to, ]
  weeks.each do |week|
    line = []
    line << week[:week_id]
    line << "W#{week[:week_of_quarter]}/Q#{week[:quarter_of_year]}/#{week[:year_id]}"
    line << "W#{week[:week_of_year]}/#{week[:year_id]}"
    # line << "#{week[:current_date].strftime('Wk. of %a')} #{week[:month_of_year]}/#{week[:day_of_month]}/#{week[:year_id]}"
    line << "#{week[:current_date].strftime('%m/%d/%Y')} - #{week[:current_date].advance(:days => 6).strftime('%m/%d/%Y')}"
    line << "#{week[:current_date].strftime('Wk. of %a %m/%d/%Y')}"
    csv << line
  end
end

FasterCSV.open("table_data/chef_lu_day.csv", "w") do |csv|
  csv << [:day_id, :day_of_week, :day_of_year, :quarter_of_year, :month_of_quarter, :month_of_year, :week_id, :week_of_year, :week_of_quarter, :day_of_quarter, :month_id, :day_of_month, :year_id, :quarter_id, :descr_default, :desc_us, :desc_iso, :desc_us_long, :desc_us2]
  days.each do |day|
    line = []
    line << day[:day_id]
    line << day[:day_of_week]
    line << day[:day_of_year]
    line << day[:quarter_of_year]
    line << day[:month_of_quarter]
    line << day[:month_of_year]
    line << day[:week_id]
    line << day[:week_of_year]
    line << day[:week_of_quarter]
    line << day[:day_of_quarter]
    line << day[:month_id]
    line << day[:day_of_month]
    line << day[:year_id]
    line << day[:quarter_id]
    # =====
    line << day[:current_date].strftime("%Y-%m-%d")
    line << day[:current_date].strftime("%m/%d/%Y")
    line << day[:current_date].strftime("%m-%d-%Y")
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
save_as_csv(aggregate_on(:week_of_quarter, weeks), [:id, :descr_default], "lookups/chef_lu_week_in_quarter.csv") do |day, csv|
  line = []
  line << day[:week_of_quarter]
  line << "W#{day[:week_of_quarter]}"
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
save_as_csv(aggregate_on(:month_of_year, months), [:id, :descr_default, :desc_mq, :desc_num, :desc_us_long], "lookups/chef_lu_month_in_year.csv") do |day, csv|
  line = []
  line << day[:month_of_year]
  line << "#{Date::ABBR_MONTHNAMES[day[:month_of_year]]}"
  line << "M#{day[:months_of_quarter]}/Q#{day[:quarter_of_year]}"
  line << "M#{day[:month_of_year]}"
  line << "#{Date::MONTHNAMES[day[:month_of_year]]}"
  csv << line
end

# week in year
save_as_csv(aggregate_on(:week_of_year, weeks), [:id, :descr_default], "lookups/chef_lu_week_in_year.csv") do |day, csv|
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