# frozen_string_literal: true

namespace :redmine_git_hosting do
  desc 'Create missing repository_git_extras records for Git and Xitolite repositories'
  task migrate_missing_git_extras: :environment do
    require 'redmine_git_hosting'

    # Find all Git and Xitolite repositories without a corresponding repository_git_extras entry
    missing = Repository.where(type: ['Repository::Git', 'Repository::Xitolite'])
                        .where.not(id: RepositoryGitExtra.select(:repository_id))

    if missing.empty?
      puts 'No missing repository_git_extras records found.'
      next
    end

    puts "Found #{missing.count} repositories without git_extras."

    missing.each do |repo|
      puts "Processing repository #{repo.id} (#{repo.redmine_name})..."

      # Build default extra options following the same pattern as in migration_tools.rake
      default_extra_options = {
        git_http:   RedmineGitHosting::Config.gitolite_http_by_default?,
        git_daemon: RedmineGitHosting::Config.gitolite_daemon_by_default?,
        git_notify: RedmineGitHosting::Config.gitolite_notify_by_default?,
        git_annex:  false,
        default_branch: 'master',
        key: RedmineGitHosting::Utils::Crypto.generate_secret(64)
      }

      # For Git repositories (non‑Xitolite), we need to set git_ssh, git_https, git_go
      # based on current plugin defaults.
      extra = repo.build_extra(default_extra_options)

      # Set boolean flags for smart_http (these columns exist only in later versions)
      if extra.respond_to?(:git_ssh=)
        extra.git_ssh = true
      end
      if extra.respond_to?(:git_https=)
        extra.git_https = false   # derived from git_http
      end
      if extra.respond_to?(:git_go=)
        extra.git_go = false
      end
      if extra.respond_to?(:protected_branch=)
        extra.protected_branch = false
      end
      if extra.respond_to?(:public_repo=)
        extra.public_repo = false
      end

      if extra.save
        puts "  Created RepositoryGitExtra for repository #{repo.id}"
      else
        puts "  ERROR creating RepositoryGitExtra for repository #{repo.id}: #{extra.errors.full_messages.join(', ')}"
      end
    end

    # Regenerate SSH keys for all repositories (optional but recommended)
    puts 'Regenerating SSH keys for all repositories...'
    begin
      RedmineGitHosting::GitoliteAccessor.new.regenerate_ssh_keys
      puts 'SSH keys regenerated successfully.'
    rescue StandardError => e
      puts "WARNING: SSH key regeneration failed: #{e.message}"
      puts 'You may need to run `rake redmine_git_hosting:update_repositories` manually.'
    end

    puts 'Migration complete.'
    puts 'Next step: Run `rake redmine_git_hosting:update_repositories` to sync repositories with Gitolite.'
  end
end