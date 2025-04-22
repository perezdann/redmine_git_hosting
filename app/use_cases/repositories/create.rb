# frozen_string_literal: true

module Repositories
  class Create < Base
    def call
      set_repository_extra
      create_repository
    end

    private

    def set_repository_extra
      @repository.build_git_extra(git_extra_params) unless @repository.git_extra
      Rails.logger.info("After build_git_extra, git_extra: #{@repository.git_extra.attributes.inspect}")
      @repository.git_extra.urls_order ||= []
      # Force default_branch and key values
      @repository.git_extra.attributes = {
        default_branch: @repository.git_extra.default_branch.presence || 'master',
        key: @repository.git_extra.key.presence || RedmineGitHosting::Utils::Crypto.generate_secret(64)
      }
      Rails.logger.info("After setting fallbacks, git_extra: #{@repository.git_extra.attributes.inspect}")
      @repository.git_extra.save!
    end

    def default_extra_options
      enable_git_annex? ? git_annex_repository_options : standard_repository_options
    end

    def enable_git_annex?
      options[:enable_git_annex]
    end

    def standard_repository_options
      {
        git_daemon: RedmineGitHosting::Config.gitolite_daemon_by_default?,
        git_notify: RedmineGitHosting::Config.gitolite_notify_by_default?,
        git_annex: false,
        default_branch: 'master',
        key: RedmineGitHosting::Utils::Crypto.generate_secret(64)
      }.merge(smart_http_options)
    end

    def smart_http_options
      case RedmineGitHosting::Config.gitolite_http_by_default?
      when '1' # HTTPS only
        { git_https: true }
      when '2' # HTTPS and HTTP
        { git_http: true, git_https: true }
      when '3' # HTTP only
        { git_http: true }
      else
        {}
      end
    end

    def git_annex_repository_options
      {
        git_http: 0,
        git_daemon: false,
        git_notify: false,
        git_annex: true,
        default_branch: 'git-annex',
        key: RedmineGitHosting::Utils::Crypto.generate_secret(64)
      }
    end

    def create_repository
      gitolite_accessor.create_repository repository, **options
    end
  end
end
