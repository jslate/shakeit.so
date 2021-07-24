require 'dotenv/load'
require 'sendgrid-ruby'
include SendGrid

emails = JSON.parse(File.read("./emails.json")).map { |hash| hash.transform_keys(&:to_sym) }

from = Email.new(email: 'dance@shakeit.so', name: "Shake It So")
subject = 'Tomorrow 9AM, Saturday Aug 7 🕺💃🇺🇸'
content = Content.new(type: 'text/html', value: File.read("./public/email-drafts/july-04-2021.html"))
api_key = ENV['SENDGRID_API_KEY']
sg = SendGrid::API.new(api_key: api_key)

emails.each do |email_hash|
  puts email_hash[:email]
  to = Email.new(**email_hash)
  mail = Mail.new(from, subject, to, content)
  response = sg.client.mail._('send').post(request_body: mail.to_json)
  puts response.status_code
  puts response.body
  puts response.headers
end
