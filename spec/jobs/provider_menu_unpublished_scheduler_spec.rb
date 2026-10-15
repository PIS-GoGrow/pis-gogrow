# frozen_string_literal: true

require "rails_helper"
require "tempfile"

RSpec.describe "Scheduler de recordatorios de menú", type: :job do
  self.use_transactional_tests = false

  fixtures :users, :providers, :menus, :benefits

  let(:production_tasks) { YAML.safe_load(Rails.root.join("config/recurring.yml").read).fetch("production") }
  let(:task_key) { "provider_menu_unpublished_reminders" }
  let(:task) { SolidQueue::RecurringTask.from_configuration(task_key, **production_tasks.fetch(task_key).symbolize_keys) }

  around do |example|
    previous_adapters = [ ProviderMenuUnpublishedRemindersJob, BenefitUpdateJob, BenefitAssignationJob ].index_with(&:queue_adapter)
    previous_adapters.each_key { it.queue_adapter = :solid_queue }
    example.run
  ensure
    previous_adapters.each { |job, adapter| job.queue_adapter = adapter }
  end

  before do
    travel_to Time.zone.local(2030, 1, 9, 10)
    allow(WhatsappSenderJob).to receive(:perform_later).and_raise("No se permiten envíos externos en esta prueba")
  end

  after do
    Notification.where(event: :provider_menu_unpublished).delete_all
    SolidQueue::Job.where(class_name: %w[ProviderMenuUnpublishedRemindersJob BenefitUpdateJob BenefitAssignationJob]).delete_all
    SolidQueue::Process.where(name: "pr127-scheduler-spec").delete_all
  end

  it "valida todas las tareas recurrentes y configura scheduler y worker como en producción" do
    queue_options = ActiveSupport::ConfigurationFile.parse(Rails.root.join("config/queue.yml")).fetch("production").deep_symbolize_keys
    Tempfile.create([ "pr127-recurring", ".yml" ]) do |file|
      file.write({ Rails.env => production_tasks }.to_yaml)
      file.flush
      configuration = SolidQueue::Configuration.new(
        **queue_options,
        recurring_schedule_file: file.path,
        mode: :async,
        standalone: false
      )

      expect(configuration).to be_valid
      expect(configuration.configured_processes.map(&:kind)).to contain_exactly(:scheduler, :dispatcher, :worker)
      scheduler = configuration.configured_processes.find { it.kind == :scheduler }
      expect(scheduler.attributes.fetch(:recurring_tasks).map(&:key))
        .to include("benefit_expiration", task_key, "provider_menu_unpublished_notifications_cleanup")
    end
  end

  it "programa BenefitUpdateJob todos los días a medianoche de Montevideo" do
    benefit_task = SolidQueue::RecurringTask.from_configuration("benefit_expiration", **production_tasks.fetch("benefit_expiration").symbolize_keys)

    expect(benefit_task.class_name).to eq("BenefitUpdateJob")
    expect(benefit_task.next_time_after(Time.utc(2030, 1, 12, 2, 59, 59))).to eq(Time.utc(2030, 1, 12, 3))
    expect(benefit_task.next_time_after(Time.utc(2030, 1, 12, 3))).to eq(Time.utc(2030, 1, 13, 3))
  end

  it "ejecuta la tarea de beneficios desde la cola y asigna después de expirar y activar" do
    past_benefit = benefits(:monthly)
    future_benefit = benefits(:future)
    past_benefit.update!(due_date: Date.current - 1.day)
    future_benefit.update!(due_date: Date.current + 1.day)
    benefit_key = "benefit_expiration"
    benefit_task = SolidQueue::RecurringTask.from_configuration(benefit_key, **production_tasks.fetch(benefit_key).symbolize_keys)
    schedule = SolidQueue::Scheduler.new(recurring_tasks: [ benefit_task ]).recurring_schedule
    timer = schedule.schedule_task(benefit_task, run_at: Time.current)

    expect(timer.wait(5)).to be_fulfilled
    expect(timer.reason).to be_nil
    job = SolidQueue::RecurringExecution.find_by!(task_key: benefit_key, run_at: Time.current).job
    expect(job).to have_attributes(class_name: "BenefitUpdateJob", queue_name: "default")

    process = SolidQueue::Process.register(kind: "Worker", name: "pr127-scheduler-spec", pid: Process.pid, hostname: Socket.gethostname)
    execution = SolidQueue::ReadyExecution.claim([ "default" ], 1, process.id).sole
    expect(execution.job).to eq(job)
    execution.perform

    expect(job.reload.finished_at).to be_present
    expect(past_benefit.reload).to be_expired
    expect(future_benefit.reload).to be_current

    assignment = SolidQueue::ReadyExecution.claim([ "default" ], 1, process.id).sole
    expect(assignment.job.class_name).to eq("BenefitAssignationJob")
    assignment.perform

    expect(assignment.job.reload.finished_at).to be_present
    expect(future_benefit.reload).to be_current
    expect(Benefit.monthly.current.where(consumer: future_benefit.consumer).count).to eq(1)
  ensure
    schedule&.unschedule_tasks
  end

  it "interpreta las 10:00 locales en UTC y omite el fin de semana" do
    expect(task.next_time_after(Time.utc(2030, 1, 11, 12, 59, 59))).to eq(Time.utc(2030, 1, 11, 13))
    expect(task.next_time_after(Time.utc(2030, 1, 11, 13))).to eq(Time.utc(2030, 1, 14, 13))

    cleanup_key = "provider_menu_unpublished_notifications_cleanup"
    cleanup = SolidQueue::RecurringTask.from_configuration(cleanup_key, **production_tasks.fetch(cleanup_key).symbolize_keys)
    expect(cleanup.next_time_after(Time.utc(2030, 1, 12, 3, 4, 59))).to eq(Time.utc(2030, 1, 12, 3, 5))
  end

  it "dispara el temporizador real, encola el job configurado y lo ejecuta desde la cola" do
    schedule = SolidQueue::Scheduler.new(recurring_tasks: [ task ]).recurring_schedule
    timer = schedule.schedule_task(task, run_at: Time.current)

    expect(timer.wait(5)).to be_fulfilled
    expect(timer.reason).to be_nil
    recurring_execution = SolidQueue::RecurringExecution.find_by!(task_key:, run_at: Time.current)
    job = recurring_execution.job
    expect(job).to have_attributes(class_name: "ProviderMenuUnpublishedRemindersJob", queue_name: "default")

    process = SolidQueue::Process.register(kind: "Worker", name: "pr127-scheduler-spec", pid: Process.pid, hostname: Socket.gethostname)
    execution = SolidQueue::ReadyExecution.claim([ "default" ], 1, process.id).sole

    expect { execution.perform }.to change(Notification.where(event: :provider_menu_unpublished), :count).by(3)
    expect(job.reload.finished_at).to be_present
  ensure
    schedule&.unschedule_tasks
  end

  it "registra un solo job cuando dos schedulers intentan encolar la misma ocurrencia" do
    run_at = Time.current
    ready = Queue.new
    start = Queue.new
    tasks = 2.times.map { SolidQueue::RecurringTask.from_configuration(task_key, **production_tasks.fetch(task_key).symbolize_keys) }
    threads = tasks.map do |scheduled_task|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << true
          start.pop
          scheduled_task.enqueue(at: run_at)
        end
      end
    end

    2.times { ready.pop }
    2.times { start << true }
    threads.each(&:value)

    expect(SolidQueue::Job.where(class_name: "ProviderMenuUnpublishedRemindersJob").count).to eq(1)
    expect(SolidQueue::RecurringExecution.where(task_key:, run_at:).count).to eq(1)
  end
end
