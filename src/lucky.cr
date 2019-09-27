require "colorize"
require "./lucky_cli"
require "./generators/*"
require "./dev"
require "./ensure_process_runner_installed"

include LuckyCli::TextHelpers

args = ARGV.join(" ")
tasks_file = ENV.fetch("LUCKY_TASKS_FILE", "./tasks.cr")

private def task_name : String?
  ARGV.first?
end

private def task_precompiled? : Bool
  path = precompiled_task_path
  !path.nil? && File.file?(path)
end

private def precompiled_task_path : String?
  task_name.try do |name|
    "bin/lucky.#{name}"
  end
end

private def check_crystal_version_matches! : Nil
  if !ENV["SKIP_CRYSTAL_VERSION_CHECK"]
    LuckyCli::CheckCrystalVersionMatches.new.run!
  end
end

check_crystal_version_matches!

if task_name == "dev"
  LuckyCli::Dev.new.call
elsif task_name == "ensure_process_runner_installed"
  LuckyCli::EnsureProcessRunnerInstalled.new.call
elsif task_name == "gen.tasks_file"
  LuckyCli::Generators::TasksFile.run
elsif task_name == "init"
  LuckyCli::Init.run
elsif task_name == "init.custom"
  LuckyCli::CustomInit.run
elsif ["-v", "--version"].includes?(task_name)
  puts LuckyCli::VERSION
elsif task_precompiled?
  exit Process.run(
    "#{precompiled_task_path.not_nil!} #{ARGV.skip(1).join(" ")}",
    shell: true,
    input: STDIN,
    output: STDOUT,
    error: STDERR
  ).exit_status
elsif File.file?(tasks_file)
  exit Process.run(
    "crystal run #{tasks_file} -- #{args}",
    shell: true,
    input: STDIN,
    output: STDOUT,
    error: STDERR
  ).exit_status
else
  puts <<-MISSING_TASKS_FILE

  #{"You are not in a Lucky project".colorize(:red)}

  Try this...

    #{red_arrow} Run #{"lucky init".colorize(:green)} to create a Lucky project.
    #{red_arrow} Change your project's root directory to see what tasks are available.

  MISSING_TASKS_FILE
end
