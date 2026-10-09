# frozen_string_literal: true

require "rails_helper"

RSpec.describe Order, type: :model do
  fixtures :orders, :schedules, :menus, :menu_option_groups, :providers, :consumers, :companies, :users, :accounts

  it { is_expected.to define_enum_for(:status).with_values(pending: 0, confirmed: 1, cancelled: 2, rejected: 3) }
  it { is_expected.to define_enum_for(:delivery_method).with_values(office: 0, home: 1) }
  it do
    expect(subject).to define_enum_for(:rejection_reason)
      .with_values(out_of_stock: 0, duplicate_order: 1, customer_request: 2, order_error: 3, other: 4, dish_modified: 5)
      .with_prefix(:rejection_reason)
  end

  describe "rejection reason validations" do
    let(:order) { orders(:upcoming_pending_today) }

    it "is valid without rejection reason while pending, confirmed or cancelled" do
      expect(order).to be_valid

      order.status = :confirmed
      expect(order).to be_valid

      order.status = :cancelled
      expect(order).to be_valid
    end

    it "requires a rejection reason when rejected" do
      order.status = :rejected
      order.rejection_reason = nil

      expect(order).not_to be_valid
      expect(order.errors[:rejection_reason]).to include(
        I18n.t("activerecord.errors.models.order.attributes.rejection_reason.blank")
      )
    end

    it "is valid with a standard rejection reason without details" do
      order.status = :rejected
      order.rejection_reason = :out_of_stock
      order.rejection_details = nil

      expect(order).to be_valid
    end

    it "requires rejection_details when reason is other" do
      order.status = :rejected
      order.rejection_reason = :other
      order.rejection_details = nil

      expect(order).not_to be_valid
      expect(order.errors[:rejection_details]).to include(
        I18n.t("activerecord.errors.models.order.attributes.rejection_details.blank")
      )
    end

    it "is valid with other reason and details present" do
      order.status = :rejected
      order.rejection_reason = :other
      order.rejection_details = "Sin insumos"

      expect(order).to be_valid
    end
  end

  describe "delivery method by provider" do
    it "rejects home for an office-only provider" do
      order = Order.new(consumer: consumers(:one), schedule: schedules(:office), amount: 1, price: 100, discounted_price: 100, address: "Dirección", delivery_method: :home)

      expect(order).not_to be_valid
      expect(order.errors[:delivery_method]).to include(I18n.t("validations.delivery_method_not_allowed"))
    end

    it "accepts office for an office-only provider" do
      order = Order.new(consumer: consumers(:one), schedule: schedules(:office), amount: 1, price: 100, discounted_price: 100, address: "Dirección", delivery_method: :office)

      expect(order).to be_valid
    end
  end

  describe "delivery method snapshot" do
    it "stays updatable when the provider turns home delivery off" do
      order = Order.create!(consumer: consumers(:one), schedule: schedules(:future), amount: 1, price: 100, discounted_price: 100, address: consumers(:one).address, delivery_method: :home)
      order.schedule.menu.provider.update!(home_delivery: false)

      order.update!(status: :confirmed)

      expect(order.reload).to have_attributes(status: "confirmed", delivery_method: "home")
    end

    it "does not flag the delivery method of an order left without a schedule" do
      order = orders(:history_without_schedule)

      order.valid?

      expect(order.errors[:delivery_method]).to be_empty
    end
  end

  # IBP-022, criterio 3: el mensaje de aclaraciones es opcional, y la pantalla
  # manda "" cuando el empleado no escribe nada. Sin normalizar, el pedido queda
  # con un string vacío y las vistas muestran "Notas" en vez de "Sin notas".
  describe "notes" do
    def order_with_notes(notes)
      Order.create!(
        consumer: consumers(:one),
        schedule: schedules(:future),
        amount: 1,
        price: 100,
        discounted_price: 100,
        delivery_method: :office,
        notes:,
        benefits: []
      )
    end

    it "stores nil when the employee writes nothing" do
      expect(order_with_notes("").notes).to be_nil
    end

    it "stores nil when the message is only whitespace" do
      expect(order_with_notes("   ").notes).to be_nil
    end

    it "keeps the message when there is content" do
      expect(order_with_notes("Sin sal, por favor").notes).to eq("Sin sal, por favor")
    end
  end

  # IBP-022 — Como EMPLEADO, quiero seleccionar las opciones de personalización que el
  # plato admita al momento de pedir, para recibir la vianda según mi preferencia.
  # Criterio 1: lo elegido tiene que ser una de las opciones que el proveedor cargó al
  # plato, y todos los grupos del plato tienen que estar respondidos.
  describe "selected options" do
    let(:salsa) { menu_option_groups(:salsa_sorrentinos) }
    let(:relleno) { menu_option_groups(:relleno_sorrentinos) }

    def order_for(schedule, selected_options)
      Order.new(
        consumer: consumers(:one),
        schedule:,
        amount: 1,
        price: schedule.menu.price,
        discounted_price: schedule.menu.price,
        delivery_method: :office,
        selected_options:
      )
    end

    def chosen(*groups)
      groups.map { |group| { "group_id" => group.id, "name" => group.name, "values" => [ group.options.first ] } }
    end

    it "accepts one option of every group the dish offers" do
      expect(order_for(schedules(:sorrentinos_today), chosen(salsa, relleno))).to be_valid
    end

    it "requires an answer for every group the dish offers" do
      order = order_for(schedules(:sorrentinos_today), chosen(salsa))

      expect(order).not_to be_valid
      expect(order.errors[:base]).to include(I18n.t("validations.invalid_options"))
    end

    it "rejects a group answered with an empty list" do
      selection = chosen(salsa) + [ { "group_id" => relleno.id, "name" => relleno.name, "values" => [] } ]

      expect(order_for(schedules(:sorrentinos_today), selection)).not_to be_valid
    end

    # El mismo grupo existe en el otro plato: no es que el dato no exista.
    it "rejects a group that belongs to another dish" do
      otros = menus(:milanesa).option_groups.create!(name: "Extras", options: [ "Papaya" ])

      expect(order_for(schedules(:sorrentinos_today), chosen(salsa, relleno, otros))).not_to be_valid
    end

    it "rejects the same group twice" do
      expect(order_for(schedules(:sorrentinos_today), chosen(salsa, relleno, salsa))).not_to be_valid
    end

    it "rejects an option the group does not offer" do
      selection = chosen(salsa, relleno)
      selection[0]["values"] = [ "Carbonara" ]

      expect(order_for(schedules(:sorrentinos_today), selection)).not_to be_valid
    end

    it "rejects the same option twice inside a group" do
      selection = chosen(salsa, relleno)
      selection[0]["values"] = [ "Filetto", "Filetto" ]

      expect(order_for(schedules(:sorrentinos_today), selection)).not_to be_valid
    end

    it "rejects options for a dish that offers none" do
      expect(order_for(schedules(:future), chosen(salsa))).not_to be_valid
    end

    context "when a group allows more than one option" do
      let(:extras) do
        menus(:milanesa).option_groups.create!(name: "Extras", options: [ "Papaya", "Arándanos", "Limón" ], limit: 2)
      end

      def milanesa_order(values)
        order_for(schedules(:future), [ { "group_id" => extras.id, "name" => extras.name, "values" => values } ])
      end

      # Borde del límite del grupo: N entra, N+1 no.
      it "accepts exactly as many options as the limit allows" do
        expect(milanesa_order([ "Papaya", "Arándanos" ])).to be_valid
      end

      it "rejects one option more than the limit allows" do
        expect(milanesa_order([ "Papaya", "Arándanos", "Limón" ])).not_to be_valid
      end
    end

    # La guarda solo corre al crear o cuando el empleado toca la selección: un
    # pedido anterior a esta funcionalidad no tiene elección guardada, y el
    # proveedor tiene que poder confirmarlo igual.
    context "with an order made before the selection existed" do
      let(:order) do
        Order.create!(
          consumer: consumers(:one),
          schedule: schedules(:sorrentinos_today),
          amount: 1,
          price: 320,
          discounted_price: 320,
          delivery_method: :office,
          selected_options: chosen(salsa, relleno)
        )
      end

      before { order.update_column(:selected_options, []) }

      it "does not check the selection again while it stays untouched" do
        expect(order.update(notes: "Sin sal")).to be(true)
      end

      it "does check it as soon as the employee changes the selection" do
        order.selected_options = chosen(salsa)

        expect(order).not_to be_valid
      end

      it "lets the provider confirm it" do
        expect(order.update(status: :confirmed)).to be(true)
      end
    end
  end

  describe "database guarantees" do
    it "rejects an order without a delivery method" do
      expect do
        Order.new(consumer: consumers(:one), schedule: schedules(:future), amount: 1, price: 100, discounted_price: 100, address: "Dirección").save(validate: false)
      end.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "rejects home without an address" do
      order = orders(:upcoming_confirmed_future)
      order.update_column(:address, nil)

      expect { order.update_column(:delivery_method, 1) }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  describe ".upcoming" do
    it "includes orders whose delivery date has not passed yet" do
      expect(described_class.upcoming).to include(
        orders(:upcoming_pending_future),
        orders(:upcoming_confirmed_future),
        orders(:upcoming_pending_today)
      )
    end

    it "excludes cancelled, rejected, past and scheduleless orders" do
      expect(described_class.upcoming).not_to include(
        orders(:history_cancelled_future),
        orders(:history_rejected_future),
        orders(:history_confirmed_past),
        orders(:history_pending_past),
        orders(:history_without_schedule)
      )
    end

    it "sorts by delivery date, closest first" do
      expect(described_class.upcoming.first).to eq(orders(:upcoming_pending_today))
    end
  end

  describe ".history" do
    it "includes cancelled and rejected orders even when their delivery date is still ahead" do
      expect(described_class.history).to include(
        orders(:history_cancelled_future),
        orders(:history_rejected_future)
      )
    end

    it "includes orders left without a schedule" do
      expect(described_class.history).to include(orders(:history_without_schedule))
    end

    it "excludes upcoming orders" do
      expect(described_class.history).not_to include(orders(:upcoming_confirmed_future))
    end
  end

  describe "#subsidy" do
    it "is what the company covers: the gap between the full price and what the employee pays" do
      expect(orders(:upcoming_confirmed_future).subsidy).to eq(300.50)
    end

    it "is nil when either amount is missing" do
      order = orders(:upcoming_confirmed_future)
      order.discounted_price = nil

      expect(order.subsidy).to be_nil
    end
  end

  describe "#cancellation_block_reason" do
    it "lets a pending order be cancelled even on its delivery day" do
      expect(orders(:upcoming_pending_today)).to be_cancellable
    end

    it "lets a confirmed order be cancelled while its delivery day is still ahead" do
      expect(orders(:upcoming_confirmed_future)).to be_cancellable
    end

    it "blocks a confirmed order once its delivery day arrived" do
      order = orders(:upcoming_pending_today)
      order.update!(status: :confirmed)

      expect(order).not_to be_cancellable
      expect(order.cancellation_block_reason).to eq("confirmed_for_today")
    end

    it "blocks a confirmed order whose delivery day already passed" do
      expect(orders(:history_confirmed_past).cancellation_block_reason).to eq("already_closed")
    end

    it "blocks orders that are already cancelled or rejected" do
      expect(orders(:history_cancelled_future).cancellation_block_reason).to eq("already_closed")
      expect(orders(:history_rejected_future).cancellation_block_reason).to eq("already_closed")
    end

    it "blocks a pending order whose delivery day already passed" do
      expect(orders(:history_pending_past).cancellation_block_reason).to eq("already_closed")
    end

    it "blocks an order left without a delivery date whatever its status" do
      order = orders(:history_without_schedule)

      expect(order.cancellation_block_reason).to eq("unavailable")

      order.status = :confirmed
      expect(order.cancellation_block_reason).to eq("unavailable")
    end
  end

  describe "#cancel" do
    let(:employee) { users(:one) }

    it "records the new state, who cancelled it, when, and the state it came from" do
      order = orders(:upcoming_confirmed_future)

      expect(order.cancel(by: employee)).to be(true)

      order.reload
      expect(order).to be_cancelled
      expect(order.cancelled_by).to eq(employee)
      expect(order.cancelled_at).to be_present
      expect(order.status_before_cancellation).to eq("confirmed")
    end

    it "gives the reserved units back to the schedule" do
      order = orders(:upcoming_confirmed_future)

      expect { order.cancel(by: employee) }
        .to change { order.schedule.reload.remaining_amount }.by(order.amount)
    end

    it "ignores a second cancellation instead of overwriting the first one" do
      order = orders(:upcoming_confirmed_future)
      order.cancel(by: employee)
      cancelled_at = order.reload.cancelled_at

      expect(order.cancel(by: employee)).to be(false)
      expect(order.reload.cancelled_at).to eq(cancelled_at)
    end

    it "refuses to cancel a confirmed order on its delivery day" do
      order = orders(:upcoming_pending_today)
      order.update!(status: :confirmed)

      expect(order.cancel(by: employee)).to be(false)
      expect(order.reload).to be_confirmed
    end

    it "refuses to cancel a pending order whose delivery day already passed" do
      order = orders(:history_pending_past)

      expect(order.cancel(by: employee)).to be(false)
      expect(order.reload).to be_pending
    end

    it "returns false instead of raising when the order no longer passes its validations" do
      order = orders(:upcoming_pending_future)
      order.update_column(:amount, nil)

      expect(order.cancel(by: employee)).to be(false)
      expect(order.reload).to be_pending
    end
  end

  describe "#withdraw!" do
    let(:provider_user) { users(:provider_user) }

    it "cancels a pending order and records provider, time and previous status" do
      order = orders(:upcoming_pending_future)

      expect(order.withdraw!(by: provider_user)).to be(true)

      order.reload
      expect(order).to be_cancelled
      expect(order.cancelled_by).to eq(provider_user)
      expect(order.cancelled_at).to be_present
      expect(order.status_before_cancellation).to eq("pending")
    end

    it "cancels a confirmed order and records provider, time and previous status" do
      order = orders(:upcoming_confirmed_future)

      expect(order.withdraw!(by: provider_user)).to be(true)

      order.reload
      expect(order).to be_cancelled
      expect(order.cancelled_by).to eq(provider_user)
      expect(order.cancelled_at).to be_present
      expect(order.status_before_cancellation).to eq("confirmed")
    end

    it "allows withdrawing a confirmed order even on its delivery day" do
      order = orders(:upcoming_pending_today)
      order.update!(status: :confirmed)

      expect(order.withdraw!(by: provider_user)).to be(true)
      expect(order.reload).to be_cancelled
      expect(order.status_before_cancellation).to eq("confirmed")
    end

    it "ignores withdrawal on an already cancelled order" do
      order = orders(:history_cancelled_future)
      original_cancelled_at = order.cancelled_at
      original_cancelled_by = order.cancelled_by

      expect(order.withdraw!(by: provider_user)).to be(false)
      expect(order.reload.cancelled_at).to eq(original_cancelled_at)
      expect(order.cancelled_by).to eq(original_cancelled_by)
    end

    it "ignores withdrawal on an already rejected order" do
      order = orders(:history_rejected_future)

      expect(order.withdraw!(by: provider_user)).to be(false)
      expect(order.reload).to be_rejected
    end
  end

  describe "#decide" do
    it "confirms a pending order and returns true" do
      order = orders(:upcoming_pending_today)

      expect(order.decide(:confirmed)).to be(true)
      expect(order.reload).to be_confirmed
    end

    it "rejects a pending order with a valid reason and returns true" do
      order = orders(:upcoming_pending_today)

      expect(order.decide(:rejected, reason: :out_of_stock)).to be(true)
      expect(order.reload).to be_rejected
      expect(order.rejection_reason).to eq("out_of_stock")
      expect(order.rejection_details).to be_nil
    end

    it "rejects a pending order with 'other' reason and details" do
      order = orders(:upcoming_pending_today)

      expect(order.decide(:rejected, reason: :other, details: "Cocina cerrada")).to be(true)
      expect(order.reload).to be_rejected
      expect(order.rejection_reason).to eq("other")
      expect(order.rejection_details).to eq("Cocina cerrada")
    end

    it "refuses to reject without a reason" do
      order = orders(:upcoming_pending_today)

      expect(order.decide(:rejected)).to be(false)
      expect(order.reload).to be_pending
      expect(order.errors[:rejection_reason]).to be_present
    end

    it "refuses to reject with 'other' reason when details are missing" do
      order = orders(:upcoming_pending_today)

      expect(order.decide(:rejected, reason: :other)).to be(false)
      expect(order.reload).to be_pending
      expect(order.errors[:rejection_details]).to be_present
    end

    it "gives reserved units back to the schedule when rejected" do
      order = orders(:upcoming_pending_today)

      expect { order.decide(:rejected, reason: :out_of_stock) }
        .to change { order.schedule.reload.remaining_amount }.by(order.amount)
    end

    it "rejects a confirmed order with a valid reason and returns true" do
      order = orders(:upcoming_confirmed_future)

      expect(order.decide(:rejected, reason: :out_of_stock)).to be(true)
      expect(order.reload).to be_rejected
      expect(order.rejection_reason).to eq("out_of_stock")
    end

    it "refuses to reject a confirmed order without a reason" do
      order = orders(:upcoming_confirmed_future)

      expect(order.decide(:rejected)).to be(false)
      expect(order.reload).to be_confirmed
    end

    it "refuses to confirm an already confirmed order and returns false" do
      order = orders(:upcoming_confirmed_future)

      expect(order.decide(:confirmed)).to be(false)
      expect(order.reload).to be_confirmed
    end

    it "refuses to reject an already cancelled order and returns false" do
      order = orders(:history_cancelled_future)

      expect(order.decide(:rejected, reason: :out_of_stock)).to be(false)
      expect(order.reload).to be_cancelled
    end

    it "refuses to decide an already cancelled order and returns false" do
      order = orders(:history_cancelled_future)

      expect(order.decide(:confirmed)).to be(false)
      expect(order.reload).to be_cancelled
    end

    it "refuses to decide an already rejected order and returns false" do
      order = orders(:history_rejected_future)

      expect(order.decide(:confirmed)).to be(false)
      expect(order.reload).to be_rejected
    end
  end

  describe "#ensure_accounts!" do
    let(:consumer) { consumers(:one) }
    let(:provider) { providers(:tuviandita) }
    let(:month) { Date.current.beginning_of_month }

    def account_for(owner)
      owner.accounts.find_by(provider:, month:)
    end

    def build_order(status:, **attributes)
      Order.new(
        consumer:,
        schedule: schedules(:future),
        amount: 1,
        price: 300.50,
        discounted_price: 150.25,
        address: companies(:gogrow).address,
        delivery_method: :office,
        status:,
        **attributes
      )
    end

    def create_order(status:, **attributes)
      build_order(status:, **attributes).tap(&:save!)
    end

    it "assigns the order to the account of the employee and to the one of their company" do
      order = create_order(status: :confirmed)

      expect(order.accounts).to contain_exactly(account_for(consumer), account_for(consumer.company))
    end

    it "charges the employee their part and the company the subsidy" do
      expect { create_order(status: :confirmed) }
        .to change { account_for(consumer).amount }.by(150.25.to_d)
        .and change { account_for(consumer.company).amount }.by(150.25.to_d)
    end

    it "does not charge anything while the order is pending" do
      expect { create_order(status: :pending) }.not_to change { account_for(consumer).amount }
      expect { create_order(status: :pending) }.not_to change { account_for(consumer.company).amount }
    end

    it "updates both accounts when the order is confirmed" do
      order = create_order(status: :pending)

      expect { order.update!(status: :confirmed) }
        .to change { account_for(consumer).amount }.by(150.25.to_d)
        .and change { account_for(consumer.company).amount }.by(150.25.to_d)
    end

    it "discounts both accounts when the order is cancelled" do
      order = create_order(status: :confirmed)

      expect { order.cancel(by: users(:one)) }
        .to change { account_for(consumer).amount }.by(-150.25.to_d)
        .and change { account_for(consumer.company).amount }.by(-150.25.to_d)
    end

    it "does not duplicate accounts when it runs again" do
      order = create_order(status: :confirmed)

      expect { order.ensure_accounts! }.not_to change(Account, :count)
      expect(order.reload.accounts.count).to eq(2)
    end

    it "keeps an old order in the accounts of the month it will be delivered" do
      order = create_order(status: :confirmed, created_at: 1.month.ago)

      expect { order.ensure_accounts! }.not_to change(Account, :count)
      expect(order.reload.accounts.map(&:month).uniq).to eq([ schedules(:future).date.beginning_of_month ])
    end

    it "completes the missing company account of an old order in its own month" do
      order = create_order(status: :confirmed, created_at: 1.month.ago)
      order.order_accounts.joins(:account).where(accounts: { owner_type: "Company" }).delete_all
      order.accounts.reset

      order.ensure_accounts!

      month = schedules(:future).date.beginning_of_month
      expect(order.reload.accounts.map { [ it.owner_type, it.month ] }).to contain_exactly(
        [ "Consumer", month ], [ "Company", month ]
      )
    end

    it "takes the account another order created at the same time instead of failing" do
      order = build_order(status: :confirmed)
      company = order.consumer.company
      # Simula la carrera: la búsqueda no ve la cuenta y el INSERT choca con el
      # índice único porque otro pedido ya la creó.
      allow(company.accounts).to receive(:find_by).and_return(nil)

      expect { order.save! }.not_to raise_error
      expect(order.accounts).to include(accounts(:gogrow_tuviandita_current))
    end
  end

  it "splits every order between the two sections" do
    expect(described_class.upcoming.ids & described_class.history.ids).to be_empty
    expect(described_class.upcoming.count + described_class.history.count).to eq(described_class.count)
  end

  describe "#max_quantity" do
    it "returns the order amount when schedule is nil" do
      order = orders(:history_without_schedule)
      expect(order.schedule).to be_nil
      expect(order.max_quantity).to eq(order.amount)
    end

    it "returns the sum of remaining amount and current order amount when schedule is present" do
      order = orders(:upcoming_pending_future)
      expect(order.max_quantity).to eq(order.schedule.remaining_amount + order.amount)
    end
  end

  describe "#delivery_address_options" do
    let(:consumer) { consumers(:one) }

    it "returns only the office address when the provider does not allow home delivery" do
      order = Order.new(consumer:, schedule: schedules(:office), address: consumer.address)
      expect(order.provider.home_delivery?).to be(false)

      expect(order.delivery_address_options(consumer)).to eq([
        { id: "office", label: I18n.t("pages.orders.addresses.office"), address: consumer.company.address }
      ])
    end

    it "returns consumer options when order address is blank and provider allows home delivery" do
      order = Order.new(consumer:, schedule: schedules(:future), address: nil)
      expect(order.delivery_address_options(consumer)).to eq(consumer.delivery_address_options)
    end

    it "returns consumer options without duplicate when order address is already in consumer options" do
      order = Order.new(consumer:, schedule: schedules(:future), address: consumer.address)
      expect(order.delivery_address_options(consumer)).to eq(consumer.delivery_address_options)
    end

    it "appends the current address option when order address is not in consumer options" do
      order = Order.new(consumer:, schedule: schedules(:future), address: "Rambla Gandhi 123")
      options = order.delivery_address_options(consumer)

      expect(options.last).to eq(
        id: "current",
        label: I18n.t("pages.orders.addresses.current"),
        address: "Rambla Gandhi 123"
      )
    end
  end

  describe "#reject_for_dish_change!" do
    let(:order) { orders(:upcoming_confirmed_future) }

    it "rejects confirmed order with dish_modified reason" do
      expect(order.reject_for_dish_change!).to be(true)
      expect(order.reload).to be_rejected
      expect(order).to be_rejection_reason_dish_modified
    end

    it "does not reject pending, cancelled or already rejected orders" do
      pending_order = orders(:upcoming_pending_today)
      cancelled_order = orders(:history_cancelled_future)
      rejected_order = orders(:history_rejected_future)

      expect(pending_order.reject_for_dish_change!).to be(false)
      expect(pending_order.reload).to be_pending

      expect(cancelled_order.reject_for_dish_change!).to be(false)
      expect(cancelled_order.reload).to be_cancelled

      expect(rejected_order.reject_for_dish_change!).to be(false)
      expect(rejected_order.reload).to be_rejected
    end
  end

  describe "menu snapshotting" do
    let(:schedule) { schedules(:future) }

    it "captures menu snapshot upon creation" do
      order = Order.create!(
        consumer: consumers(:one),
        schedule:,
        delivery_method: :office,
        amount: 1,
        price: 300
      )

      expect(order.menu_name).to eq(schedule.menu.name)
      expect(order.menu_description).to eq(schedule.menu.description)
      expect(order.menu_option_groups).to eq(schedule.menu.option_groups_snapshot)
    end

    it "falls back to schedule menu attributes when snapshot columns are nil" do
      order = Order.new(schedule:, menu_name: nil, menu_description: nil, menu_option_groups: nil)

      expect(order.menu_name).to eq(schedule.menu.name)
      expect(order.menu_description).to eq(schedule.menu.description)
      expect(order.menu_option_groups).to eq(schedule.menu.option_groups_snapshot)
    end
  end

  describe "notifications" do
    let!(:notification_configuration) do
      Notification::Configuration.find_or_create_by!(key: "order_updates") do |configuration|
        configuration.roles = %w[consumer]
      end
    end

    it "notifies the consumer when the provider rejects an order" do
      order = orders(:upcoming_pending_today)

      expect {
        order.decide(:rejected, reason: :out_of_stock)
      }.to change(Notification, :count).by(1)

      notification = Notification.order(:created_at).last

      expect(notification).to have_attributes(
        user: order.consumer.user,
        event: "order_rejection",
        role: "consumer",
        requires_action: false,
        notifiable: order
      )

      expect(notification.title).to eq("Tu pedido fue cancelado")
      expect(notification.description).to include("no había stock disponible")
    end

    it "uses the rejection details when the provider selects other" do
      order = orders(:upcoming_pending_today)

      order.decide(
        :rejected,
        reason: :other,
        details: "Cocina cerrada"
      )

      notification = Notification.order(:created_at).last

      expect(notification.event).to eq("order_rejection")
      expect(notification.description).to include(
        "por el siguiente motivo: Cocina cerrada."
      )
    end

    it "notifies the consumer when an order is rejected because the dish changed" do
      order = orders(:upcoming_confirmed_future)

      expect {
        order.reject_for_dish_change!
      }.to change(Notification, :count).by(1)

      notification = Notification.order(:created_at).last

      expect(notification.event).to eq("order_rejection")
      expect(notification.user).to eq(order.consumer.user)
      expect(notification.notifiable).to eq(order)
      expect(notification.description).to include("porque el plato fue modificado")
    end

    it "notifies the consumer when the provider withdraws the dish" do
      order = orders(:upcoming_pending_future)
      provider_user = users(:provider_user)

      expect {
        order.withdraw!(by: provider_user)
      }.to change(Notification, :count).by(1)

      notification = Notification.order(:created_at).last

      expect(notification).to have_attributes(
        user: order.consumer.user,
        event: "order_withdrawal",
        role: "consumer",
        requires_action: false,
        notifiable: order
      )

      expect(notification.description).to include(
        "porque el plato dejó de estar disponible"
      )
    end

    it "does not create these notifications when the consumer cancels their own order" do
      order = orders(:upcoming_pending_future)

      expect {
        order.cancel(by: order.consumer.user)
      }.not_to change(Notification, :count)
    end
  end

  describe "confirmation notification" do
    def confirmation_notifications(order)
      Notification.where(event: "order_confirmation", notifiable: order)
    end

    it "notifies only the employee who placed the order, once" do
      order = orders(:upcoming_pending_today)

      order.decide(:confirmed)

      notifications = confirmation_notifications(order)
      expect(notifications.count).to eq(1)
      expect(notifications.first.user).to eq(users(:one))
      expect(notifications.first.role).to eq("consumer")
      expect(users(:other_consumer_user).notifications).to be_empty
    end

    # Ver DEFECT-notificacion-confirmado-sin-plato-ni-pedido-08-10-2026.md:
    # el criterio 3 pide también el plato y el identificador del pedido.
    it "names the delivery date and the provider" do
      order = orders(:upcoming_pending_today)

      order.decide(:confirmed)

      description = confirmation_notifications(order).first.description
      expect(description).to include(I18n.l(order.schedule.date, format: :short))
      expect(description).to include(users(:provider_user).name)
    end

    it "does not notify twice when the order is confirmed again" do
      order = orders(:upcoming_pending_today)
      order.decide(:confirmed)

      expect(order.decide(:confirmed)).to be(false)
      expect(confirmation_notifications(order).count).to eq(1)
    end

    it "does not confirm nor notify an order the employee already cancelled" do
      order = orders(:history_cancelled_future)

      expect(order.decide(:confirmed)).to be(false)
      expect(order.reload).to be_cancelled
      expect(confirmation_notifications(order)).to be_empty
    end

    it "does not notify a confirmation when the employee cancels" do
      order = orders(:upcoming_pending_future)

      order.cancel(by: users(:one))

      expect(order.reload).to be_cancelled
      expect(confirmation_notifications(order)).to be_empty
    end

    # Ver DEFECT-falla-de-notificacion-solo-queda-en-el-log-08-10-2026.md: el
    # criterio 4 pide además que el fallo quede registrado para reintento.
    it "keeps the order confirmed when the notification cannot be saved" do
      order = orders(:upcoming_pending_today)
      allow(Notification).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(Notification.new))

      expect(order.decide(:confirmed)).to be(true)
      expect(order.reload).to be_confirmed
      expect(confirmation_notifications(order)).to be_empty
    end
  end

  # IBP-037: cada beneficio registra cuántas viandas de la orden cubrió, y al
  # modificarla se recalcula con los usos que la propia orden ya tenía.
  describe "#modify with special subsidies" do
    around do |example|
      travel_to(Time.zone.local(2026, 9, 14, 10)) { example.run }
    end

    let(:consumer) { consumers(:one) }
    let(:menu) { Menu.create!(provider: providers(:tuviandita), name: "Milanesa", description: "Con puré", price: 300) }
    let(:schedule) { Schedule.create!(menu:, date: Date.new(2026, 9, 16), amount: 20) }
    let(:delivery) { { delivery_method: "office", address: companies(:gogrow).address } }
    let!(:base) do
      consumer.benefits.destroy_all
      consumer.benefits.create!(
        benefit_configuration: benefit_configurations(:monthly), percentage: 50, amount: 1, due_date: Date.new(2026, 9, 30)
      )
    end
    let!(:special) do
      consumer.benefits.create!(benefit_configuration: benefit_configurations(:gift), description: "Premio", percentage: 30, amount: 2)
    end

    def place(quantity)
      line = OrderPricing.new(consumer).call([ { schedule:, quantity: } ]).first
      Order.reserve(
        consumer:, schedule:, quantity:, delivery_method: :office, address: nil,
        discounted_price: line.discounted_price, benefits: line.benefits
      )
    end

    def modify(order, quantity)
      order.modify(by: users(:one), quantity:, notes: nil, delivery:)
    end

    it "records how many meals each benefit covered" do
      order = place(3)

      # 1ª base + premio (60), 2ª solo premio (210), 3ª a precio completo.
      expect(order.discounted_price).to eq(570)
      expect(order.order_benefits.pluck(:benefit_id, :benefit_used)).to contain_exactly([ base.id, 1 ], [ special.id, 2 ])
    end

    it "charges the company the base and the special subsidy once confirmed" do
      order = place(3)
      order.decide(:confirmed)

      expect(order.accounts.find { it.owner == consumer }.reload.amount).to eq(570)
      expect(order.accounts.find { it.owner == consumer.company }.reload.amount).to eq(330)
    end

    it "raises the quantity without spending its own uses twice" do
      order = place(1)

      expect(modify(order, 3)).to be(true)

      expect(order.reload.discounted_price).to eq(570)
      expect(order.order_benefits.pluck(:benefit_id, :benefit_used)).to contain_exactly([ base.id, 1 ], [ special.id, 2 ])
    end

    it "lowers the quantity and gives the uses back" do
      order = place(3)

      expect(modify(order, 1)).to be(true)

      expect(order.reload.discounted_price).to eq(60)
      expect(order.order_benefits.pluck(:benefit_id, :benefit_used)).to contain_exactly([ base.id, 1 ], [ special.id, 1 ])
      expect(OrderPricing.new(consumer).remaining_uses(special)).to eq(1)
    end

    it "adds a special assigned after the order was placed" do
      special.destroy
      order = place(1)
      seniority = consumer.benefits.create!(benefit_configuration: benefit_configurations(:seniority), description: "Antigüedad", percentage: 10)

      modify(order, 1)

      expect(order.reload.discounted_price).to eq(120)
      expect(order.order_benefits.pluck(:benefit_id)).to contain_exactly(base.id, seniority.id)
    end

    it "drops a special that no longer applies" do
      order = place(1)
      benefit_configurations(:gift).deactivate!(by: users(:admin))

      modify(order, 1)

      expect(order.reload.discounted_price).to eq(150)
      expect(order.order_benefits.pluck(:benefit_id)).to contain_exactly(base.id)
    end
  end

  describe "cancelling or rejecting an order with a special subsidy" do
    around do |example|
      travel_to(Time.zone.local(2026, 9, 14, 10)) { example.run }
    end

    let(:consumer) { consumers(:one) }
    let(:schedule) { Schedule.create!(menu: menus(:milanesa), date: Date.new(2026, 9, 16), amount: 20) }
    let(:special) do
      consumer.benefits.create!(benefit_configuration: benefit_configurations(:gift), description: "Premio", percentage: 30, amount: 1)
    end
    let(:order) do
      line = OrderPricing.new(consumer).call([ { schedule:, quantity: 1 } ]).first
      Order.reserve(
        consumer:, schedule:, delivery_method: :office, address: nil,
        discounted_price: line.discounted_price, benefits: line.benefits
      )
    end

    before do
      consumer.benefits.destroy_all
      special
    end

    it "spends the use while the order is pending or confirmed" do
      order
      expect(OrderPricing.new(consumer).remaining_uses(special)).to eq(0)

      order.decide(:confirmed)
      expect(OrderPricing.new(consumer).remaining_uses(special)).to eq(0)
    end

    it "frees the use when the employee cancels" do
      order.cancel(by: users(:one))

      expect(OrderPricing.new(consumer).remaining_uses(special)).to eq(1)
    end

    it "frees the use when the provider rejects" do
      order.decide(:rejected, reason: :out_of_stock)

      expect(OrderPricing.new(consumer).remaining_uses(special)).to eq(1)
    end
  end
