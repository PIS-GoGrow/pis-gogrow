# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderReminders::Generate do
  fixtures :users, :companies, :providers, :consumers, :menus, :schedules, :orders

  let(:date) { Date.current }
  let(:consumer) { consumers(:other) }
  let(:consumer_with_order) { consumers(:one) }
  let(:tuviandita) { providers(:tuviandita) }
  let(:endulzate) { providers(:endulzate) }

  before do
    Notification::Configuration.find_or_create_by!(key: "order_reminders") do |configuration|
      configuration.roles = [ "consumer" ]
      configuration.configurable = true
    end

    tuviandita.update!(order_deadline: "12:00")
    endulzate.update!(order_deadline: "13:00")
  end

  describe ".call" do
    it "notifies one hour before the earliest deadline among published providers" do
      expect {
        described_class.call(date:, now: at(10, 59))
      }.not_to change { reminders_for(consumer).count }

      expect {
        described_class.call(date:, now: at(11))
      }.to change { reminders_for(consumer).count }.by(1)

      notification = reminders_for(consumer).sole

      expect(notification).to have_attributes(
        event: "order_deadline_reminder",
        requires_action: false,
        notifiable: consumer,
        user: consumer.user
      )

      expect(notification.description)
        .to eq("¡No te quedes sin almuerzo! Todavía no pediste tu vianda de hoy.")
    end

    it "does not notify if no provider published a menu for the date" do
      empty_date = date + 10.days
      now = Time.zone.local(
        empty_date.year,
        empty_date.month,
        empty_date.day,
        11
      )

      expect {
        described_class.call(date: empty_date, now:)
      }.not_to change { Notification.where(event: "order_deadline_reminder").count }
    end

    it "does not notify an employee with a pending order for today" do
      expect {
        described_class.call(date:, now: at(11))
      }.not_to change { reminders_for(consumer_with_order).count }
    end

    it "does not notify an employee with a confirmed order for today" do
      orders(:upcoming_pending_today)
        .update_column(:status, Order.statuses[:confirmed])

      expect {
        described_class.call(date:, now: at(11))
      }.not_to change { reminders_for(consumer_with_order).count }
    end

    it "notifies when the employee's only order for today was cancelled" do
      orders(:upcoming_pending_today)
        .update_column(:status, Order.statuses[:cancelled])

      expect {
        described_class.call(date:, now: at(11))
      }.to change { reminders_for(consumer_with_order).count }.by(1)
    end

    it "notifies when the employee's only order for today was rejected" do
      orders(:upcoming_pending_today)
        .update_column(:status, Order.statuses[:rejected])

      expect {
        described_class.call(date:, now: at(11))
      }.to change { reminders_for(consumer_with_order).count }.by(1)
    end

    it "creates at most one reminder per employee per day" do
      described_class.call(date:, now: at(11))

      expect {
        described_class.call(date:, now: at(11, 1))
      }.not_to change { reminders_for(consumer).count }

      expect(reminders_for(consumer).count).to eq(1)
    end

    it "does not create another reminder after the employee dismisses it" do
      described_class.call(date:, now: at(11))
      reminders_for(consumer).sole.close!

      expect {
        described_class.call(date:, now: at(11, 1))
      }.not_to change { reminders_for(consumer).count }

      expect(reminders_for(consumer).count).to eq(1)
    end

    it "does not notify after the earliest deadline has passed" do
      expect {
        described_class.call(date:, now: at(12))
      }.not_to change { reminders_for(consumer).count }
    end

    it "creates a single reminder when two providers share the earliest deadline" do
      endulzate.update!(order_deadline: "12:00")

      expect {
        described_class.call(date:, now: at(10, 59))
      }.not_to change { reminders_for(consumer).count }

      described_class.call(date:, now: at(11))
      described_class.call(date:, now: at(11))

      expect(reminders_for(consumer).count).to eq(1)
    end

    it "still notifies if the first run inside the window is late" do
      expect {
        described_class.call(date:, now: at(11, 30))
      }.to change { reminders_for(consumer).count }.by(1)
    end

    it "does not notify again when the deadline changes after the reminder was sent" do
      described_class.call(date:, now: at(11))
      tuviandita.update!(order_deadline: "12:30")

      expect {
        described_class.call(date:, now: at(11, 45))
      }.not_to change { reminders_for(consumer).count }
    end

    it "only notifies employees without an order, in the same run" do
      described_class.call(date:, now: at(11))

      expect(Notification.where(event: "order_deadline_reminder").map(&:user))
        .to contain_exactly(consumer.user)
      expect(Notification.where(event: "order_deadline_reminder", user: [ users(:admin), users(:provider_user) ]))
        .to be_empty
    end

    it "notifies an employee whose only active order is for another day" do
      expect(consumer.orders.joins(:schedule).where(schedules: { date: date + 3 }, status: :confirmed)).to exist

      expect {
        described_class.call(date:, now: at(11))
      }.to change { reminders_for(consumer).count }.by(1)
    end

    it "notifies when a provider publishes a menu shortly before its deadline" do
      empty_date = date + 10.days

      expect {
        described_class.call(date: empty_date, now: at(11, 0, empty_date))
      }.not_to change { reminders_for(consumer).count }

      menus(:milanesa).schedules.create!(date: empty_date, amount: 5)

      expect {
        described_class.call(date: empty_date, now: at(11, 30, empty_date))
      }.to change { reminders_for(consumer).count }.by(1)
    end

    context "when deciding the earliest deadline" do
      it "ignores a provider that is closed that day" do
        tuviandita.closures.create!(starts_on: date, ends_on: date, reason: "Feriado")

        expect {
          described_class.call(date:, now: at(11))
        }.not_to change { reminders_for(consumer).count }

        expect {
          described_class.call(date:, now: at(12))
        }.to change { reminders_for(consumer).count }.by(1)
      end

      it "ignores a provider whose menu is archived" do
        menus(:milanesa).update_column(:archived_at, Time.current)

        expect {
          described_class.call(date:, now: at(11))
        }.not_to change { reminders_for(consumer).count }

        expect {
          described_class.call(date:, now: at(12))
        }.to change { reminders_for(consumer).count }.by(1)
      end

      it "ignores a provider with dishes published only for another day" do
        providers(:office_provider).update!(order_deadline: "10:00")

        expect {
          described_class.call(date:, now: at(9))
        }.not_to change { reminders_for(consumer).count }

        expect {
          described_class.call(date:, now: at(11))
        }.to change { reminders_for(consumer).count }.by(1)
      end
    end

    context "with WhatsApp" do
      let(:configuration) { Notification::Configuration.find_by!(key: "order_reminders") }

      it "enqueues the WhatsApp message for an employee subscribed to order reminders" do
        configuration.users << consumer.user

        expect {
          described_class.call(date:, now: at(11))
        }.to have_enqueued_job(WhatsappSenderJob).with(:order_deadline_reminder, {}, {}, consumer.user.phone)
      end

      it "does not enqueue WhatsApp for an employee who turned order reminders off" do
        expect {
          described_class.call(date:, now: at(11))
        }.not_to have_enqueued_job(WhatsappSenderJob)

        expect(reminders_for(consumer).count).to eq(1)
      end
    end
  end

  def at(hour, minute = 0, day = date)
    Time.zone.local(day.year, day.month, day.day, hour, minute)
  end

  def reminders_for(target_consumer)
    Notification.where(
      user: target_consumer.user,
      notifiable: target_consumer,
      event: "order_deadline_reminder"
    )
  end
end
