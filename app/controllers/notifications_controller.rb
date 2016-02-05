class NotificationsController < ApplicationController

# Here we ensure any StandardError triggers our alert method with rescue_from.
  rescue_from StandardError do |exception|
    trigger_sms_alerts(exception)
  end

  def trigger_sms_alerts(e)
  # Alert message to send out via text. You might also include a picture with your alert, ?screenshot of application during crash?
    @alert_message = "
      [This is a test] ALERT! 
      It appears the server is having issues. 
      Exception: #{e}. 
      Go to: http://newrelic.com for more details."
    @image_url = "http://howtodocs.s3.amazonaws.com/new-relic-monitor.png"

    @admin_list = YAML.load_file('config/administrators.yml')

    begin
    # We read the admins from our YAML file and send alert messages to each of them with the private send_message method.
      @admin_list.each do |admin|
        phone_number = admin['phone_number']
        send_message(phone_number, @alert_message, @image_url)
      end
      
      flash[:success] = "Exception: #{e}. Administrators will be notified."
    rescue
      flash[:alert] = "Something when wrong."
    end


    redirect_to '/'
  end

  def index
  end

  def server_error
    raise 'A test exception'
  end

  private

    def send_message(phone_number, alert_message, image_url)
    # To send a message we need to initialize the Twilio REST client, which requires TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN

      @twilio_number = ENV['TWILIO_NUMBER']
      @client = Twilio::REST::Client.new ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN']
      
      # There are the three parameters needed to send an SMS using the Twilio REST API:
      message = @client.account.messages.create(
        :from => @twilio_number,
        :to => phone_number,
        :body => alert_message,
        # US phone numbers can make use of an image as well.
        # :media_url => image_url 
      )
      # After the message is sent, we print out the phone number we're textin
      puts message.to
    end

end
