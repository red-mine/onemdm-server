namespace :ota do
  desc "Advance staged rollouts that are due (enqueue jobs or run inline)"
  task advance: :environment do
    due = OtaConfiguration.where(rollout_strategy: 'staged', paused: false)
                          .where("rollout_current_percent < rollout_total_percent")

    count = 0
    due.find_each do |cfg|
      next unless cfg.ready_for_advance?
      # Perform inline to work without an external worker; swap to perform_later if you run a queue
      OtaRolloutAdvanceJob.perform_now(cfg.id)
      count += 1
    end

    puts "Advanced #{count} configuration(s)."
  end
end

