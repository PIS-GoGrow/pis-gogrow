# frozen_string_literal: true

require "rails_helper"

RSpec.describe Payment, type: :model do
  it { is_expected.to belong_to(:account) }
  it { is_expected.to belong_to(:provider).optional }

  # Faker no sirve acá: config/initializers/locale.rb deja available_locales en
  # [:es] y Faker traduce con I18n en :en, así que cualquier Faker::Name o
  # Faker::Address revienta con MissingTranslationData. Se usan valores fijos
  # como en spec/models/account_spec.rb; la repetición de emails entre ejemplos
  # no choca porque cada ejemplo corre en su transacción.
  let(:company) { Company.create!(name: "GoGrow", address: "18 de Julio 1006") }
  let(:consumer) { Consumer.create!(user: User.create!(email: "consumer-payment-test@gmail.com", name: "Lucía", password: "password123456"), company:, address: "Ellauri 1234") }
  let(:provider) { Provider.create!(user: User.create!(email: "provider-payment-test@gmail.com", name: "Rotisería Central", password: "password123456")) }
  let(:account) { Account.create!(owner: consumer, provider:, month: Date.current, amount: 500) }

  # El adjunto es lo que valida el modelo (tipo y tamaño), así que el io se arma
  # con el tamaño y el content_type que cada caso necesita.
  def payment_with_receipt(status: :submitted, rejection_reason: nil, content_type: "image/png", bytes: "comprobante", filename: "comprobante.png")
    payment = account.payments.build(provider:, status:, rejection_reason:)
    payment.receipt.attach(io: StringIO.new(bytes), filename:, content_type:)
    payment
  end

  it "starts as pending" do
    expect(described_class.new.status).to eq("pending")
  end

  describe "the provider notification" do
    let(:notifications) { Notification.where(event: "payment_receipt_submitted", user: provider.user) }

    it "notifies the provider when a receipt is sent" do
      payment_with_receipt.save!

      expect(notifications.sole).to have_attributes(
        role: "provider",
        title: "Nuevo comprobante de pago",
        description: start_with("Lucía envió un comprobante de pago de")
      )
    end

    it "keeps a single active notification when the receipt is sent again" do
      payment = payment_with_receipt.tap(&:save!)
      payment.reject_with("Ilegible")
      payment.update!(status: :submitted)

      expect(notifications.active.count).to eq(1)
      expect(notifications.closed.count).to eq(1)
    end

    it "does not notify for a payment that was not sent" do
      account.payments.create!(provider:)

      expect(notifications).to be_empty
    end
  end

  describe "the receipt" do
    it "is required to send a payment" do
      payment = account.payments.build(provider:, status: :submitted)

      expect(payment).not_to be_valid
      expect(payment.errors[:receipt]).to include(
        I18n.t("activerecord.errors.models.payment.attributes.receipt.required")
      )
    end

    it "accepts the three formats the app announces" do
      [ "application/pdf", "image/jpeg", "image/png" ].each do |content_type|
        payment = payment_with_receipt(content_type:)

        expect(payment).to be_valid
      end
    end

    it "rejects any other format" do
      payment = payment_with_receipt(content_type: "text/plain")

      expect(payment).not_to be_valid
      expect(payment.errors[:receipt]).to include(
        I18n.t("activerecord.errors.models.payment.attributes.receipt.invalid_content_type")
      )
    end

    # Borde del tamaño: 10 MB entra, un byte más no.
    it "accepts exactly 10 MB and rejects one byte more" do
      at_limit = payment_with_receipt(bytes: "x" * 10.megabytes)
      over_limit = payment_with_receipt(bytes: "x" * (10.megabytes + 1))

      expect(at_limit).to be_valid
      expect(over_limit).not_to be_valid
      expect(over_limit.errors[:receipt]).to include(
        I18n.t("activerecord.errors.models.payment.attributes.receipt.too_large")
      )
    end

    it "does not require a receipt for a payment that was not sent" do
      payment = account.payments.build(provider:, status: :pending)

      expect(payment).to be_valid
    end
  end

  describe "the rejection reason" do
    it "is required to reject a payment" do
      payment = payment_with_receipt(status: :rejected, rejection_reason: " ")

      expect(payment).not_to be_valid
      expect(payment.errors[:rejection_reason]).to include(
        I18n.t("activerecord.errors.models.payment.attributes.rejection_reason.blank")
      )
    end

    it "is kept on the rejected payment" do
      payment = payment_with_receipt(status: :rejected, rejection_reason: "La imagen está borrosa")
      payment.save!

      expect(payment).to be_rejected
      expect(payment.rejection_reason).to eq("La imagen está borrosa")
    end

    it "is cleared when the employee sends the payment again" do
      payment = payment_with_receipt(status: :rejected, rejection_reason: "La imagen está borrosa")
      payment.save!

      # Es el reenvío de Consumer::PaymentsController#update: comprobante nuevo y
      # el pago vuelve a "enviado".
      payment.receipt.attach(
        io: StringIO.new("comprobante nuevo"), filename: "nuevo.png", content_type: "image/png"
      )
      payment.update!(status: :submitted)

      expect(payment.reload).to be_submitted
      expect(payment.rejection_reason).to be_nil
    end
  end

  describe "#approve" do
    it "approves the payment and takes the rejection reason away" do
      payment = payment_with_receipt(status: :rejected, rejection_reason: "La imagen está borrosa")
      payment.save!

      payment.approve

      expect(payment.reload).to be_approved
      expect(payment.rejection_reason).to be_nil
    end
  end

  describe "#reject_with" do
    it "rejects the payment with the reason the provider chose" do
      payment = payment_with_receipt
      payment.save!

      payment.reject_with("Los montos no coinciden")

      expect(payment.reload).to be_rejected
      expect(payment.rejection_reason).to eq("Los montos no coinciden")
    end
  end

  describe "one receipt under review per account" do
    let(:already_under_review) do
      I18n.t("activerecord.errors.models.payment.attributes.receipt.already_under_review")
    end

    it "does not allow a second submitted payment for the same account" do
      payment_with_receipt.save!
      second = payment_with_receipt(filename: "comprobante_2.png")

      expect(second).not_to be_valid
      expect(second.errors[:receipt]).to include(already_under_review)
    end

    it "is enforced by the database when the validation is skipped" do
      payment_with_receipt.save!
      second = payment_with_receipt(filename: "comprobante_2.png")

      expect { second.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows a new submitted payment once the previous one was resolved" do
      first = payment_with_receipt
      first.save!
      first.reject_with("Comprobante ilegible")

      expect(payment_with_receipt(filename: "comprobante_2.png")).to be_valid
    end

    it "does not allow resubmitting a rejected payment while another one is under review" do
      rejected = payment_with_receipt(status: :rejected, rejection_reason: "Comprobante ilegible")
      rejected.save!
      payment_with_receipt(filename: "comprobante_2.png").save!

      rejected.status = :submitted

      expect(rejected).not_to be_valid
      expect(rejected.errors[:receipt]).to include(already_under_review)
    end

    it "keeps the limit per account" do
      payment_with_receipt.save!
      other_account = Account.create!(owner: consumer, provider:, month: Date.current.prev_month, amount: 500)
      other = other_account.payments.build(provider:, status: :submitted)
      other.receipt.attach(io: StringIO.new("comprobante"), filename: "otro.png", content_type: "image/png")

      expect(other).to be_valid
    end
  end

  describe "multiple receipts and deletion integrity" do
    it "allows an account to have multiple payments as long as only one is under review" do
      payment1 = payment_with_receipt(status: :rejected, rejection_reason: "Comprobante ilegible", filename: "comprobante_1.png")
      payment1.save!
      payment2 = payment_with_receipt(filename: "comprobante_2.png")
      payment2.save!

      expect(account.payments.count).to eq(2)
      expect(account.payments).to include(payment1, payment2)
    end

    it "destroys attached receipt and leaves other payments intact when one payment is destroyed" do
      payment1 = payment_with_receipt(status: :rejected, rejection_reason: "Comprobante ilegible", filename: "comprobante_1.png")
      payment1.save!
      payment2 = payment_with_receipt(filename: "comprobante_2.png")
      payment2.save!

      attachment1_id = payment1.receipt.attachment.id
      attachment2_id = payment2.receipt.attachment.id

      expect {
        payment1.destroy!
      }.to change(described_class, :count).by(-1)

      expect(described_class.exists?(payment1.id)).to be(false)
      expect(described_class.exists?(payment2.id)).to be(true)
      expect(ActiveStorage::Attachment.exists?(attachment1_id)).to be(false)
      expect(ActiveStorage::Attachment.exists?(attachment2_id)).to be(true)
      expect(account.reload.payments).to contain_exactly(payment2)
    end
  end

  describe "automatic payment reminders" do
    before do
      Notification::Configuration.find_or_create_by!(
        key: "automatic_payment_reminders"
      ) do |configuration|
        configuration.roles = [ "consumer" ]
      end
    end

    it "closes an active reminder when the employee submits a payment" do
      notification = Notifier.call(
        event_key: "payment_due_soon",
        user: consumer.user,
        notifiable: account,
        description_data: {
          amount: "$500",
          provider: provider.user.name,
          due_date: "10/11/2026",
          days: 3
        }
      )

      payment = payment_with_receipt(status: :submitted)
      payment.save!

      expect(notification.reload.closed_at).to be_present
    end

    it "closes an active reminder when a rejected payment is submitted again" do
      payment = payment_with_receipt(
        status: :rejected,
        rejection_reason: "La imagen está borrosa"
      )
      payment.save!

      notification = Notifier.call(
        event_key: "payment_due_soon",
        user: consumer.user,
        notifiable: account,
        description_data: {
          amount: "$500",
          provider: provider.user.name,
          due_date: "10/11/2026",
          days: 3
        }
      )

      payment.receipt.attach(
        io: StringIO.new("comprobante nuevo"),
        filename: "nuevo.png",
        content_type: "image/png"
      )
      payment.update!(status: :submitted)

      expect(notification.reload.closed_at).to be_present
    end

    it "does not close reminders when a payment is rejected" do
      notification = Notifier.call(
        event_key: "payment_due_soon",
        user: consumer.user,
        notifiable: account,
        description_data: {
          amount: "$500",
          provider: provider.user.name,
          due_date: "10/11/2026",
          days: 3
        }
      )

      payment = account.payments.create!(
        provider:,
        status: :pending
      )

      payment.reject_with("El comprobante no es válido")

      expect(notification.reload.closed_at).to be_nil
    end
  end
end

# == Schema Information
#
# Table name: payments
#
#  id               :bigint           not null, primary key
#  rejection_reason :text
#  status           :integer          default(0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  provider_id      :bigint
#
# Indexes
#
#  index_payments_on_account_id            (account_id)
#  index_payments_on_account_id_submitted  (account_id) UNIQUE WHERE (status = 1)
#  index_payments_on_provider_id           (provider_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (provider_id => providers.id)
#
