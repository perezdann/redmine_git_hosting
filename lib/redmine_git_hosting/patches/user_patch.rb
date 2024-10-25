# frozen_string_literal: true
require 'gitolite'

module RedmineGitHosting
  module Patches
    module UserPatch
      def self.prepended(base)
        base.class_eval do
          # Virtual attribute
          attr_accessor :status_has_changed

          # Relations
          has_many :gitolite_public_keys, dependent: :destroy
          has_many :protected_branches_members, dependent: :destroy, foreign_key: :principal_id
          has_many :protected_branches, through: :protected_branches_members

          # Callbacks
          after_save :check_if_status_changed
          after_save :handle_gitolite_user_lock
          after_destroy :remove_from_gitolite_locked_users
        end
      end

      # Returns a unique identifier for this user to use for gitolite keys.
      def gitolite_identifier
        identifier = [RedmineGitHosting::Config.gitolite_identifier_prefix, stripped_login]
        identifier.concat(['_', id]) unless RedmineGitHosting::Config.gitolite_identifier_strip_user_id?
        identifier.join
      end

      def gitolite_projects
        projects.select { |p| p.gitolite_repos.any? }
      end

      # Syntaxic sugar
      def status_has_changed?
        status_has_changed
      end

      private

      def check_if_status_changed
        self.status_has_changed = saved_changes&.key?(:status)
      end

      def stripped_login
        login.underscore.gsub(/[^0-9a-zA-Z]/, '_')
      end

      # Handle user lock status changes
      def handle_gitolite_user_lock
        return unless status_has_changed?
        
        if status == ::User::STATUS_LOCKED
          add_to_gitolite_locked_users
        elsif saved_changes['status']&.first == ::User::STATUS_LOCKED
          remove_from_gitolite_locked_users
        end
      end

      def add_to_gitolite_locked_users
        RedmineGitHosting.logger.info("Adding user '#{login}' to @REDMINE_LOCKED_USERS")
        
        begin
          # Use GitoliteWrapper to handle the gitolite operations
          RedmineGitHosting::GitoliteWrapper.resync_gitolite(:add_to_locked_users, {
            user_id: gitolite_identifier,
            update_settings: true
          })
          
          # Update projects after locking user
          update_projects if respond_to?(:update_projects)
        rescue StandardError => e
          RedmineGitHosting.logger.error("Failed to add user to locked group: #{e.message}")
        end
      end

      def remove_from_gitolite_locked_users
        RedmineGitHosting.logger.info("Removing user '#{login}' from @REDMINE_LOCKED_USERS")
        
        begin
          # Use GitoliteWrapper to handle the gitolite operations
          RedmineGitHosting::GitoliteWrapper.resync_gitolite(:users/remove_from_locked_users, {
            user_id: gitolite_identifier,
            update_settings: true
          })
          
          # Update projects after unlocking user
          update_projects if respond_to?(:update_projects)
        rescue StandardError => e
          RedmineGitHosting.logger.error("Failed to remove user from locked group: #{e.message}")
        end
      end
    end
  end
end

User.prepend RedmineGitHosting::Patches::UserPatch unless User.included_modules.include?(RedmineGitHosting::Patches::UserPatch)
