# frozen_string_literal: true
require 'gitolite/config'

module RedmineGitHosting
  module GitoliteWrappers
    class RemoveFromLockedUsers < Base
      def call
        conf = gitolite_config

        # Remove user from locked group
        group = conf.groups['REDMINE_LOCKED_USERS']
        if group
          group.delete(object_id.to_s)
          # Remove empty group
          conf.groups.delete('REDMINE_LOCKED_USERS') if group.empty?
          gitolite_admin_repo_commit("Remove user #{object_id} from @REDMINE_LOCKED_USERS")
        end
      end
    end
  end
end