end

# == Schema Information
#
# Table name: orders
#
#  id                         :bigint           not null, primary key
#  address                    :string
#  amount                     :integer
#  cancelled_at               :datetime
#  delivery_method            :integer          not null
#  discounted_price           :decimal(10, 2)
#  menu_description           :string
#  menu_name                  :string
#  menu_option_groups         :jsonb
#  modified_at                :datetime
#  notes                      :string
#  price                      :decimal(10, 2)
#  rejection_details          :string
#  rejection_reason           :integer
#  selected_options           :jsonb            not null
#  status                     :integer          default(0), not null
#  status_before_cancellation :integer
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  cancelled_by_id            :bigint
#  consumer_id                :bigint           not null
#  modified_by_id             :bigint
#  schedule_id                :bigint
#
# Indexes
#
#  index_orders_on_cancelled_by_id  (cancelled_by_id)
#  index_orders_on_consumer_id      (consumer_id)
#  index_orders_on_modified_by_id   (modified_by_id)
#  index_orders_on_schedule_id      (schedule_id)
#
# Foreign Keys
#
#  fk_rails_...  (cancelled_by_id => users.id)
#  fk_rails_...  (consumer_id => consumers.id)
#  fk_rails_...  (modified_by_id => users.id)
#  fk_rails_...  (schedule_id => schedules.id)
#
