require 'fileutils'

namespace :protobuf do

  desc 'Clean & Compile the protobuf source to ruby classes. Pass PB_NO_CLEAN=1 if you do not want to force-clean first.'
  task :compile, [ :package, :source, :destination, :plugin, :file_extension ] do |tasks, args|
    args.with_defaults(:destination => 'lib')
    args.with_defaults(:source => 'definitions')
    args.with_defaults(:plugin => 'ruby')
    args.with_defaults(:file_extension => '.pb.rb')

    unless do_not_clean?
      force_clean!
      ::Rake::Task[:clean].invoke(args[:package], args[:destination], args[:file_extension])
    end

    command = []
    command << "protoc"
    command << "--#{args[:plugin]}_out=#{args[:destination]}"
    command << "-I #{args[:source]}"
    command << "#{args[:source]}/#{args[:package]}/*.proto"
    command << "#{args[:source]}/#{args[:package]}/**/*.proto"
    full_command = command.join(' ')

    puts full_command
    exec(full_command)
  end

  desc 'Clean the generated *.pb.rb files from the destination package. Pass PB_FORCE_CLEAN=1 to skip confirmation step.'
  task :clean, [ :package, :destination, :file_extension ] do |task, args|
    args.with_defaults(:destination => 'lib')
    args.with_defaults(:file_extension => '.pb.rb')

    file_extension = args[:file_extension].sub(/\*?\.+/, '')
    files_to_clean = ::File.join(args[:destination], args[:package], '**', "*.#{file_extension}")

    if force_clean? || permission_to_clean?(files_to_clean)
      ::Dir.glob(files_to_clean).each do |file|
        ::FileUtils.rm(file)
      end
    end
  end

  def do_not_clean?
    ! ::ENV.key?('PB_NO_CLEAN')
  end

  def force_clean?
    ::ENV.key?('PB_FORCE_CLEAN')
  end

  def force_clean!
    ::ENV['PB_FORCE_CLEAN'] = '1'
  end

  def permission_to_clean?(files_to_clean)
    puts "Do you really want to remove files matching pattern #{files_to_clean}? (y/n)"
    ::STDIN.gets.chomp =~ /y(es)?/i
  end

end
