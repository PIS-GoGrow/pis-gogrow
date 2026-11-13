# frozen_string_literal: true

class BackfillConsumerAddressesToDeliveryAddresses < ActiveRecord::Migration[8.1]
  class MigrationConsumer < ActiveRecord::Base
    self.table_name = "consumers"
  end

  class MigrationDeliveryAddress < ActiveRecord::Base
    self.table_name = "delivery_addresses"
  end

  def up
    MigrationConsumer.where.not(address: [ nil, "" ]).find_each do |consumer|
      legacy_address = consumer.address.to_s.squish
      next if legacy_address.blank?

      already_saved = MigrationDeliveryAddress
        .where(consumer_id: consumer.id)
        .any? do |delivery_address|
          [
            delivery_address.street,
            delivery_address.apartment
          ].compact_blank.join(", ").squish == legacy_address
        end

      next if already_saved

      MigrationDeliveryAddress.create!(
        consumer_id: consumer.id,
        name: "Casa",
        street: legacy_address,
        created_at: Time.current,
        updated_at: Time.current
      )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
