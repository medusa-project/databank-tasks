include DatabankTasks

namespace :hub do

  desc 'do pending tasks'
  task process_pending: :environment do
    tasks_in_process = Task.where(status: TaskStatus::PROCESSING)
    # wait for the last batch to finish
    if tasks_in_process.count == 0
      Task.where(status: TaskStatus::PENDING).each do |task|
        puts "task #{task.id}"
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

  desc 'change processing to pending after interruption'
  task processing2pending: :environment do
    Task.where(status: TaskStatus::PROCESSING).each do |task|
      task.status = TaskStatus::PENDING
      task.save
    end
  end

end
