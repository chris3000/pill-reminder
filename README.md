I wrote this app to remind my wife to take her pre-natal pills during her pregnancy.
It uses Twilio to send SMS and Sinatra for the web interface.  A cron job will periodically
hit the URL which will trigger an SMS if my wife hasn't told the app that she has taken her pills.
