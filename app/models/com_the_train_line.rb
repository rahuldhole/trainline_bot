class ComTheTrainLine
  attr_reader :local_settings, :form_fields, :session

  def self.find(from, to, departure_at)
    begin
      cttl = ComTheTrainLine.new
      cttl.bot(from, to, departure_at)
    rescue => e
      if not cttl.session.nil?
        cttl.screenshot("error")
        cttl.close
      end
      return puts "Error: #{e.message}. Please try again later.
        If the error persist try rebuilding container.
        Exiting..."
    end
  end

  def initialize
    @local_settings = {
      'url' => 'https://www.thetrainline.com/',
    }

    @form_fields = {
      accept_cookies_button_id: 'onetrust-accept-btn-handler',
      variable: {
        'from_id_match_string' => 'from.search_',
        'to_id_match_string' => 'to.search_',
      },

      fixed: {
        'form_data_test' => 'ExtendedSearch',
        'departure_date_id' => 'page.journeySearchForm.outbound.title',
        'submit_type_button_data_test' => 'submit-journey-search-button',

        optional: {
          'hours_minutes_id' => 'journey-search-form-time-picker', # two inputs hours and minutes have a common id
          #! Note:  first hours is for departure and second hours is for return same for minutes
          'departure_hours_name' => 'hours', # so lets differentiate them by name
          'departure_minutes_name' => 'minutes', # same here
          'leaving_at_or_arriving_by_id' => 'before-after-dropdown',
        }
      }
    }.freeze

    puts "Visitting #{@local_settings['url']}"
    @session = nil
    start
  end

  def start
    close if not @session.nil?
    @session = BotSessions.create_bot_session(@local_settings['url'])
  end

  def close
    BotSessions.end_bot_session(@session)
    puts 'Session closed'
  end

  def method_missing(method, *args, &block)
    if method.to_s.end_with?('=')
      @local_settings[method.to_s.upcase.chop] = args.first
    elsif @local_settings.keys.include?(method.to_s.upcase)
      @local_settings[method.to_s.upcase]
    else
      super
    end
  end

  def bot(from, to, departure_at)
    puts "Searching for trips from #{from} to #{to} at #{departure_at}... Please wait..."

    @session.visit '/'
    loading(5)
    puts "Landed on #{@session.title}"

    accept_cookies
    submit(from, to, departure_at)
    
    return true
  end

  def screenshot(name)
    return if @session.nil? or @session.html.nil?

    directory = "tmp"
    Dir.mkdir(directory) unless File.directory?(directory)

    name = Time.now.strftime("%Y-%m-%d_%H-%M-%S") if name.nil?
    filename = "screenshot_#{name.to_s}.html"
    filepath = "#{directory}/#{filename}" if not name.nil?

    File.open(filepath, 'w') { |file| file.write(@session.html) }
    
    puts "screenshot saved to #{filename}"
    rescue => e
      puts "Session screenshot failed: #{e.message}"
  end

  protected

  def loading(seconds)
    seconds.times do
      print "\u{1f682}"
      sleep 1
    end
    puts
  end

  def wait_for_overlay_to_disappear
    @session.has_no_css?('.onetrust-pc-dark-filter.ot-fade-in', wait: 10)
  end

  def accept_cookies
    puts "Accepting cookies"
    # click by javascript because of overlay
    @session.execute_script("document.getElementById('#{@form_fields[:accept_cookies_button_id]}').click()")
    # wait until overlay disappears
    wait_for_overlay_to_disappear
    screenshot("accepted_cookies")
    puts "Accepted cookies"
  end

  def submit(from, to, departure_at)
    puts "Fill in the search form"

    search_form = @session.find(:css, "[data-test='#{form_fields[:fixed]['form_data_test']}']")
    loading(1)
    puts "Found the search form"

    search_form.find(:css, "[id^='#{@form_fields[:variable]['from_id_match_string']}']") # from
      .set(from)
    loading(1)
    puts "Filled: from field"
    
    search_form.find(:css, "[id^='#{@form_fields[:variable]['to_id_match_string']}']") # to
      .set(to)
    loading(1)
    puts "Filled: to field"

    departure_date = departure_at.strftime("%d-%b-%y")
    search_form.find(:id, @form_fields[:fixed]['departure_date_id']) # departure date
      .set(departure_date)
    loading(1)
    puts "Filled: departure date field"

    departure_hours = departure_at.strftime("%H")
    search_form.find_all(:css, "[name='#{@form_fields[:fixed][:optional]['departure_hours_name']}']")[0]
      .set(departure_hours)
    loading(1)
    puts "Filled: departure hours field"

    departure_minutes = departure_at.strftime("%M")
    search_form.find_all(:css, "[name='#{@form_fields[:fixed][:optional]['departure_minutes_name']}']")[0]
      .set(departure_minutes)
    loading(1)
    puts "Filled: departure minutes field"

    screenshot("filled_form")

    # search_form.find(:css, "[data-test='#{@form_fields[:fixed]['submit_type_button_data_test']}']") # submit button
    #   .click
    # loading(1)

    puts "Submitted the search from"
  end

  def parse_results(page)
    # TODO
  end
end