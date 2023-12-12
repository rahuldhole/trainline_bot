require 'mechanize'
require 'date'

class ComThetrainline
  def initialize
    @local_settings = {
      'DEFAULT_USER_AGENT' => 'Mac Safari',
      'RANDOMIZE_USER_AGENT' => true,
      'TRAINLINE_URL' => 'https://www.thetrainline.com/',
    }.freeze

    @form_fields = {
      'from_name_selector_match_string' => 'from.search_',
      'to_name_selector_match_string' => 'to.search_',
      'departure_date_selector_name' => 'page.journeySearchForm.outbound.title',
      'departure_time_selector_name' => 'hours',
      'departure_minutes_selector_name' => 'minutes',
      'submit_button_selector_name' => 'search',
    }.freeze

    @agent = Mechanize.new
    @agent.user_agent_alias = @local_settings['RANDOMIZE_USER_AGENT'] ? Mechanize::AGENT_ALIASES.keys.sample : @local_settings['DEFAULT_USER_AGENT']

    puts "Initialized ComThetrainline"
    puts "> user agent: #{@agent.user_agent}"
    puts "> url: #{@local_settings['TRAINLINE_URL']}"
  end

  def self.find(from, to, departure_at)
    bot = ComThetrainline.new
    bot.search(from, to, departure_at)
  end

  def search(from, to, departure_at)
    puts "Searching for trips from #{from} to #{to} at #{departure_at}..."
    page = @agent.get(@local_settings['TRAINLINE_URL'])

    form = page.forms.first
    from_selector_name, to_selector_name = get_from_to_selectors(form, departure_at)
    form[from_selector_name] = from
    form[to_selector_name] = to
    form[@form_fields['departure_date_selector_name']] = departure_at.strftime('%d-%b-%y')
    form[@form_fields['departure_time_selector_name']] = departure_at.strftime('%H')
    form[@form_fields['departure_minutes_selector_name']] = departure_at.strftime('%M')

    result_page = @agent.submit(form, form.buttons.last)
    
    puts "Submitted form... \n #{form.inspect}"
    File.open('tmp.html', 'w') { |f| f.write(result_page.body) }
    # parse_results(result_page)
  end

  private 

  def get_from_to_selectors(form, departure_at)
    from_selector_name = form.fields.find { |f| f.name.start_with?(@form_fields['from_name_selector_match_string']) }.name
    to_selector_name = form.fields.find { |f| f.name.start_with?(@form_fields['to_name_selector_match_string']) }.name
    
    return from_selector_name, to_selector_name
  end

  def parse_results(page)
    # TODO
  end

end

# Example
ComThetrainline.find('London', 'Paris', DateTime.new(2023, 12, 26, 6, 0, 0))