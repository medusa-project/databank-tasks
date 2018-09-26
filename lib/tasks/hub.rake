namespace :hub do

  desc 'do pending tasks'
  task process_pending: :environment do

    tasks_in_process = Task.where(status: TaskStatus::PROCESSING)

    # wait for the last batch to finish
    if tasks_in_process.count == 0
      Task.where(status: TaskStatus::PENDING).each do |task|
        task.process
      end
    end
  end

end
