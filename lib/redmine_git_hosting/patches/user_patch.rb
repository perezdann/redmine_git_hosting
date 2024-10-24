# frozen_string_literal: true

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
      # As login names may change (i.e., user renamed), we use the user id
      # with its login name as a prefix for readibility.
      def gitolite_identifier
        identifier = [RedmineGitHosting::Config.gitolite_identifier_prefix, stripped_login]
        identifier.concat ['_', id] unless RedmineGitHosting::Config.gitolite_identifier_strip_user_id?
        identifier.join
      end

      def gitolite_projects
        projects.select { |p| p.gitolite_repos.any? }
      end

      # Syntaxic sugar
      def status_has_changed?
        status_has_changed
      end

      def allowed_to_manage_repository?(repository)
        !roles_for_project(repository.project).select { |role| role.allowed_to? :manage_repository }.empty?
      end

      def allowed_to_commit?(repository)
        allowed_to? :commit_access, repository.project
      end

      def allowed_to_clone?(repository)
        allowed_to? :view_changesets, repository.project
      end

      def allowed_to_create_ssh_keys?
        allowed_to? :create_gitolite_ssh_key, nil, global: true
      end

      def allowed_to_download?(repository)
        git_allowed_to? :download_git_revision, repository
      end

      def git_allowed_to?(permission, repository)
        if repository.project.active?
          allowed_to? permission, repository.project
        else
          allowed_to? permission, nil, global: true
        end
      end

      private

      # This is Rails method : saved_changes
      # However, the value is cleared before passing the object to the controller.
      # We need to save it in virtual attribute to trigger Gitolite resync if changed.
      def check_if_status_changed
        self.status_has_changed = saved_changes&.key? :status
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
        
        admin = GitoliteAdmin.new
        conf = admin.config

        # Add or update the @all repository with deny rule
        all_repo = conf.repos['@all'] || conf.add_repo('@all')
        all_repo.add_permission('-', '@REDMINE_LOCKED_USERS')

        # Add user to locked group
        if conf.groups['@REDMINE_LOCKED_USERS']
          conf.groups['@REDMINE_LOCKED_USERS'].add_user(gitolite_identifier)
        else
          conf.add_group('@REDMINE_LOCKED_USERS', [gitolite_identifier])
        end

        admin.save
        GitoliteWrapper.update
      rescue => e
        RedmineGitHosting.logger.error("Failed to add user to locked group: #{e.message}")
      end

      def remove_from_gitolite_locked_users
        RedmineGitHosting.logger.info("Removing user '#{login}' from @REDMINE_LOCKED_USERS")
        
        admin = GitoliteAdmin.new
        conf = admin.config

        # Remove user from locked group
        if group = conf.groups['@REDMINE_LOCKED_USERS']
          group.remove_user(gitolite_identifier)
          
          # Remove empty group
          conf.groups.delete('@REDMINE_LOCKED_USERS') if group.users.empty?
          
          admin.save
          GitoliteWrapper.update
        end
      rescue => e
        RedmineGitHosting.logger.error("Failed to remove user from locked group: #{e.message}")
      end
    end

  end
end

User.prepend RedmineGitHosting::Patches::UserPatch unless User.included_modules.include? RedmineGitHosting::Patches::UserPatch
