# frozen_string_literal: true

class SharedPropsSerializer < ApplicationSerializer
  one :auth, source: proc { Current }

  many :notifications,
       resource: NotificationSerializer,
       source: proc {
         next Notification.none unless Current.user && Current.session

         Current.user.notifications
           .active
           .where(role: Current.session.role)
           .order(created_at: :desc)
       }

  typelize locale: :string
  attribute :locale do
    I18n.locale.to_s
  end
end
