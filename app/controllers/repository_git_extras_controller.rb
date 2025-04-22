# frozen_string_literal: true

class RepositoryGitExtrasController < RedmineGitHostingController
  include RedmineGitHosting::GitoliteAccessor::Methods

  skip_before_action :set_current_tab

  helper :extend_repositories

  def update
    set_git_extra
    @git_extra.safe_attributes = params[:repository_git_extra]

    if @git_extra.save
      flash.now[:notice] = l :notice_gitolite_extra_updated
      gitolite_accessor.update_repository @repository, update_default_branch: @git_extra.default_branch_has_changed?
    else
      flash.now[:error] = l :notice_gitolite_extra_update_failed
    end
  end

  def sort_urls
    set_git_extra
    return unless request.post?

    if @git_extra.update urls_order: params[:repository_git_extra]
      flash.now[:notice] = l :notice_gitolite_extra_updated
    else
      flash.now[:error] = l :notice_gitolite_extra_update_failed
    end
  end

  def move
    @move_repository_form = MoveRepositoryForm.new @repository
    return unless request.post?

    @move_repository_form = MoveRepositoryForm.new @repository
    return unless @move_repository_form.submit params[:repository_mover]

    redirect_to settings_project_path(@repository.project, tab: 'repositories')
  end

  private

  def set_git_extra
    @git_extra = @repository.git_extra || @repository.create_git_extra(
      git_daemon: RedmineGitHosting::Config.gitolite_daemon_by_default?,
      git_notify: RedmineGitHosting::Config.gitolite_notify_by_default?,
      git_annex: false,
      default_branch: 'main',
      key: RedmineGitHosting::Utils::Crypto.generate_secret(64),
      urls_order: []
    )
  end
end
