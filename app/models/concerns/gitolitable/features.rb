# frozen_string_literal: true

module Gitolitable
  module Features
    extend ActiveSupport::Concern

    # Always true to force repository fetch_changesets.
    def report_last_commit
      true
    end

    # Always true to force repository fetch_changesets.
    def extra_report_last_commit
      true
    end

    def git_default_branch
      git_extra&.default_branch || 'main'
    end

    def gitolite_hook_key
      git_extra&.key || false
    end

    def git_daemon_enabled?
      git_extra&.fetch(:git_annex, false) || false
    end

    def git_annex_enabled?
      git_extra&.git_annex || false
    end

    def git_notification_enabled?
      git_extra&.git_notify || false
    end

    def git_ssh_enabled?
      git_extra&.git_ssh || false
    end

    def git_go_enabled?
      git_extra&.git_go || false
    end

    def https_access_enabled?
      git_extra&.git_https || false
    end

    def http_access_enabled?
      git_extra&.git_http || false
    end

    def smart_http_enabled?
      https_access_enabled? || http_access_enabled?
    end

    def only_https_access_enabled?
      https_access_enabled? && !http_access_enabled?
    end

    def only_http_access_enabled?
      http_access_enabled? && !https_access_enabled?
    end

    def protected_branches_enabled?
      git_extra&.protected_branch || false
    end

    def public_project?
      project.is_public?
    end

    def public_repo?
      git_extra&.public_repo || false
    end

    def urls_order
      git_extra&.urls_order || false
    end
  end
end
