namespace :notifications do
  desc "Sincroniza Notification::Configuration con config/notifications.yml"
  task sync: :environment do
    Notification::Configuration.sync!
  end
end