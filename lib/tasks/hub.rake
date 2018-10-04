include DatabankTasks

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

  desc 'reset for testing'
  task reset: :environment do
    Task.all.each do |task|
      task.destroy
    end
  end

end
