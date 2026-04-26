module RedmineGitHosting
  module GitoliteWrappers
    class AddToLockedUsers < Base
      def call
        conf = gitolite_config
        user_id = target_object_id[:user_id]
        # Add or update the @all repository with deny rule
        all_repo = conf.repos['@all'] || Gitolite::Config::Repo.new('@all')
        conf.add_repo(all_repo) unless conf.repos['@all']
        # Ensure the deny permission exists
        unless all_repo.permissions['-']&.include?('@REDMINE_LOCKED_USERS')
          all_repo.permissions['-'] = ['@REDMINE_LOCKED_USERS']
        end
        # Add user to locked group
        group = conf.groups['@REDMINE_LOCKED_USERS']
        if group
          group.add_user(user_id.to_s) unless group.users.include?(user_id.to_s)
        else
          conf.add_group('@REDMINE_LOCKED_USERS', [user_id.to_s])
        end
        gitolite_admin_repo_commit("Add user #{user_id} to @REDMINE_LOCKED_USERS")
      end
    end
  end
end
