Configuration.for('fulcrum') do
  app_host "clients.botandrose.com"
  mailer_sender "BARD <notifications@clients.botandrose.com>"
  disable_registration true
  column_order "progress_to_left"
end
