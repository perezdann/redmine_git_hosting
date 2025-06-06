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
      safe_extra[:default_branch]
    end

    def gitolite_hook_key
      safe_extra[:key]
    end

    def git_daemon_enabled?
      safe_extra[:git_daemon]
    end

    def git_annex_enabled?
      safe_extra[:git_annex]
    end

    def git_notification_enabled?
      safe_extra[:git_notify]
    end

    def git_ssh_enabled?
      safe_extra[:git_ssh]
    end

    def git_go_enabled?
      safe_extra[:git_go]
    end

    def https_access_enabled?
      safe_extra[:git_https]
    end

    def http_access_enabled?
      safe_extra[:git_http]
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
      safe_extra[:protected_branch]
    end

    def public_project?
      project.is_public?
    end

    def public_repo?
      safe_extra[:public_repo]
    end

    def urls_order
      safe_extra[:urls_order]
    end

    private

    def safe_extra
      extra || {}
    end
  end
end
