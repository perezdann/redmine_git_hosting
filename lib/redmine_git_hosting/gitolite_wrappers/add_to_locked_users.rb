# frozen_string_literal: true
require 'gitolite/config'

module RedmineGitHosting
  module GitoliteWrappers
    class AddToLockedUsers < Base
      def call
        conf = gitolite_config

        # Add or update the @all repository with deny rule
        all_repo = conf.repos['@all'] || Gitolite::Config::Repo.new('@all')
        conf.add_repo(all_repo) unless conf.repos['@all']
        
        # Ensure the deny permission exists
        unless all_repo.permissions['-']&.include?('@REDMINE_LOCKED_USERS')
          all_repo.permissions['-'] = ['@REDMINE_LOCKED_USERS']
        end

        # Add user to locked group
        group = conf.groups['REDMINE_LOCKED_USERS']
        if group
          group << object_id.to_s unless group.include?(object_id.to_s)
        else
          conf.add_group('REDMINE_LOCKED_USERS', [object_id.to_s])
        end

        gitolite_admin_repo_commit("Add user #{object_id} to @REDMINE_LOCKED_USERS")
      end
    end
  end
end
