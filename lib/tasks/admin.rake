include DatabankTasks

namespace :admin do
  task reset_all: :environment do
    Task.all.destroy_all
    Problem.all.destroy_all
  end
end