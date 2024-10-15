# frozen_string_literal: true

class GithostingShellWorker
  include Sidekiq::Worker

  sidekiq_options queue: :redmine_git_hosting, retry: false

  def self.maybe_do(command, object, options)
    Sidekiq.logger.info "Command: #{command.inspect}, Object: #{object.inspect}, Options: #{options.inspect}"


    # Convert all Symbols in the options hash to Strings
#    options = options.transform_keys(&:to_s).transform_values do |v|
#      v.is_a?(Symbol) ? v.to_s : v
#    end

    command = command.to_s
    object = object.stringify_keys if object.respond_to?(:stringify_keys)
    options = options.stringify_keys if options.respond_to?(:stringify_keys)

    args = [command, object, options]
    Sidekiq::Queue.new(:redmine_git_hosting).each do |job|
      return nil if job.args == args
    end

    perform_async command, object, options
  end

  def perform(command, object, options)
#    logger.info "#{command} | #{object} | #{options}"
    object = [object] unless object.is_a?(Array)
#    RedmineGitHosting::GitoliteWrapper.resync_gitolite command, object, **options
    begin
      RedmineGitHosting::GitoliteWrapper.resync_gitolite command, object, **options
    rescue => e
      logger.error "Error performing command: #{e.message}"
      raise e  # Re-raise or handle as appropriate
    end



  end
end
